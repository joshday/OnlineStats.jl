#-----------------------------------------------------------------------# FastNode
struct FastNode{T} <: OnlineStat{(1, 0)}
    stats::Matrix{T}
    id::Int 
    children::Vector{Int}
    j::Int 
    at::Float64
    ig::Float64
end
function FastNode(p=0, nkeys=2; stat=FitNormal())
    FastNode([FitNormal() for i in 1:p, j in 1:nkeys], 1, Int[], 0, -Inf, -Inf)
end
function FastNode(o::FastNode, id::Int)
    FastNode([FitNormal() for i in 1:nvars(o), j in 1:nkeys(o)], id, Int[], 0, -Inf, -Inf)
end
nobs(o::FastNode) = sum(nobs, o.stats[1, :])
probs(o::FastNode) = nobs.(o.stats[1, :]) ./ nobs(o)
nkeys(o::FastNode) = size(o.stats, 2)
nvars(o::FastNode) = size(o.stats, 1)
function fakedata(::Type{FastNode}, n, p) 
    x = randn(n, p)
    y = [(rand() > 1 /(1 + exp(xb))) + 1 for xb in x * (1:p)]
    x, y
end
function _fit!(o::FastNode, xy)
    x, y = xy 
    j = Int(y)
    if isempty(o.stats)
        o.stats = [FitNormal() for i in 1:size(x,2), j in 1:size(o.stats,2)]
    end
    for i in 1:nvars(o)
        _fit!(o.stats[i, j], x[i])
    end
end
function classify(o::FastNode)
    out = 1
    n = nobs(o.stats[1])
    for j in 2:nkeys(o)
        n2 = nobs(o.stats[1, j])
        if n2 > n 
            out = j 
            n = n2
        end
    end
    out
end
child(o::FastNode, x::VectorOb) = x[o.j] < o.at ? first(o.children) : last(o.children)

# node, tree_length --> left, right
function split(o::FastNode, d::Int, split_candidates::Vector{Float64})
    n = nobs(o)
    pl = zeros(nkeys(o))  # "prob" left
    pr = zeros(nkeys(o))  # "prob" right
    ent_root = impurity(probs(o))
    ig = -Inf
    ind = 0 
    at = -Inf
    for j in 1:nvars(o)
        stats_j = o.stats[j, :]
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
                pl[k] = cdf(stats_j[k], loc)
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
    push!(o.children, d + 1)
    push!(o.children, d + 2)
    FastNode(o; id = d + 1), FastNode(o; id = d + 2)
end
impurity(p) = entropy(p, 2)

# #-----------------------------------------------------------------------# FastNode
# """
#     FastNode(p, nclasses; stat = FitNormal())

# Node of a decision tree.  Assumes each predictor variable, conditioned on any 
# class, has a normal distribution.  Internal structure for [`FastTree`](@ref).
# Observations must be a `Pair`/`Tuple`/`NamedTuple` of (`VectorOb`, `Int`)
# """
# mutable struct FastNode{T} <: ExactStat{(1, 0)}
#     data::Matrix{T}         # keystats in columns
#     id::Int                 # index of node (tree stored in vector)
#     children::Vector{Int}   # indices of children (tree stored in vector)
#     j::Int                  # variable to split on
#     at::Float64             # location to split
#     ig::Float64             # information gain
# end
# function FastNode(p::Int, nlab::Int; id=1, children = Int[], stat = FitNormal()) 
#     FastNode([copy(stat) for i in 1:p, j in 1:nlab], id, children, 0, -Inf, 0.0)
# end
# function FastNode(o::FastNode; id = nothing)
#     FastNode(size(o.data)...; id = id, children = Int[], stat = make_stat(o))
# end

# # TODO - others: CountMap, Hist, OrderStats
# make_stat(o::FastNode{FitNormal}) = FitNormal()

# function Base.show(io::IO, o::FastNode)
#     print(io, "FastNode(nobs=$(nobs(o)), split = x[$(o.j)] < $(round(o.at,3)))")
# end

# nvars(o::FastNode) = size(o.data, 1)
# nkeys(o::FastNode) = size(o.data, 2)
# nobs(o::FastNode) = sum(nobs, o.data[1, :])
# probs(o::FastNode) = nobs.(o.data[1, :]) ./ nobs(o)
# function fit!(o::FastNode, xy, γ)
#     x, y = xy
#     w = 1 / (nobs(o.data[1, y]) + 1)
#     for j in eachindex(x)
#         fit!(o.data[j, y], x[j], w)
#     end
# end

