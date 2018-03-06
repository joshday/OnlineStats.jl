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










# hoeffding_bound(R, δ, n) = sqrt(R ^ 2 * -log(δ) / 2n)


# #-----------------------------------------------------------------------# TreeNode 
# mutable struct TreeNode{T, S} <: ExactStat{(1, 0)}
#     nbc::NBClassifier{T, S}
#     id::Int 
#     split::Pair{Int, Float64}
#     lr::Vector{Int}             # left and right children
# end
# TreeNode(args...) = TreeNode(NBClassifier(args...), 1, Pair(1, -Inf), Int[])

# for f in [:nobs,:probs,:condprobs,:impurity,:predict,:classify,:nparams,:(Base.length)]
#     @eval $f(o::TreeNode, args...) = $f(o.nbc, args...)
# end

# Base.keys(o::TreeNode) = keys(o.nbc)
# Base.show(io::IO, o::TreeNode) = print(io, "TreeNode with ", o.nbc)
# fit!(o::TreeNode, xy, γ) = fit!(o.nbc, xy, γ)
# haschildren(o::TreeNode) = length(o.lr) > 0

# function go_to_node(tree::Vector{<:TreeNode}, x::VectorOb)
#     i = 1
#     while haschildren(tree[i])
#         o = tree[i]
#         if x[first(o.split)] < last(o.split)
#             i = o.lr[1]
#         else
#             i = o.lr[2]
#         end
#     end
#     return i
# end

# function shouldsplit(o::TreeNode)
#     nobs(o) > 10_000
# end

# # get best split for each variable: Vector of Pair(impurity, x)
# function top_IGs(leaf::TreeNode, impurity = entropybase2)
#     imp = impurity(probs(leaf))
#     out = Pair{Float64, Float64}[]
#     for j in 1:nparams(leaf)
#         tsplits = split_candidates(leaf.nbc, j)
#         imps = Float64[]
#         for x in tsplits
#             n1, n2 = split_nobs(leaf.nbc, j, x)
#             n1sum = sum(n1)
#             n2sum = sum(n2)
#             imp_l = impurity(n1 ./ sum(n1sum))
#             imp_r = impurity(n2 ./ sum(n2sum))
#             γ = n2sum / (n1sum + n2sum)
#             push!(imps, smooth(imp_l, imp_r, γ))
#         end
#         maximp, k = findmax(imps)
#         push!(out, Pair(maximp, tsplits[k]))
#     end
#     imp .- out
# end

# #-----------------------------------------------------------------------# CTree 
# # TODO: options like minsplit, etc.
# # TODO: Loss matrix
# struct CTree{T, S} <: ExactStat{(1, 0)}
#     tree::Vector{TreeNode{T, S}}
#     maxsize::Int
# end
# function CTree(p::Integer, T::Type; maxsize::Int = 25)
#     CTree([TreeNode(p * Hist(10), T)], maxsize)
# end
# function Base.show(io::IO, o::CTree)
#     print_with_color(:green, io, "CTree of size $(length(o.tree))\n")
#     for node in o.tree
#         print(io, "  > ", node)
#     end
# end

# nparams(o::CTree) = length(o.tree[1].nbc.empty_stats)

# get_leaf(o::CTree, x) = o.tree[go_to_node(o.tree, x)]

# function fit!(o::CTree, xy, γ) 
#     x, class = xy
#     # find leaf
#     leaf = get_leaf(o, x)
#     # update leaf sufficient statistics
#     fit!(leaf, xy, γ)
#     # If we should split the leaf
#     if length(o.tree) < o.maxsize && shouldsplit(leaf)
#         # get the top 2 information gains
#         IGs = zeros(nparams(o))
#         for j in eachindex(IGs)

#         end
#     end
# end


# predict(o::CTree, x::VectorOb) = predict(get_leaf(o, x), x)
# classify(o::CTree, x::VectorOb) = classify(get_leaf(o, x), x)

# for f in [:predict, :classify]
#     @eval begin 
#         function $f(o::CTree, x::AbstractMatrix, dim::Rows = Rows())
#             mapslices(x -> $f(o, x), x, 2)
#         end
#         function $f(o::CTree, x::AbstractMatrix, dim::Cols)
#             mapslices(x -> $f(o, x), x, 1)
#         end
#     end
# end
