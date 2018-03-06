#-----------------------------------------------------------------------# Common
for f in [:predict, :classify]
    @eval begin 
        function $f(o::OnlineStat{(1,0)}, x::AbstractMatrix, dim::Rows = Rows())
            mapslices(x -> $f(o, x), x, 2)
        end
        function $f(o::OnlineStat{(1,0)}, x::AbstractMatrix, dim::Cols)
            mapslices(x -> $f(o, x), x, 1)
        end
    end
end


#-----------------------------------------------------------------------# NodeStats
mutable struct NodeStats{T, O} <: OnlineStat{(1, 0)}
    stats::Matrix{O}  # a row for each label
    labels::Vector{T}
    nobs::Vector{Int}
    empty_stat::O
end
NodeStats(p::Int, T::Type, o::OnlineStat{0} = Hist(50)) = NodeStats(fill(o, 0, p), T[], Int[], o)
default_weight(o::NodeStats) = default_weight(o.empty_stat)

function Base.show(io::IO, o::NodeStats)
    println(io, "NodeStats")
    println(io, "    > NVars : ", size(o.stats, 2), " ", name(o.empty_stat))
    print(io,   "    > Labels: ", o.labels)
end

function fit!(o::NodeStats, xy, γ)
    x, y = xy 
    addrow = true
    for (i, lab) in enumerate(o.labels)
        if y == lab 
            addrow = false 
            o.nobs[i] += 1
            for (j, xj) in enumerate(x)
                fit!(o.stats[i, j], xj, 1 / o.nobs[i])
            end
        end
    end
    if addrow 
        push!(o.labels, y)
        push!(o.nobs, 1)
        newrow = [copy(o.empty_stat) for i in 1:1, j in 1:size(o.stats, 2)]
        for (stat, xj) in zip(newrow, x)
            fit!(stat, xj, 1.0)
        end
        o.stats = vcat(o.stats, newrow)
    end
end

function Base.getindex(o::NodeStats{T}, label::T) where {T}
    i = findfirst(x -> x == label, o.labels)
    i == 0 && error("Label $label is not here")
    o.stats[i, :]
end
Base.getindex(o::NodeStats, ::Colon, j) = o.stats[:, j]
Base.keys(o::NodeStats) = o.labels

probs(o::NodeStats) = o.nobs ./ sum(o.nobs)
nobs(o::NodeStats) = sum(o.nobs)

#-----------------------------------------------------------------------# StumpSplit
struct StumpSplit{T}
    j::Int          # variable to split on
    loc::Float64    # where to split
    class::Vector{T} # class[1] = label if xj < loc, class[2] = label if xj ≥ loc
    ig::Float64     # information gain
end
function classify(o::StumpSplit, x::VectorOb) 
    length(o.class) == 0 && error("Call `make_split!(o)` before classifying.")
    o.class[1 + (x[o.j] ≥ o.loc)]
end

#-----------------------------------------------------------------------# Stump
mutable struct Stump{T, O} <: ExactStat{(1, 0)}
    ns::NodeStats{T, O} # Sufficient statistics
    split::StumpSplit{T}
end
function Stump(p::Int, T::Type, stat = Hist(50))
    Stump(NodeStats(p, T, stat), StumpSplit(0, 0.0, T[], 0.0))
end
function Base.show(io::IO, o::Stump)
    println(io, "Stump")
    print(io, "  > ", o.ns)
end
fit!(o::Stump, xy, γ) = fit!(o.ns, xy, γ)

Base.keys(o::Stump) = keys(o.ns)

nobs(o::Stump) = sum(o.ns)
classify(o::Stump, x::VectorOb) = classify(o.split, x)