# function classify(o::FastNode) 
#     out = 1
#     n = nobs(o.data[1])
#     for k in 2:size(o.data, 2)
#         n2 = nobs(o.data[1, k])
#         if n2 > n 
#             n = n2 
#             out = k 
#         end
#     end
#     out
# end
# child(o::FastNode, x::VectorOb) = x[o.j] < o.at ? first(o.children) : last(o.children)

# function split!(t, o::FastNode)
#     n = nobs(o)
#     pl = zeros(nkeys(o))  # "prob" left
#     pr = zeros(nkeys(o))  # "prob" right
#     ent_root = impurity(probs(o))
#     ig = -Inf
#     ind = 0 
#     at = -Inf
#     for j in 1:nvars(o)
#         stats_j = o.data[j, :]
#         split_candidates = t.buffer
#         k = 0 
#         for stat in stats_j 
#             μ = mean(stat)
#             σ = std(stat)
#             split_candidates[k+1] = μ - 2σ
#             split_candidates[k+2] = μ - 1.5σ
#             split_candidates[k+3] = μ - σ
#             split_candidates[k+4] = μ - .5σ
#             split_candidates[k+5] = μ 
#             split_candidates[k+6] = μ + .5σ
#             split_candidates[k+7] = μ + σ
#             split_candidates[k+8] = μ + 1.5σ
#             split_candidates[k+9] = μ + 2σ
#             k += 9
#         end
#         for loc in split_candidates
#             for k in 1:nkeys(o)
#                 pl[k] = cdf(stats_j[k], loc)
#                 pr[k] = 1.0 - pl[k]
#             end
#             ent_l = impurity(pl ./ sum(pl))
#             ent_r = impurity(pr ./ sum(pr))
#             ent_after = smooth(ent_l, ent_r, sum(pr) / (sum(pr) + sum(pl)))
#             new_ig = ent_root - ent_after 
#             if new_ig > ig 
#                 ig = new_ig 
#                 ind = j 
#                 at = loc
#             end
#         end
#     end
#     o.j = ind 
#     o.at = at
#     o.ig = ig
#     d = length(t.tree)
#     push!(o.children, d + 1)
#     push!(o.children, d + 2)
#     push!(t.tree, FastNode(o; id = d + 1))
#     push!(t.tree, FastNode(o; id = d + 2))
# end
# impurity(p) = entropy(p, 2)


# #-----------------------------------------------------------------------# FastTree
# """
#     FastTree(npredictors, nclasses; maxsize=5000, splitsize=2000)

# Create an online decision tree under the assumption that the distribution of any predictor 
# conditioned on any class is Normal.  The classes must be `Int`s beginning at one (1, 2, 3, ...).
# When a node splits every time it reaches `splitsize` observations.  When the number of 
# nodes in the tree reaches `maxsize`, no more splits will occur.

# # Example 

#     x = randn(10^5, 10)
#     y = (x[:, 1] .> 0) .+ 1

#     s = series((x,y), FastTree(10, 2))

#     yhat = classify(s.stats[1], x)
#     mean(y .== yhat)
# """
# struct FastTree{T} <: ExactStat{(1, 0)}
#     tree::Vector{FastNode{T}}
#     maxsize::Int
#     splitsize::Int
#     buffer::Vector{Float64}  # for storing split candidates
# end
# function FastTree(p, nlab; stat=FitNormal(), maxsize=5000, splitsize=2000) 
#     FastTree([FastNode(p, nlab; stat=stat)], maxsize, splitsize, zeros(nlab * 9))
# end
# function Base.show(io::IO, o::FastTree) 
#     print(io, "FastTree: (keys, stats)=", size(o.tree[1].data), " | size=",length(o.tree))
# end

# function fit!(o::FastTree, xy, γ)
#     x, y = xy 
#     node = whichleaf(o, x)
#     fit!(node, xy, γ)
#     if length(o.tree) < o.maxsize && nobs(node) > o.splitsize 
#         split!(o, node)
#     end
# end

# nkeys(o::FastTree) = nkeys(first(o.tree))
# nvars(o::FastTree) = nvars(first(o.tree))

