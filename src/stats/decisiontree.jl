#-----------------------------------------------------------------------# FastNode
"""
    FastNode(p, nclasses; stat = FitNormal())

Node of a decision tree.  Assumes each predictor variable, conditioned on any 
class, has a normal distribution.  Internal structure for [`FastTree`](@ref).
Observations must be a `Pair`/`Tuple`/`NamedTuple` of (`VectorOb`, `Int`)
"""
mutable struct FastNode{T} <: ExactStat{(1, 0)}
    data::Matrix{T} # keystats in columns
    id::Int 
    children::Vector{Int}
    j::Int 
    at::Float64
    ig::Float64
end
function FastNode(p::Int, nlab::Int; id=1, children = Int[], stat = FitNormal()) 
    FastNode([copy(stat) for i in 1:p, j in 1:nlab], id, children, 0, -Inf, 0.0)
end
function FastNode(o::FastNode; id = nothing)
    FastNode(size(o.data)...; id = id, children = Int[], stat = make_stat(o))
end

# TODO - others: CountMap, Hist, OrderStats
make_stat(o::FastNode{FitNormal}) = FitNormal()

function Base.show(io::IO, o::FastNode)
    print(io, "FastNode(nobs=$(nobs(o)), split = x[$(o.j)] < $(round(o.at,3)))")
end

nvars(o::FastNode) = size(o.data, 1)
nkeys(o::FastNode) = size(o.data, 2)
nobs(o::FastNode) = sum(nobs, o.data[1, :])
probs(o::FastNode) = nobs.(o.data[1, :]) ./ nobs(o)
function fit!(o::FastNode, xy, γ)
    x, y = xy
    w = 1 / (nobs(o.data[1, y]) + 1)
    for j in eachindex(x)
        fit!(o.data[j, y], x[j], w)
    end
end

function classify(o::FastNode) 
    out = 1
    n = nobs(o.data[1])
    for k in 2:size(o.data, 2)
        n2 = nobs(o.data[1, k])
        if n2 > n 
            n = n2 
            out = k 
        end
    end
    out
end
child(o::FastNode, x::VectorOb) = x[o.j] < o.at ? first(o.children) : last(o.children)

function split!(t, o::FastNode)
    n = nobs(o)
    pl = zeros(nkeys(o))  # "prob" left
    pr = zeros(nkeys(o))  # "prob" right
    ent_root = impurity(probs(o))
    ig = -Inf
    ind = 0 
    at = -Inf
    for j in 1:nvars(o)
        stats_j = o.data[j, :]
        split_candidates = t.buffer
        k = 0 
        for stat in stats_j 
            μ = mean(stat)
            σ = std(stat)
            split_candidates[k+1] = μ - 2σ
            split_candidates[k+2] = μ - 1.5σ
            split_candidates[k+3] = μ - σ
            split_candidates[k+4] = μ - .5σ
            split_candidates[k+5] = μ 
            split_candidates[k+6] = μ + .5σ
            split_candidates[k+7] = μ + σ
            split_candidates[k+8] = μ + 1.5σ
            split_candidates[k+9] = μ + 2σ
            k += 9
        end
        for loc in split_candidates
            for k in 1:nkeys(o)
                pl[k] = _cdf(stats_j[k], loc)
                pr[k] = 1.0 - pl[k]
            end
            ent_l = impurity(pl ./ sum(pl))
            ent_r = impurity(pr ./ sum(pr))
            ent_after = smooth(ent_l, ent_r, sum(pr) / (sum(pr) + sum(pl)))
            new_ig = ent_root - ent_after 
            if new_ig > ig 
                ig = new_ig 
                ind = j 
                at = loc
            end
        end
    end
    o.j = ind 
    o.at = at
    o.ig = ig
    d = length(t.tree)
    push!(o.children, d + 1)
    push!(o.children, d + 2)
    push!(t.tree, FastNode(o; id = d + 1))
    push!(t.tree, FastNode(o; id = d + 2))
end
impurity(p) = entropy(p, 2)