function make_split!(o::Stump{T}) where {T}
    imp_root = impurity(probs(o.ns))

    nobs_left = zeros(length(o.ns.nobs))
    nobs_right = zeros(length(o.ns.nobs))

    splits = StumpSplit{T}[]

    for j in 1:size(o.ns.stats, 2)
        suff_stats_j = o.ns[:, j]
        for loc in split_candidates(suff_stats_j)
            # find out nobs for each label in the left and the right
            for (k, hk) in enumerate(suff_stats_j)
                nleft = sum(hk.alg, loc)
                nobs_left[k] += nleft
                nobs_right[k] += nobs(hk) - nleft
            end
            nlsum = sum(nobs_left)
            nrsum = sum(nobs_right)
            imp_left = impurity(nobs_left ./ sum(nlsum))
            imp_right = impurity(nobs_right ./ sum(nrsum))
            imp_after = smooth(imp_left, imp_right, nrsum / (nrsum + nlsum))
            # left label
            _, i = findmax(nobs_left)
            lab_left = keys(o)[i]
            # right label
            _, i = findmax(nobs_right)
            lab_right = keys(o)[i]
            push!(splits, StumpSplit(j, loc, [lab_left, lab_right], imp_root - imp_after))
        end
    end
    # set the best split 
    max_ig = maximum(s.ig for s in splits)
    i = findfirst(x -> x.ig == max_ig, splits)
    o.split = splits[i]
    o
end

# TODO: split_candidates for 
# - OrderStats
# - FitNormal
# - Hist{FixedBins}
function split_candidates(v::Vector{T}) where {T <: Hist}
    extrem = extrema.(v)
    a = maximum(first, extrem)
    b = minimum(last, extrem)
    h = reduce((x,y) -> merge(x.alg, y.alg), v)
    out = midpoints(first.(h.value))  # midpoints of merged histograms
end
function classify(o::Stump, x::AbstractMatrix, dim::Rows = Rows())
    mapslices(x -> classify(o, x), x, 2)
end
function classify(o::Stump, x::AbstractMatrix, dim::Cols)
    mapslices(x -> classify(o, x), x, 1)
end




#-----------------------------------------------------------------------# StumpForest 
struct StumpForest{T <: Stump} <: ExactStat{(1, 0)}
    forest::Vector{T}
    subsets::Matrix{Int}  # subsets[:, k] gets setn to stump forest[k]
    p::Int
end
function StumpForest(p::Int, T::Type; nt = 100, b = 50, np = round(Int, sqrt(p)))
    forest = [Stump(np, T, Hist(b)) for _ in 1:nt] 
    subsets = zeros(Int, np, nt)
    for j in 1:nt 
        subsets[:, j] = sample(1:p, np; replace = false)
    end
    StumpForest(forest, subsets, p)
end
function Base.show(io::IO, o::StumpForest)
    println(io, name(o))
    println(io, "    > N Trees : ", length(o.forest))
    println(io, "    > Subset  : ", size(o.subsets, 1), "/", o.p)
    print(io,   "    > Is Split: ", first(o.forest).split.j > 0)
end

Base.keys(o::StumpForest) = keys(first(o.forest))

nobs(o::StumpForest) = nobs(first(o.forest))

function fit!(o::StumpForest, xy, γ)
    cutoff = 2 / length(o.forest)
    x, y = xy
    for (i, stump) in enumerate(o.forest)
        if rand() < cutoff 
            xyi = (x[o.subsets[:, i]], y)
            fit!(stump, xyi, γ)
            fit!(stump, xyi, γ)
        end
    end
end

value(o::StumpForest) = make_split!.(o.forest)

function predict(o::StumpForest, x::VectorOb)
    out = Dict(Pair.(keys(o), 0))
    for (i, stump) in enumerate(o.forest)
        vote = classify(stump, x[o.subsets[:, i]])
        out[vote] += 1
    end
    out
end
function classify(o::StumpForest, x::VectorOb)
    p = predict(o, x)
    n = maximum(last, p)
    for entry in p 
        if last(entry) == n 
            return first(entry)
        end
    end
end
