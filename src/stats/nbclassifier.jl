#-----------------------------------------------------------------------# NBClassifier
"""
    NBClassifier(p::Int, T::Type; stat = Hist(15))

Calculate a naive bayes classifier for classes of type `T` and `p` predictors.  For each
class `K`, predictor variables are summarized by the `stat`.

# Example 

    x, y = randn(10^4, 10), rand(Bool, 10^4)

    o = fit!(NBClassifier(10, Bool), (x,y))
    collect(keys(o))
    probs(o)

    xi = randn(10)
    predict(o, xi)
    classify(o, xi)
"""
mutable struct NBClassifier{T, G<:Group} <: OnlineStat{XY}
    d::OrderedDict{T, G}
    init::G
    # For trees
    id::Int 
    j::Int 
    at::Union{Number, String, Symbol, Char}
    ig::Float64
    children::Vector{Int}
end
function NBClassifier{T}(g::G; id=1) where {T,G} 
    NBClassifier{T,G}(OrderedDict{T,G}(), g, id, 0, -Inf, -Inf, Int[])
end
function NBClassifier(g::G, T::Type; id=1) where {G<:Group}
    NBClassifier(OrderedDict{T, G}(), g, id, 0, -Inf, -Inf, Int[])
end
function NBClassifier(p::Int, T::Type; id=1, stat=KHist(10))
    NBClassifier(p * stat, T; id=id)
end
function Base.show(io::IO, o::NBClassifier)
    print(io, "NBClassifier")
    for (k, p) in zip(keys(o), probs(o))
        print(io, "\n    > $k ($(round(p, digits=4)))")
    end
end
function _fit!(o::NBClassifier, xy)
    x, y = xy 
    if haskey(o.d, y)
        _fit!(o.d[y], x)
    else 
        stat = copy(o.init)
        _fit!(stat, x)
        o.d[y] = stat
    end
end
_merge!(o::NBClassifier, o2::NBClassifier) = merge!(merge!, o.d, o2.d)
Base.getindex(o::NBClassifier, j) = [stat[j] for stat in values(o.d)]

Base.keys(o::NBClassifier) = keys(o.d)
Base.values(o::NBClassifier) = values(o.d)
nkeys(o::NBClassifier) = length(o.d)
nvars(o::NBClassifier) = length(o.init)
nobs(o::NBClassifier) = isempty(o.d) ? 0 : sum(nobs, values(o))
probs(o::NBClassifier) = isempty(o.d) ? zeros(0) : map(nobs, values(o)) ./ nobs(o)

function _predict(o::NBClassifier, x::VectorOb, p = zeros(nkeys(o)), n = nobs(o))
    for (k, gk) in enumerate(values(o))
        # P(Ck)
        p[k] = log(nobs(gk) / n + ϵ) 
        # P(xj | Ck)
        for j in 1:length(x)
            p[k] += log(pdf(gk[j], x[j]) + ϵ)
        end
        p[k] = exp(p[k])
    end
    sp = sum(p)
    sp == 0.0 ? p : rmul!(p, inv(sp))
end
function _classify(o::NBClassifier, x::VectorOb, p = zeros(nkeys(o)), n = nobs(o)) 
    _, k = findmax(_predict(o, x, p, n))
    index_to_key(o, k)
end
function index_to_key(d, i)
    for (k, ky) in enumerate(keys(d))
        k == i && return ky 
    end
end

predict(o::NBClassifier, x::VectorOb) = _predict(o, x)
predict(o::NBClassifier, x) = [predict(o, xi) for xi in x]
predict(o::NBClassifier, x::AbstractMatrix) = predict(o, OnlineStatsBase.eachrow(x))

classify(o::NBClassifier, x::VectorOb) = _classify(o, x)
classify(o::NBClassifier, x) = [classify(o, xi) for xi in x]
classify(o::NBClassifier, x::AbstractMatrix) = classify(o, OnlineStatsBase.eachrow(x))

# Tree stuff

function classify_node(o::NBClassifier)
    _, k = findmax([nobs(g) for g in values(o)])
    index_to_key(o, k)
end

function split!(o::NBClassifier)
    nroot = [nobs(g) for g in values(o)]
    nleft, nright = copy(nroot), copy(nroot)
    entropy_root = entropy(o)
end

entropy(o::NBClassifier) = entropy(probs(o), 2)