#-----------------------------------------------------------------------# FastTree
"""
    FastTree(npredictors, nclasses; maxsize=5000, splitsize=2000)

Create an online decision tree under the assumption that the distribution of any predictor 
conditioned on any class is Normal.  The classes must be `Int`s beginning at one (1, 2, 3, ...).
When a node hits `splitsize` observations, it will be given two children.  When the number of 
nodes in the tree reaches `maxsize`, no more splits will occur.

# Example 

    x = randn(10^5, 10)
    y = (x[:, 1] .> 0) .+ 1

    s = series((x,y), FastTree(10, 2))

    yhat = classify(s.stats[1], x)
    mean(y .== yhat)
"""
struct FastTree{T} <: ExactStat{(1, 0)}
    tree::Vector{FastNode{T}}
    maxsize::Int
    splitsize::Int
    buffer::Vector{Float64}
end
function FastTree(p, nlab; stat=FitNormal(), maxsize=5000, splitsize=2000) 
    FastTree([FastNode(p, nlab; stat=stat)], maxsize, splitsize, zeros(nlab * 9))
end
function Base.show(io::IO, o::FastTree) 
    print(io, "FastTree: (keys, stats)=", size(o.tree[1].data), " | size=",length(o.tree))
end

function fit!(o::FastTree, xy, γ)
    x, y = xy 
    node = whichleaf(o, x)
    fit!(node, xy, γ)
    if length(o.tree) < o.maxsize && nobs(node) > o.splitsize 
        split!(o, node)
    end
end

nkeys(o::FastTree) = nkeys(first(o.tree))
nvars(o::FastTree) = nvars(first(o.tree))

function whichleaf(o, x::VectorOb)
    i = 1
    node = o.tree[1]
    while length(node.children) > 0
        node = o.tree[child(node, x)]
    end
    node
end

classify(o::FastTree, x::VectorOb) = classify(whichleaf(o,x))
classify(o::FastTree, x::AbstractMatrix, ::Rows = Rows()) = mapslices(xi->classify(o,xi), x, 2)
classify(o::FastTree, x::AbstractMatrix, ::Cols) = mapslices(xi->classify(o,xi), x, 1)




#-----------------------------------------------------------------------# FastForest 
"""
    FastForest(p, nclasses; nt, b, λ, kw...)

Build a random forest of [`FastTree`](@ref) trees with `p` predictors.  Each tree 
in the forest recieves a random subset of predictors of size `b`.  For a new observation,
each tree in the forest is updated with probability `λ`.  The keyword arguments are:

- `nt=40`: Number of trees in the forest 
- `b=floor(Int,sqrt(p))`: Number of random predictors to use for each tree
- `λ = .05`: Probability of a tree being updated for any given observation
- `maxsize=1000`:  Maximum number of nodes in any tree in the forest
- `splitsize=2000`: How many observations a node can observe before it splits

# Example 

    x = randn(10^5, 10)
    y = (x[:, 1] .> 0) .+ 1

    s = series((x,y), FastForest(10, 2))

    yhat = classify(s.stats[1], x)
    mean(y .== yhat)
"""
struct FastForest{T} <: ExactStat{(1, 0)}
    forest::Vector{Pair{Vector{Int}, FastTree{T}}}  # subset => tree
    p::Int
    λ::Float64
end
function FastForest(p::Int, nclass::Int; nt=40, b=floor(Int, sqrt(p)), λ=.05, kw...)
    forest = [Pair(sort!(sample(1:p, b, replace=false)), FastTree(b, nclass; kw...)) for i in 1:nt]
    FastForest(forest, p, λ)
end
function Base.show(io::IO, o::FastForest)
    print(io, "FastForest(")
    print(io, "nt = $(length(o.forest)), subset = $(length(first(o.forest[1])))/$(o.p))")
end
nkeys(o::FastForest) = nkeys(o.forest[1][2])
function fit!(o::FastForest, xy, γ)
    x, y = xy
    for i in eachindex(o.forest)
        if rand() < o.λ 
            subset, tree = o.forest[i]
            fit!(tree, (x[subset], y), γ)
        end
    end
end

function _predict(o::FastForest, x::VectorOb, buffer::Vector{Int})
    for item in o.forest 
        subset, tree = item 
        xi = @view(x[subset])
        buffer[classify(tree, xi)] += 1
    end
    buffer
end
_classify(o::FastForest, x::VectorOb, buffer::Vector{Int}) = findmax(_predict(o, x, buffer))[2]

