mutable struct FastNode{G<:Group} <: OnlineStat{XY}
    stats::Vector{G}
    ids::Vector{Int}  # self, left, right
    j::Int
    at::Float64
    ig::Float64
end
function FastNode(p, nkeys=2; stat = FitNormal(), id=1)
    FastNode([p * stat for k in 1:nkeys], [id], 0, 0.0, -Inf)
end
Base.show(io::IO, o::FastNode) =
    print(io, "FastNode | $(nkeys(o)) keys × $(nvars(o)) vars | at=$((o.j, o.at))")

function _fit!(o::FastNode, xy)
    x, y = xy
    y in 1:nkeys(o) || error("y must be an integer in 1:nkeys")
    _fit!(o.stats[y], x)
end
nobs(o::FastNode) = sum(nobs, o.stats)
probs(o::FastNode) = nobs.(o.stats) ./ nobs(o)
nkeys(o::FastNode) = length(o.stats)
nvars(o::FastNode) = length(o.stats[1])
Base.getindex(o::FastNode, i) = [stat[i] for stat in o.stats]

_merge!(o::FastNode, o2::FastNode) = _merge!.(o.stats, o2.stats)

function fakedata(::Type{FastNode}, n, p)
    x = randn(n, p)
    y = [(rand() > 1 /(1 + exp(xb))) + 1 for xb in x * (1:p)]
    x, y
end
function classify(o::FastNode)
    out = 1
    n = nobs(o.stats[1])
    for j in 2:nkeys(o)
        n2 = nobs(o.stats[j])
        if n2 > n
            out = j
            n = n2
        end
    end
    out
end

function whichchild(o::FastNode, x::VectorOb)
    o.j == 0 && return rand(o.ids[2:3])
    x[o.j] < o.at ? o.ids[2] : o.ids[3]
end

impurity(p) = entropy(p, 2)

# tree needs `length` method
function split!(o::FastNode, tree)
    n = nobs(o)
    nl = zeros(nkeys(o))  # "prob" left
    nr = zeros(nkeys(o))  # "prob" right
    imp_before = impurity(probs(o))
    ig = -Inf
    ind = 0
    at = -Inf
    sc = zeros(9 * nkeys(o))
    for j in 1:nvars(o)
        stats_j = o[j]
        k = 0
        for stat in stats_j # split candidates
            μ = mean(stat)
            σ = std(stat)
            sc[k+1] = μ - 2σ
            sc[k+2] = μ - 1.5σ
            sc[k+3] = μ - σ
            sc[k+4] = μ - .5σ
            sc[k+5] = μ
            sc[k+6] = μ + .5σ
            sc[k+7] = μ + σ
            sc[k+8] = μ + 1.5σ
            sc[k+9] = μ + 2σ
            k += 9
        end
        for loc in sc
            for k in 1:nkeys(o)
                stat_kj = stats_j[k]  # summarizes variable j for label k
                # @show cdf(stat_kj, loc), std(stat_kj), nobs(stat_kj)
                nl[k] = cdf(stat_kj, loc) * nobs(stat_kj)
                nr[k] = nobs(stat_kj) - nl[k]
            end
            imp_l = impurity(nl ./ sum(nl))
            imp_r = impurity(nr ./ sum(nr))
            imp_after = smooth(imp_l, imp_r, sum(nr) / n)
            new_ig = imp_before - imp_after
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
    d = length(tree)
    push!(o.ids, d + 1)
    push!(o.ids, d + 2)
    FastNode(nvars(o), nkeys(o); id = d + 1), FastNode(nvars(o), nkeys(o); id = d + 2)
end

#-----------------------------------------------------------------------# FastTree
"""
    FastTree(p::Int, nclasses=2; stat=FitNormal(), maxsize=5000, splitsize=1000)

Calculate a decision tree of `p` predictors variables and classes `1, 2, …, nclasses`.
Nodes split when they reach `splitsize` observations until `maxsize` nodes are in the tree.
Each variable is summarized by `stat`, which can be `FitNormal()` or `Hist(nbins)`.

# Example

```julia
x = randn(10^5, 10)
y = rand([1,2], 10^5)

o = fit!(FastTree(10), zip(eachrow(x),y))

xi = randn(10)
classify(o, xi)
```
"""
struct FastTree{T<:FastNode} <: OnlineStat{XY}
    tree::Vector{T}
    maxsize::Int
    splitsize::Int