# function whichleaf(o, x::VectorOb)
#     i = 1
#     node = o.tree[1]
#     while length(node.children) > 0
#         node = o.tree[child(node, x)]
#     end
#     node
# end

# classify(o::FastTree, x::VectorOb) = classify(whichleaf(o,x))
# classify(o::FastTree, x::AbstractMatrix, ::Rows = Rows()) = mapslices(xi->classify(o,xi), x, 2)
# classify(o::FastTree, x::AbstractMatrix, ::Cols) = mapslices(xi->classify(o,xi), x, 1)




# #-----------------------------------------------------------------------# FastForest 
# """
#     FastForest(p, nclasses; nt, b, λ, kw...)

# Build a random forest of [`FastTree`](@ref) trees with `p` predictors.  Each tree 
# in the forest recieves a random subset of predictors of size `b`.  For a new observation,
# each tree in the forest is updated with probability `λ`.  The keyword arguments are:

# - `nt=40`: Number of trees in the forest 
# - `b=floor(Int,sqrt(p))`: Number of random predictors to use for each tree
# - `λ = .05`: Probability of a tree being updated for any given observation
# - `maxsize=1000`:  Maximum number of nodes in any tree in the forest
# - `splitsize=2000`: How many observations a node can observe before it splits

# # Example 

#     x = randn(10^5, 10)
#     y = (x[:, 1] .> 0) .+ 1

#     s = series((x,y), FastForest(10, 2))

#     yhat = classify(s.stats[1], x)
#     mean(y .== yhat)
# """
# struct FastForest{T} <: ExactStat{(1, 0)}
#     forest::Vector{Pair{Vector{Int}, FastTree{T}}}  # subset => tree
#     p::Int
#     λ::Float64
# end
# function FastForest(p::Int, nclass::Int; nt=40, b=floor(Int, sqrt(p)), λ=.05, kw...)
#     forest = [Pair(sort!(sample(1:p, b, replace=false)), FastTree(b, nclass; kw...)) for i in 1:nt]
#     FastForest(forest, p, λ)
# end
# function Base.show(io::IO, o::FastForest)
#     print(io, "FastForest(")
#     print(io, "nt = $(length(o.forest)), subset = $(length(first(o.forest[1])))/$(o.p))")
# end
# nkeys(o::FastForest) = nkeys(o.forest[1][2])
# function fit!(o::FastForest, xy, γ)
#     x, y = xy
#     for i in eachindex(o.forest)
#         if rand() < o.λ 
#             subset, tree = o.forest[i]
#             fit!(tree, (x[subset], y), γ)
#         end
#     end
# end

# function _predict(o::FastForest, x::VectorOb, buffer::Vector{Int})
#     for item in o.forest 
#         subset, tree = item 
#         xi = @view(x[subset])
#         buffer[classify(tree, xi)] += 1
#     end
#     buffer
# end
# _classify(o::FastForest, x::VectorOb, buffer::Vector{Int}) = findmax(_predict(o, x, buffer))[2]

# predict(o::FastForest, x::VectorOb) = _predict(o, x, zeros(Int, nkeys(o)))
# classify(o::FastForest, x::VectorOb) = _classify(o, x, zeros(Int, nkeys(o)))

# function zeros!(v::Vector{Int}) 
#     for i in eachindex(v)
#         @inbounds v[i] = 0 
#     end
#     v
# end 

# function classify(o::FastForest, x::AbstractMatrix, dim::Rows = Rows())
#     buffer = zeros(Int, nkeys(o))
#     mapslices(x -> _classify(o, x, zeros!(buffer)), x, 2)
# end
# function predict(o::FastForest, x::AbstractMatrix, dim::Rows = Rows())
#     buffer = zeros(Int, nkeys(o))
#     mapslices(x -> _predict(o, x, zeros!(buffer)), x, 2)
# end
# function classify(o::FastForest, x::AbstractMatrix, dim::Cols)
#     buffer = zeros(Int, nkeys(o))
#     mapslices(x -> _classify(o, x, zeros!(buffer)), x, 1)
# end
# function predict(o::FastForest, x::AbstractMatrix, dim::Cols)
#     buffer = zeros(Int, nkeys(o))
#     mapslices(x -> _predict(o, x, zeros!(buffer)), x, 1)
# end