predict(o::FastForest, x::VectorOb) = _predict(o, x, zeros(Int, nkeys(o)))
classify(o::FastForest, x::VectorOb) = _classify(o, x, zeros(Int, nkeys(o)))

function zeros!(v::Vector{Int}) 
    for i in eachindex(v)
        @inbounds v[i] = 0 
    end
    v
end 

function classify(o::FastForest, x::AbstractMatrix, dim::Rows = Rows())
    buffer = zeros(Int, nkeys(o))
    mapslices(x -> _classify(o, x, zeros!(buffer)), x, 2)
end
function predict(o::FastForest, x::AbstractMatrix, dim::Rows = Rows())
    buffer = zeros(Int, nkeys(o))
    mapslices(x -> _predict(o, x, zeros!(buffer)), x, 2)
end
function classify(o::FastForest, x::AbstractMatrix, dim::Cols)
    buffer = zeros(Int, nkeys(o))
    mapslices(x -> _classify(o, x, zeros!(buffer)), x, 1)
end
function predict(o::FastForest, x::AbstractMatrix, dim::Cols)
    buffer = zeros(Int, nkeys(o))
    mapslices(x -> _predict(o, x, zeros!(buffer)), x,12)
end



# abstract type EnsembleMethod end

# struct Bagging <: EnsembleMethod end

# struct Forest <: EnsembleMethod
#     subsets::Matrix{Int}
# end
# function Forest(p::Int, nt::Int, b::Int=floor(Int, sqrt(p)))
#     subsets = zeros(Int, b, nt)
#     for j in 1:nt 
#         subsets[:, j] = sample(1:p, b, replace=false)
#     end
#     Forest(subsets)
# end


# # #-----------------------------------------------------------------------# Ensemble
# # struct Ensemble{T<:Tuple, M<:EnsembleMethod} <: ExactStat{(1, 0)}
# #     models::T
# #     method::M
# # end
# # Ensemble(models, method::Type) = Ensemble(models, method(models))


# struct FastTreeEnsemble{T, M <: EnsembleMethod} <: ExactStat{(1, 0)}
#     trees::Vector{FastTree{T}}
#     method::M
# end
# function FastTreeEnsemble 

# end










# #-----------------------------------------------------------------------# NBNode
# mutable struct NBNode{T, G}
#     nbc::NaiveBayesClassifier{T, G}
#     id::Int 
#     parent::Int 
#     children::Vector{Int}
#     split::NBSplit
# end
# function NBNode(o::NaiveBayesClassifier, id::Int, parent::Int) 
#     NBNode(o, id, parent, Int[], NBSplit(0, 0.0, -Inf, Int[]))
# end
# function Base.show(io::IO, o::NBNode)
#     println(io, name(o))
#     print(io, "    > id=", o.id, ", parent=", o.parent)
#     length(o.children) > 0 && print(io, ", children=", o.children)
#     o.split.j > 0 && print(io, ", split=", o.split)
# end

# #-----------------------------------------------------------------------# NBTree 
# """
#     NBTree(root::NaiveBayesClassifier; maxsize=1000, minsplit=5000, cp=.01)

# Create a decision tree where each node is a naive bayes classifier.  

# - `maxsize` controls the size of the tree 
# - `minsplit` is the minimum number of observations in a node before attempting a split 
# - `cp` is a complexity parameter.  A split only occurs if the information gain is greater than `cp`.
# """
# struct NBTree{T <: NBNode} <: OnlineStat{(1, 0)}
#     tree::Vector{T}
#     maxsize::Int
#     minsplit::Int
#     cp::Float64     # complexity parameter
# end
# function NBTree(root::NaiveBayesClassifier; maxsize = 1000, minsplit = 5000, cp = 0.01) 
#     NBTree([NBNode(root, 1, 0)], maxsize, minsplit, cp)
# end
# default_weight(o::NBTree) = default_weight(o.tree[1].nbc)
# Base.show(io::IO, o::NBTree) = print(io, name(o), " (size = ", length(o.tree), ")")
# nobs(o::NBTree) = nobs(first(o.tree).nbc)