#  function split(o::NBClassifier)
#     nroot = [nobs(g) for g in values(o)]
#     nleft = copy(nroot)
#     nright = copy(nroot)
#     split = NBSplit(length(nroot))
#     entropy_root = entropy(o)
#     for j in 1:nvars(o)
#         ss = o[j]
#         stat = merge(ss)
#         for loc in split_candidates(stat)
#             for k in 1:nkeys(o)
#                 nleft[k] = round(Int, n_sent_left(ss[k], loc))
#             end
#             entropy_left = entropy(nleft ./ sum(nleft))
#             @. nright = nroot - nleft
#             entropy_right = entropy(nright ./ sum(nright))
#             entropy_after = smooth(entropy_right, entropy_left, sum(nleft) / sum(nroot))
#             ig = entropy_root - entropy_after
#             if ig > split.ig
#                 split.j = j
#                 split.at = loc
#                 split.ig = ig 
#                 split.nleft .= nleft
#             end
#         end
#     end
#     left = NBClassifier(collect(keys(o)), o.init)
#     right = NBClassifier(collect(keys(o)), o.init)
#     for (i, g) in enumerate(values(left.d))
#         g.nobs = split.nleft[i]
#     end
#     for (i, g) in enumerate(values(right.d))
#         g.nobs = nroot[i] - split.nleft[i]
#     end
#     o, split, left, right
# end

# #-----------------------------------------------------------------------# NBClassifier 
# """
#     NBClassifier(group::Group, labeltype::Type)

# Create a naive bayes classifier, using the stats in `group` to approximate the 
# distributions of each predictor variable conditioned on label.

# - For continuous variables, use [`Hist(nbin)`](@ref). 
# - For categorical variables, use [`CountMap(T)`](@ref).

# # Example

#     x = randn(10^5, 10)
#     y = rand(1:5, 10^5)
#     o = NBClassifier(10Hist(20), Float64)
#     series((x, y), o)
#     predict(o, x)
#     classify(o, x)
# """
# struct NBClassifier{T, G <: Group} <: ExactStat{(1, 0)}
#     d::OrderedDict{T, G}  # class => group
#     init::G        # empty group
# end
# NBClassifier(T::Type, g::G) where {G<:Group} = NBClassifier(OrderedDict{T,G}(), g)
# NBClassifier(g::Group, T::Type) = NBClassifier(T, g)
# function NBClassifier(labels::Vector{T}, g::G) where {T, G<:Group} 
#     NBClassifier(OrderedDict{T, G}(lab=>copy(g) for lab in labels), g)
# end 
# NBClassifier(p::Int, T::Type, b=20) = NBClassifier(T, p * Hist(b))


# function Base.show(io::IO, o::NBClassifier)
#     print(io, name(o))
#     sd = sort(o.d)
#     for di in sd
#         print(io, "\n    > ", first(di), " (", round(nobs(last(di)) / nobs(o), 4), ")")
#     end
# end

# Base.keys(o::NBClassifier) = keys(o.d)
# Base.values(o::NBClassifier) = values(o.d)
# Base.haskey(o::NBClassifier, y) = haskey(o.d, y)
# nvars(o::NBClassifier) = length(o.init)
# nkeys(o::NBClassifier) = length(o.d)
# nobs(o::NBClassifier) = sum(nobs, values(o))
# probs(o::NBClassifier) = [nobs(g) for g in values(o)] ./ nobs(o)
# Base.getindex(o::NBClassifier, j) = [stat[j] for stat in values(o)]

# # d is an object that iterates keys in known order
# function index_to_key(d, i)
#     for (k, ky) in enumerate(keys(d))
#         k == i && return ky 
#     end
# end

# function fit!(o::NBClassifier, xy, γ)
#     x, y = xy 
#     if haskey(o, y)
#         g = o.d[y]
#         fit!(g, x, 1 / (nobs(g) + 1))
#     else 
#         o.d[y] = fit!(copy(o.init), x, 1.0)
#     end
# end
# entropy(o::NBClassifier) = entropy(probs(o), 2)

# function _predict(o::NBClassifier, x::VectorOb, p = zeros(nkeys(o)), n = nobs(o))
#     for (k, gk) in enumerate(values(o))
#         # P(Ck)
#         p[k] = log(nobs(gk) / n + ϵ) 
#         # P(xj | Ck)
#         for j in 1:length(x)
#             p[k] += log(pdf(gk[j], x[j]) + ϵ)
#         end
#         p[k] = exp(p[k])
#     end
#     sp = sum(p)
#     sp == 0.0 ? p : p ./= sum(p)
# end
# function _classify(o::NBClassifier, x::VectorOb, p = zeros(nkeys(o)), n = nobs(o)) 
#     _, k = findmax(_predict(o, x, p, n))
#     index_to_key(o, k)
# end
# predict(o::NBClassifier, x::VectorOb) = _predict(o, x)
# classify(o::NBClassifier, x::VectorOb) = _classify(o, x)
# function classify_node(o::NBClassifier)
#     _, k = findmax([nobs(g) for g in values(o)])
#     index_to_key(o, k)
# end
# for f in [:(_predict), :(_classify)]
#     @eval begin 
#         function $f(o::NBClassifier, x::AbstractMatrix, ::Rows = Rows())
#             n = nobs(o)
#             p = zeros(nkeys(o))
#             mapslices(xi -> $f(o, xi, p, n), x, 2)
#         end
#         function $f(o::NBClassifier, x::AbstractMatrix, ::Cols)
#             n = nobs(o)
#             p = zeros(nkeys(o))
#             mapslices(xi -> $f(o, xi, p, n), x, 1)
#         end
#     end
# end

