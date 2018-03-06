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
mutable struct NodeStats{T, O <: OnlineStat} <: OnlineStat{(1, 0)}
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
    @inbounds for (i, lab) in enumerate(o.labels)
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

function find_best_split(o::NodeStats{T}) where {T}
    # splits = Split{T}[]
    # nobs_left = zeros(Int, length(o.nobs))
    # nobs_right = zeros(Int, length(o.nobs))

    # for j in 1:size(o.stats, 2)
    #     zeros!(nobs_left)
    #     zeros!(nobs_right)
    #     suff_stats_j = o[:, j]
    #     for loc in split_candidates(suff_stats_j)
    #         for (k, hk) in enumerate(suff_stats_j)
    #             nleft = sum(hk.alg, loc)
    #             nobs_left[k] += nleft
    #             nobs_right[k] += nobs(hk) - nleft
    #         end

    #     end
    # end
end

#-----------------------------------------------------------------------# Split
struct Split{T}
    j::Int          # variable to split on
    loc::Float64    # where to split
    class::Vector{T} # class[1] = label if xj < loc, class[2] = label if xj ≥ loc
    ig::Float64     # information gain
end
function classify(o::Split, x::VectorOb) 
    length(o.class) == 0 && error("Call `make_split!(o)` before classifying.")
    o.class[1 + !goleft(o,x)]
end
goleft(o::Split, x::VectorOb) = x[o.j] < o.loc

#-----------------------------------------------------------------------# Stump
mutable struct Stump{T, O <: OnlineStat} <: ExactStat{(1, 0)}
    ns::NodeStats{T, O} # Sufficient statistics
    split::Split{T}
end
function Stump(p::Int, T::Type, stat = Hist(50))
    Stump(NodeStats(p, T, stat), Split(0, 0.0, T[], 0.0))
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
    splits = Split{T}[]

    for j in 1:size(o.ns.stats, 2)
        suff_stats_j = o.ns[:, j]
        for loc in split_candidates(suff_stats_j)
            nobs_left = zeros(length(o.ns.nobs))
            nobs_right = zeros(length(o.ns.nobs))
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
            push!(splits, Split(j, loc, [lab_left, lab_right], imp_root - imp_after))
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
    λ::Float64
end
function StumpForest(p::Int, T::Type; nt = 100, b = 50, np = round(Int, sqrt(p)), λ = .1)
    forest = [Stump(np, T, Hist(b)) for _ in 1:nt] 
    subsets = zeros(Int, np, nt)
    for j in 1:nt 
        subsets[:, j] = sample(1:p, np; replace = false)
    end
    StumpForest(forest, subsets, p, λ)
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
    x, y = xy
    for (i, stump) in enumerate(o.forest)
        @inbounds if rand() < o.λ 
            @views xyi = (x[o.subsets[:, i]], y)
            fit!(stump, xyi, γ)
        end
    end
end

value(o::StumpForest) = make_split!.(o.forest)

# TODO: speed these up
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


#-----------------------------------------------------------------------# Node 
struct Node{T, O <: OnlineStat} <: ExactStat{(1, 0)}
    ns::NodeStats{T, O}
    id::Int 
    children::Vector{Int}
    split::Split{T}
end
Base.show(io::IO, o::Node) = print(io, "Node $(o.id) with children: $(o.children)")
shouldsplit(o::Node) = nobs(o.ns) > 10_000

#-----------------------------------------------------------------------# Tree
struct Tree{T, O} <: ExactStat{(1, 0)}
    tree::Vector{Node{T, O}}
    maxsize::Int
end
function Tree(p::Int, T::Type; b = 50, maxsize = 50) 
    Tree([Node(NodeStats(p, T, Hist(b)), 1, Int[], Split(0, 0.0, T[], 0.0))], maxsize)
end

function Base.show(io::IO, o::Tree)
    println(io, "Tree")
    println(io, "    > Labels: ", keys(o))
    print(io,   "    > Size:  ", length(o.tree))
end
Base.keys(o::Tree) = keys(first(o.tree).ns)

function fit!(o::Tree, xy, γ)
    x, y = xy
    node = o.tree[whichleaf(o, x)]  # Find the node to update
    fit!(node.ns, xy, γ)  # update sufficient statistics
    if length(o.tree) < o.maxsize && shouldsplit(node)
        best_split = find_best_split(node.ns)
    end
end

function whichleaf(o::Tree, x::VectorOb)
    i = 1
    while length(o.tree[i].children) > 0 
        node = o.tree[i]
        i = node.children[1 + !goleft(node.split, x)]
    end
    i
end