# function fit!(o::NBTree, xy, γ)
#     x, y = xy 
#     i, node = whichleaf(o, x)
#     fit!(node.nbc, xy, γ)
#     if length(o.tree) < o.maxsize && nobs(node.nbc) >= o.minsplit 
#         nbc, spl, left_nbc, right_nbc = split(node.nbc)
#         if spl.ig > o.cp
#             node.split = spl
#             node.children = [length(o.tree) + 1, length(o.tree) + 2]
#             left =  NBNode(left_nbc,  length(o.tree) + 1, i, Int[], NBSplit(spl))
#             right = NBNode(right_nbc, length(o.tree) + 2, i, Int[], NBSplit(spl))
#             push!(o.tree, left)
#             push!(o.tree, right)
#         end
#     end
# end

# function whichleaf(o::NBTree, x::VectorOb)
#     i = 1 
#     node = o.tree[i]
#     while length(node.children) > 0
#         i = node.children[whichchild(node.split, x)]
#         node = o.tree[i]
#     end
#     i, node
# end

# predict(o::NBTree, x::VectorOb) = probs(whichleaf(o, x)[2].nbc)
# classify(o::NBTree, x::VectorOb) = findmax(predict(o, x))[2]




# for f in [:predict, :classify]
#     @eval begin
#         # $f(o::NBTree, x::VectorOb) = $f(whichleaf(o, x)[2].nbc, x)
#         $f(o::NBTree, x::AbstractMatrix, ::Rows = Rows()) = mapslices(xi -> $f(o, xi), x, 2)
#         $f(o::NBTree, x::AbstractMatrix, ::Cols) = mapslices(xi -> $f(o, xi), x, 1)
#     end
# end


# #-----------------------------------------------------------------------# NBForest 
# struct NBForest{T <: NBTree} <: OnlineStat{(1, 0)}
#     forest::Vector{T}
#     subsets::Vector{Vector{Int}}
#     p::Int
#     λ::Float64
# end
# # function NBForest(root; nt = 100, np = round(Int, sqrt(nvars(root))), kw...)
# #     forest = [NBTree()]
# # end



# #################################################################################### 
# ####################################################################################
# ####################################################################################
# ####################################################################################
# ####################################################################################
# #################################################################################### 
# ############## Everything below here will be deprecated


# #-----------------------------------------------------------------------# Common
# abstract type TreePart <: ExactStat{(1, 0)} end

# for f in [:predict, :classify]
#     @eval begin 
#         function $f(o::TreePart, x::AbstractMatrix, dim::Rows = Rows())
#             mapslices(x -> $f(o, x), x, 2)
#         end
#         function $f(o::TreePart, x::AbstractMatrix, dim::Cols)
#             mapslices(x -> $f(o, x), x, 1)
#         end
#     end
# end

# split_candidates(v::Vector{<:OnlineStat}) = split_candidates(merge(v))

# #-----------------------------------------------------------------------# NodeStats
# # Sufficient statistics for each predictor, conditioned on label
# # In the future we can use other stats, for now we'll use Hist(b)
# mutable struct NodeStats{T, O <: OnlineStat} <: TreePart
#     stats::Matrix{O}  # a row for each label
#     labels::Vector{T}
#     nobs::Vector{Int}
#     empty_stat::O
# end
# NodeStats(p::Int, T::Type, o::OnlineStat{0} = Hist(50)) = NodeStats(fill(o, 0, p), T[], Int[], o)
# default_weight(o::NodeStats) = default_weight(o.empty_stat)

# function Base.show(io::IO, o::NodeStats)
#     println(io, "NodeStats")
#     println(io, "    > NVars : ", size(o.stats, 2), " ", name(o.empty_stat))
#     print(io,   "    > Labels: ", o.labels)
# end

# function fit!(o::NodeStats, xy, γ)
#     x, y = xy 
#     addrow = true
#     @inbounds for (i, lab) in enumerate(o.labels)
#         # if we've already seen the label, update the sufficient statistics
#         if y == lab 
#             addrow = false 
#             o.nobs[i] += 1
#             for (j, xj) in enumerate(x)
#                 fit!(o.stats[i, j], xj, 1 / o.nobs[i])
#             end
#         end
#     end
#     if addrow 
#         # if we haven't seen the label, add a row for it
#         push!(o.labels, y)
#         push!(o.nobs, 1)
#         newrow = [copy(o.empty_stat) for i in 1:1, j in 1:size(o.stats, 2)]
#         for (stat, xj) in zip(newrow, x)
#             fit!(stat, xj, 1.0)
#         end
#         o.stats = vcat(o.stats, newrow)
#     end
# end