# function split(o::NBClassifier)
#     nroot = [nobs(g) for g in values(o)]
#     nleft = copy(nroot)
#     nright = copy(nroot)
#     split = NBSplit(length(nroot))
#     entropy_root = entropy(o)
#     for j in 1:nvars(o)
#         ss = o[j]
#         stat = merge(ss)
#         for loc in split_candidates(stat)
#             for k in 1:nkeys(o)
#                 nleft[k] = round(Int, n_sent_left(ss[k], loc))
#             end
#             entropy_left = entropy(nleft ./ sum(nleft))
#             @. nright = nroot - nleft
#             entropy_right = entropy(nright ./ sum(nright))
#             entropy_after = smooth(entropy_right, entropy_left, sum(nleft) / sum(nroot))
#             ig = entropy_root - entropy_after
#             if ig > split.ig
#                 split.j = j
#                 split.at = loc
#                 split.ig = ig 
#                 split.nleft .= nleft
#             end
#         end
#     end
#     left = NBClassifier(collect(keys(o)), o.init)
#     right = NBClassifier(collect(keys(o)), o.init)
#     for (i, g) in enumerate(values(left.d))
#         g.nobs = split.nleft[i]
#     end
#     for (i, g) in enumerate(values(right.d))
#         g.nobs = nroot[i] - split.nleft[i]
#     end
#     o, split, left, right
# end

# n_sent_left(o::Union{OrderStats, Hist}, loc) = sum(o, loc)
# n_sent_left(o::CountMap, label) = o[label]

# #-----------------------------------------------------------------------# NBSplit
# # Continuous:  x[j] < at 
# # Categorical: x[j] == at
# mutable struct NBSplit{}
#     j::Int 
#     at::Any
#     ig::Float64 
#     nleft::Vector{Int}
# end
# NBSplit(n=0) = NBSplit(0, -Inf, -Inf, zeros(Int, n))

# whichchild(o::NBSplit, x) = x[o.j] < o.at ? 1 : 2

# #-----------------------------------------------------------------------# NBNode
# mutable struct NBNode{T <: NBClassifier} <: ExactStat{(1, 0)}
#     nbc::T
#     id::Int 
#     parent::Int 
#     children::Vector{Int}
#     split::NBSplit
# end
# function NBNode(o::NBClassifier; id = 1, parent = 0, children = Int[], split = NBSplit()) 
#     NBNode(o, id, parent, children, split)
# end
# function Base.show(io::IO, o::NBNode)
#     print(io, "NBNode ", o.id)
#     if o.split.j > 0
#         print(io, " (split on $(o.split.j)")
#     end
# end

# #-----------------------------------------------------------------------# NBTree 
# """
#     NBTree(o::NBClassifier; maxsize=5000, splitsize=1000)

# Create a decision tree where each node is a naive bayes classifier.  A node will split 
# when it reaches `splitsize` observations and no more splits will occur once `maxsize` 
# nodes are in the tree.

# # Example 

#     x = randn(10^5, 10)
#     y = rand(Bool, 10^5)
#     o = NBTree(NBClassifier(10Hist(20), Bool))
#     series((x,y), o)
#     classify(o, x)
# """
# mutable struct NBTree{T<:NBNode} <: ExactStat{(1, 0)}
#     tree::Vector{T}
#     maxsize::Int
#     splitsize::Int
# end
# function NBTree(o::NBClassifier; maxsize = 5000, splitsize = 1000)
#     NBTree([NBNode(o)], maxsize, splitsize)
# end
# NBTree(args...; kw...) = NBTree(NBClassifier(args...); kw...)
# function Base.show(io::IO, o::NBTree)
#     print(io, "NBTree(size = $(length(o.tree)), splitsize=$(o.splitsize))")
# end

# function fit!(o::NBTree, xy, γ)
#     x, y = xy 
#     i, node = whichleaf(o, x)
#     fit!(node.nbc, xy, γ)
#     if length(o.tree) < o.maxsize && nobs(node.nbc) >= o.splitsize 
#         nbc, spl, left_nbc, right_nbc = split(node.nbc)
#         # if spl.ig > o.cp
#             node.split = spl
#             node.children = [length(o.tree) + 1, length(o.tree) + 2]
#             t = length(o.tree)
#             left =  NBNode(left_nbc,  id = t + 1, parent = i)
#             right = NBNode(right_nbc, id = t + 2, parent = i)
#             push!(o.tree, left)
#             push!(o.tree, right)
#         # end
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

# function classify(o::NBTree, x::VectorOb)
#     i, node = whichleaf(o, x)
#     classify_node(node.nbc)
# end
# function classify(o::NBTree, x::AbstractMatrix)
#     mapslices(xi -> classify(o, xi), x, 2)
# end