end
function FastTree(p, nkeys=2; stat = FitNormal(), maxsize=5000, splitsize=1000)
    tree = [FastNode(p, nkeys; stat=stat)]
    FastTree(tree, maxsize, splitsize)
end
function Base.show(io::IO, o::FastTree)
    print(io, "FastTree(n=", nobs(o))
    print(io, ", size=", length(o.tree))
    print(io, ", maxsize=", o.maxsize)
    print(io, ", splitsize=", o.splitsize)
    print(io, ")")
end
nobs(o::FastTree) = nobs(o.tree[1])
nkeys(o::FastTree) = nkeys(o.tree[1])
nvars(o::FastTree) = nvars(o.tree[1])
Base.length(o::FastTree) = length(o.tree)
function _fit!(o::FastTree, xy)
    x, y = xy
    node = whichleaf(o, x)
    _fit!(node, xy)
    if length(o.tree) < o.maxsize && nobs(node) > o.splitsize
        left, right = split!(node, o.tree)
        push!(o.tree, left)
        push!(o.tree, right)
    end
end

function whichleaf(o, x::VectorOb)
    node = o.tree[1]
    while length(node.ids) > 1
        node = o.tree[whichchild(node, x)]
    end
    node
end

classify(o::FastTree, x::VectorOb) = classify(whichleaf(o, x))
function classify(o::FastTree, x::AbstractMatrix)
    [classify(o, xi) for xi in OnlineStatsBase.eachrow(x)]
end

#-----------------------------------------------------------------------# FastForest
"""
    FastForest(p, nkeys=2; stat=FitNormal(), kw...)

Calculate a random forest where each variable is summarized by `stat`.

# Keyword Arguments

- `nt=100`: Number of trees in the forest
- `b=floor(Int, sqrt(p))`: Number of random features for each tree to receive
- `maxsize=1000`: Maximum size for any tree in the forest
- `splitsize=5000`: Number of observations in any given node before splitting
- `λ = 5 * (1 / nt)`: Probability that each tree is updated on a new observation

# Example

```julia
x, y = randn(10^5, 10), rand(1:2, 10^5)

o = fit!(FastForest(10), zip(eachrow(x),y))

classify(o, x[1,:])
```
"""
mutable struct FastForest{T<:FastTree} <: OnlineStat{XY}
    forest::Vector{T}
    subsets::Matrix{Int}
    p::Int
    λ::Float64
    n::Int
end
function FastForest(p, nkeys=2; stat = FitNormal(), maxsize=1000, splitsize = 5000,
                    nt=100, b=floor(Int, sqrt(p)), λ = 5 * (1 / nt))
    forest = [FastTree(b, nkeys; stat=stat, maxsize=maxsize, splitsize=splitsize) for i in 1:nt]
    subsets = fill(0, b, nt)
    for j in 1:size(subsets, 2)
        subsets[:, j] = sample(1:p, b; replace=false)
    end
    FastForest(forest, subsets, p, λ, 0)
end
nkeys(o::FastForest) = maximum(nkeys(tree) for tree in o.forest)
function Base.show(io::IO, o::FastForest)
    print(io, "FastForest(")
    print(io, "n=", nobs(o))
    print(io, ", nt=", length(o.forest))
    print(io, ", b=", size(o.subsets, 1))
    print(io, ", avg_size=", mean(length, o.forest))
    print(io, ")")
end
function _fit!(o::FastForest, xy)
    x, y = xy
    o.n += 1
    for (tree, subset) in zip(o.forest, OnlineStatsBase.eachcol(o.subsets))
        rand() < o.λ && fit!(tree, (x[subset], y))
    end
end

function _classify(o::FastForest, x::VectorOb, buffer::Vector{Int})
    buffer[:] .= 0
    for (i, tree) in enumerate(o.forest)
        buffer[classify(tree, x[o.subsets[:, i]])] += 1
    end
    findmax(buffer)[2]
end

classify(o::FastForest, x::VectorOb) = _classify(o, x, zeros(Int, nkeys(o)))
function classify(o::FastForest, x::AbstractMatrix)
    buffer = zeros(Int, nkeys(o))
    [_classify(o, xi, buffer) for xi in OnlineStatsBase.eachrow(x)]
end