# # ns[lab] --> conditional stats for label
# # ns[:, j] --> sufficient stats of predictor j, conditioned on labels
# function Base.getindex(o::NodeStats{T}, label::T) where {T}
#     i = findfirst(x -> x == label, o.labels)
#     i == 0 && error("Label $label is not here")
#     o.stats[i, :]
# end
# Base.getindex(o::NodeStats, ::Colon, j) = o.stats[:, j]
# Base.keys(o::NodeStats) = o.labels

# probs(o::NodeStats) = o.nobs ./ sum(o.nobs)
# nobs(o::NodeStats) = sum(o.nobs)
# nparams(o::NodeStats) = size(o.stats, 2)

# function find_best_split(o::NodeStats{T}) where {T}
#     splits = Split{T}[]
#     imp_root = impurity(probs(o))
#     for j in 1:size(o.stats, 2)
#         nobs_left = zeros(length(o.nobs))
#         nobs_right = zeros(length(o.nobs))
#         suff_stats_j = o[:, j]
#         for loc in split_candidates(suff_stats_j)
#             for (k, hk) in enumerate(suff_stats_j)
#                 nleft = sum(hk, loc)
#                 nobs_left[k] += nleft
#                 nobs_right[k] += nobs(hk) - nleft
#             end
#             nlsum = sum(nobs_left)
#             nrsum = sum(nobs_right)
#             imp_left = impurity(nobs_left ./ sum(nlsum))
#             imp_right = impurity(nobs_right ./ sum(nrsum))
#             imp_after = smooth(imp_left, imp_right, nrsum / (nrsum + nlsum))
#             # left label
#             _, i = findmax(nobs_left)
#             lab_left = keys(o)[i]
#             # right label
#             _, i = findmax(nobs_right)
#             lab_right = keys(o)[i]
#             push!(splits, Split(j, loc, [lab_left, lab_right], imp_root - imp_after))
#         end
#     end
#     # get the best split 
#     max_ig = maximum(s.ig for s in splits)
#     i = findfirst(x -> x.ig == max_ig, splits)
#     return splits[i]
# end

# function classify(o::NodeStats)
#     _, i = findmax(o.nobs)
#     o.labels[i]
# end

# #-----------------------------------------------------------------------# Split
# struct Split{T}
#     j::Int          # variable to split on
#     loc::Float64    # where to split
#     class::Vector{T} # class[1] = label if xj < loc, class[2] = label if xj ≥ loc
#     ig::Float64     # information gain
# end
# function classify(o::Split, x::VectorOb) 
#     length(o.class) == 0 && error("Call `make_split!(o)` before classifying.")
#     o.class[1 + !goleft(o,x)]
# end
# goleft(o::Split, x::VectorOb) = x[o.j] < o.loc

# #-----------------------------------------------------------------------# Stump
# mutable struct Stump{T, O <: OnlineStat} <: TreePart
#     ns::NodeStats{T, O} # Sufficient statistics
#     split::Split{T}
# end
# function Stump(p::Int, T::Type, stat = Hist(50))
#     Stump(NodeStats(p, T, stat), Split(0, 0.0, T[], 0.0))
# end
# function Base.show(io::IO, o::Stump)
#     println(io, "Stump")
#     print(io, "  > ", o.ns)
# end
# fit!(o::Stump, xy, γ) = fit!(o.ns, xy, γ)

# Base.keys(o::Stump) = keys(o.ns)

# nobs(o::Stump) = sum(o.ns)
# classify(o::Stump, x::VectorOb) = classify(o.split, x)

# function make_split!(o::Stump{T}) where {T}
#     imp_root = impurity(probs(o.ns))
#     splits = Split{T}[]

#     for j in 1:nparams(o.ns)
#         suff_stats_j = o.ns[:, j]
#         for loc in split_candidates(suff_stats_j)
#             nobs_left = zeros(length(o.ns.nobs))
#             nobs_right = zeros(length(o.ns.nobs))
#             # find out nobs for each label in the left and the right
#             for (k, hk) in enumerate(suff_stats_j)
#                 nleft = sum(hk.alg, loc)
#                 nobs_left[k] += nleft
#                 nobs_right[k] += nobs(hk) - nleft
#             end
#             nlsum = sum(nobs_left)
#             nrsum = sum(nobs_right)
#             imp_left = impurity(nobs_left ./ sum(nlsum))
#             imp_right = impurity(nobs_right ./ sum(nrsum))
#             imp_after = smooth(imp_left, imp_right, nrsum / (nrsum + nlsum))
#             # left label
#             _, i = findmax(nobs_left)
#             lab_left = keys(o)[i]
#             # right label
#             _, i = findmax(nobs_right)
#             lab_right = keys(o)[i]
#             push!(splits, Split(j, loc, [lab_left, lab_right], imp_root - imp_after))
#         end
#     end
#     # set the best split 
#     max_ig = maximum(s.ig for s in splits)
#     i = findfirst(x -> x.ig == max_ig, splits)
#     o.split = splits[i]
#     o
# end

# #-----------------------------------------------------------------------# split_candidates




# function classify(o::Stump, x::AbstractMatrix, dim::Rows = Rows())
#     mapslices(x -> classify(o, x), x, 2)
# end
# function classify(o::Stump, x::AbstractMatrix, dim::Cols)
#     mapslices(x -> classify(o, x), x, 1)
# end

# #-----------------------------------------------------------------------# StumpForest 
# struct StumpForest{T <: Stump} <: TreePart
#     forest::Vector{T}
#     subsets::Matrix{Int}  # subsets[:, k] gets setn to stump forest[k]
#     p::Int
#     λ::Float64
# end
# function StumpForest(p::Int, T::Type; nt = 100, b = 50, np = round(Int, sqrt(p)), λ = .1)
#     forest = [Stump(np, T, Hist(b)) for _ in 1:nt] 
#     subsets = zeros(Int, np, nt)
#     for j in 1:nt 
#         subsets[:, j] = sample(1:p, np; replace = false)
#     end
#     StumpForest(forest, subsets, p, λ)
# end
# function Base.show(io::IO, o::StumpForest)
#     println(io, name(o))
#     println(io, "    > N Trees : ", length(o.forest))
#     println(io, "    > Subset  : ", size(o.subsets, 1), "/", o.p)
#     print(io,   "    > Is Split: ", first(o.forest).split.j > 0)
# end

# Base.keys(o::StumpForest) = keys(first(o.forest))

# nobs(o::StumpForest) = nobs(first(o.forest))

# function fit!(o::StumpForest, xy, γ)
#     x, y = xy
#     for (i, stump) in enumerate(o.forest)
#         @inbounds if rand() < o.λ 
#             @views xyi = (x[o.subsets[:, i]], y)
#             fit!(stump, xyi, γ)
#         end
#     end
# end

# value(o::StumpForest) = make_split!.(o.forest)

# # TODO: speed these up
# function predict(o::StumpForest, x::VectorOb)
#     out = Dict(Pair.(keys(o), 0))
#     for (i, stump) in enumerate(o.forest)
#         vote = classify(stump, x[o.subsets[:, i]])
#         out[vote] += 1
#     end
#     out
# end
# function classify(o::StumpForest, x::VectorOb)
#     p = predict(o, x)
#     n = maximum(last, p)
#     for entry in p 
#         if last(entry) == n 
#             return first(entry)
#         end
#     end
# end


# #-----------------------------------------------------------------------# Node 
# mutable struct Node{T, O <: OnlineStat} <: TreePart
#     ns::NodeStats{T, O}
#     id::Int 
#     children::Vector{Int}
#     split::Split{T}
# end
# Base.show(io::IO, o::Node) = print(io, "Node $(o.id) with children: $(o.children)")

# #-----------------------------------------------------------------------# DTree
# """
#     DTree(p::Int, T::Type, stat = Hist(50); kw...)

# Calculate a decision tree with `p` predictor variables where classes have type `T`.  The
# "sufficient statistics" of the data are estimated by `stat`.
# """
# struct DTree{T, O} <: TreePart
#     tree::Vector{Node{T, O}}
#     maxsize::Int
#     splitsize::Int
#     empty_stat::O
# end
# function DTree(p::Int, T::Type, o = Hist(50); maxsize = 50, splitsize = 1000) 
#     tree = [Node(NodeStats(p, T, o), 1, Int[], Split(0, 0.0, T[], 0.0))]
#     DTree(tree, maxsize, splitsize, o)
# end

# function Base.show(io::IO, o::DTree)
#     println(io, name(o))
#     println(io, "    > Labels: ", keys(o))
#     print(io,   "    > Size:  ", length(o.tree))
# end
# Base.keys(o::DTree) = keys(first(o.tree).ns)

# function fit!(o::DTree{T}, xy, γ) where {T}
#     x, y = xy
#     node = o.tree[whichleaf(o, x)]  # Find the node to update
#     fit!(node.ns, xy, γ)  # update sufficient statistics
#     if length(o.tree) < o.maxsize && nobs(node.ns) > o.splitsize
#         node.split = find_best_split(node.ns)
#         m = length(o.tree)
#         node.children = [m + 1, m + 2]
#         p = size(node.ns.stats, 2)
#         l = Node(NodeStats(p, T, copy(o.empty_stat)), m + 1, Int[], Split(0, 0.0, T[], 0.0))
#         r = Node(NodeStats(p, T, copy(o.empty_stat)), m + 2, Int[], Split(0, 0.0, T[], 0.0))
#         push!(o.tree, l)
#         push!(o.tree, r)
#     end
# end

# function whichleaf(o::DTree, x::VectorOb)
#     i = 1
#     while length(o.tree[i].children) > 0 
#         node = o.tree[i]
#         i = node.children[1 + !goleft(node.split, x)]
#     end
#     i
# end

# function classify(o::DTree, x::VectorOb) 
#     i = whichleaf(o, x)
#     node = o.tree[i]
#     if !isempty(node.ns.nobs)
#         return classify(node.ns)
#     else
#         k = findfirst(x -> any(x.children .== i), o.tree)
#         return classify(o.tree[k].ns)
#     end
# end

# #-----------------------------------------------------------------------# Forest 
# struct Forest{T <: DTree} <: TreePart
#     forest::Vector{T}
#     subsets::Matrix{Int}  # subsets[:, k] gets setn to stump forest[k]
#     p::Int
#     λ::Float64
# end
# function Forest(p::Int, T::Type, stat = Hist(10); nt = 100, np = round(Int, sqrt(p)), 
#                 λ = .1, maxsize = 20, splitsize = 5000)
#     forest = [DTree(np, T, stat; maxsize=maxsize, splitsize=splitsize) for i in 1:nt]
#     subsets = Matrix{Int}(np, nt)
#     for i in 1:size(subsets, 2)
#         subsets[:, i] = sample(1:p, np; replace = false)
#     end
#     Forest(forest, subsets, p, λ)
# end

# Base.keys(o::Forest) = keys(first(o.forest))

# function Base.show(io::IO, o::Forest)
#     print(io, name(o))
#     print(io, "\n    > NTrees      : ", length(o.forest))
#     print(io, "\n    > N Predictors: ", size(o.subsets, 1), "/", o.p)
#     print(io, "\n    > λ           : ", o.λ)
#     print(io, "\n    > Max Size    : ", o.forest[1].maxsize)
#     print(io, "\n    > Split Size  : ", o.forest[1].splitsize)
# end
# function fit!(o::Forest, xy, γ)
#     x, y = xy
#     for (i, tree) in enumerate(o.forest)
#         rand() < o.λ && fit!(tree, (x[o.subsets[:, i]], y), γ)
#     end
# end

# function predict(o::Forest, x::VectorOb)
#     out = Dict(Pair.(keys(o), 0))
#     for (i, stump) in enumerate(o.forest)
#         vote = classify(stump, x[o.subsets[:, i]])
#         out[vote] += 1
#     end
#     out
# end
# function classify(o::Forest, x::VectorOb)
#     p = predict(o, x)
#     n = maximum(last, p)
#     for entry in p 
#         if last(entry) == n 
#             return first(entry)
#         end
#     end
# end