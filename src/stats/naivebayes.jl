#-----------------------------------------------------------------------# NB 
export NB

struct NB{T, G <: Group} <: ExactStat{(1, 0)}
    d::OrderedDict{T, G}  # class => group
    init::G        # empty group
end
NB(T::Type, g::G) where {G<:Group} = NB(OrderedDict{T,G}(), g)
NB(labels::Vector{T}, g::G) where {T, G<:Group} = NB(OrderedDict{T, G}(lab=>copy(g) for lab in labels), g)

function Base.show(io::IO, o::NB)
    println(io, name(o))
    sd = sort(o.d)
    for di in sd
        print(io, "    > ", first(di), " (", round(nobs(last(di)) / nobs(o), 4), ")")
    end
end

Base.keys(o::NB) = keys(o.d)
Base.values(o::NB) = values(o.d)
Base.haskey(o::NB, y) = haskey(o.d, y)
nvars(o::NB) = length(o.init)
nkeys(o::NB) = length(o.d)
nobs(o::NB) = sum(nobs, values(o))
probs(o::NB) = [nobs(g) for g in values(o)] ./ nobs(o)
Base.getindex(o::NB, j) = [stat[j] for stat in values(o)]

# d is an object that iterates keys in known order
function index_to_key(d, i)
    for (k, ky) in enumerate(keys(d))
        k == i && return ky 
    end
end

function fit!(o::NB, xy, γ)
    x, y = xy 
    if haskey(o, y)
        g = o.d[y]
        fit!(g, x, 1 / (nobs(g) + 1))
    else 
        o.d[y] = fit!(copy(o.init), x, 1.0)
    end
end
entropy(o::NB) = entropy(probs(o), 2)

function predict(o::NB, x::VectorOb, p = zeros(nkeys(o)), n = nobs(o))
    for (k, gk) in enumerate(values(o))
        # P(Ck)
        p[k] = log(nobs(gk) / n + ϵ) 
        # P(xj | Ck)
        for j in eachindex(x)
            p[k] += log(_pdf(gk[j], x[j]) + ϵ)
        end
        p[k] = exp(p[k])
    end
    sp = sum(p)
    sp == 0.0 ? p : p ./= sum(p)
end
function classify(o::NB, x::VectorOb, p = zeros(nkeys(o)), n = nobs(o)) 
    _, k = findmax(predict(o, x, p, n))
    index_to_key(o, k)
end
function classify_node(o::NB)
    _, k = findmax([nobs(g) for g in values(o)])
    index_to_key(o, k)
end
for f in [:predict, :classify]
    @eval begin 
        function $f(o::NB, x::AbstractMatrix, ::Rows = Rows())
            n = nobs(o)
            p = zeros(nkeys(o))
            mapslices(xi -> $f(o, xi, p, n), x, 2)
        end
        function $f(o::NB, x::AbstractMatrix, ::Cols)
            n = nobs(o)
            p = zeros(nkeys(o))
            mapslices(xi -> $f(o, xi, p, n), x, 1)
        end
    end
end

function split(o::NB)
    nroot = [nobs(g) for g in values(o)]
    nleft = copy(nroot)
    nright = copy(nroot)
    split = NBSplit(length(nroot))
    entropy_root = entropy(o)
    for j in 1:nvars(o)
        ss = o[j]
        stat = merge(ss)
        for loc in split_candidates(stat)
            for k in 1:nkeys(o)
                nleft[k] = round(Int, n_sent_left(ss[k], loc))
            end
            entropy_left = entropy(nleft ./ sum(nleft))
            @. nright = nroot - nleft
            entropy_right = entropy(nright ./ sum(nright))
            entropy_after = smooth(entropy_right, entropy_left, sum(nleft) / sum(nroot))
            ig = entropy_root - entropy_after
            if ig > split.ig
                split.j = j
                split.at = loc
                split.ig = ig 
                split.nleft .= nleft
            end
        end
    end
    left = NB(collect(keys(o)), o.init)
    right = NB(collect(keys(o)), o.init)
    for (i, g) in enumerate(values(left.d))
        g.nobs = split.nleft[i]
    end
    for (i, g) in enumerate(values(right.d))
        g.nobs = nroot[i] - split.nleft[i]
    end
    info("split occured on $(split.j) with ig $(split.ig): $(split.nleft), ", nroot - split.nleft)
    o, split, left, right
end

n_sent_left(o::Union{OrderStats, Hist}, loc) = sum(o, loc)
n_sent_left(o::CountMap, label) = o[label]

#-----------------------------------------------------------------------# NBSplit
# Continuous:  x[j] < at 
# Categorical: x[j] == at
mutable struct NBSplit{}
    j::Int 
    at::Any
    ig::Float64 
    nleft::Vector{Int}
end
NBSplit(n=0) = NBSplit(0, -Inf, -Inf, zeros(Int, n))

whichchild(o::NBSplit, x) = x[o.j] < o.at ? 1 : 2

#-----------------------------------------------------------------------# NBNode
mutable struct NBNode{T <: NB} <: ExactStat{(1, 0)}
    nbc::T
    id::Int 
    parent::Int 
    children::Vector{Int}
    split::NBSplit
end
NBNode(o::NB; id = 1, parent = 0, children = Int[], split = NBSplit()) = NBNode(o, id, parent, children, split)
function Base.show(io::IO, o::NBNode)
    print(io, "NBNode ", o.id)
    if o.split.j > 0
        print(io, " (split on $(o.split.j)")
    end
end

#-----------------------------------------------------------------------# NBTree 
mutable struct NBTree{T<:NBNode} <: ExactStat{(1, 0)}
    tree::Vector{T}
    maxsize::Int
    minsplit::Int
end
function NBTree(o::NB; maxsize = 5000, minsplit = 1000)
    NBTree([NBNode(o)], maxsize, minsplit)
end
NBTree(args...; kw...) = NBTree(NB(args...); kw...)
function Base.show(io::IO, o::NBTree)
    print(io, "NBTree(size = $(length(o.tree)), minsplit=$(o.minsplit))")
end

function fit!(o::NBTree, xy, γ)
    x, y = xy 
    i, node = whichleaf(o, x)
    fit!(node.nbc, xy, γ)
    if length(o.tree) < o.maxsize && nobs(node.nbc) >= o.minsplit 
        nbc, spl, left_nbc, right_nbc = split(node.nbc)
        # if spl.ig > o.cp
            node.split = spl
            node.children = [length(o.tree) + 1, length(o.tree) + 2]
            t = length(o.tree)
            left =  NBNode(left_nbc,  id = t + 1, parent = i)
            right = NBNode(right_nbc, id = t + 2, parent = i)
            push!(o.tree, left)
            push!(o.tree, right)
        # end
    end
end

function whichleaf(o::NBTree, x::VectorOb)
    i = 1 
    node = o.tree[i]
    while length(node.children) > 0
        i = node.children[whichchild(node.split, x)]
        node = o.tree[i]
    end
    i, node
end

function classify(o::NBTree, x::VectorOb)
    i, node = whichleaf(o, x)
    classify_node(node.nbc)
end
function classify(o::NBTree, x::AbstractMatrix)
    mapslices(xi -> classify(o, xi), x, 2)
end



# #-----------------------------------------------------------------------# NaiveBayesClassifier 
# """
#     NaiveBayesClassifier(T::Type, group::Group)

# Build a naive bayes classifier for lables with type `T`.  The `group` stores the sufficient 
# statistics of the predictor variables and group stats can be `Hist(nbins)` (continuous), 
# `OrderStats(n)` (continuous), or `CountMap(type)` (categorical).
# """
# struct NaiveBayesClassifier{T, G<:Group} <: OnlineStat{(1, 0)}
#     groups::Vector{G}
#     labels::Vector{T}
#     nobs::Vector{Int}
#     empty_group::G
# end
# const NBC = NaiveBayesClassifier
# NaiveBayesClassifier(T::Type, g::G) where {G} = NaiveBayesClassifier(G[], T[], Int[], g)
# default_weight(o::NaiveBayesClassifier) = default_weight(o.empty_group)
# function Base.show(io::IO, o::NaiveBayesClassifier)
#     println(io, name(o))
#     println(io, "    > N Variables: ", nvars(o))
#     print(io, "    > Labels: ")
#     for (lab, prob) in zip(o.labels, probs(o))
#         print(io, "\n        > $lab ($(round(prob, 3)))")
#     end
# end
# probs(o::NaiveBayesClassifier) = length(o.nobs) > 0 ? o.nobs ./ sum(o.nobs) : Float64[]
# nobs(o::NaiveBayesClassifier) = sum(o.nobs)
# function fit!(o::NaiveBayesClassifier, xy, γ)
#     x, y = xy 
#     add = true 
#     for i in eachindex(o.labels)
#         @inbounds if y == o.labels[i]
#             fit!(o.groups[i], x, 1 / (o.nobs[i] += 1))
#             add = false
#         end
#     end
#     if add
#         push!(o.nobs, 1)
#         push!(o.labels, y)
#         g = copy(o.empty_group)
#         fit!(g, x, 1.0)
#         push!(o.groups, g)
#     end
# end
# Base.getindex(o::NaiveBayesClassifier, i) = getindex.(o.groups, i)
# Base.keys(o::NaiveBayesClassifier) = o.labels
# impurity(probs, f::Function = x -> entropy(x, 2)) = f(probs)
# nvars(o::NaiveBayesClassifier) = length(o.empty_group)
# nkeys(o::NaiveBayesClassifier) = length(o.labels)

# function Base.sort!(o::NaiveBayesClassifier)
#     perm = sortperm(o.labels)
#     o.groups[:] = o.groups[perm]
#     o.labels[:] = o.labels[perm]
#     o.nobs[:] = o.nobs[perm]
#     o
# end

# # log P(x | class_k)
# # generated function to unroll loop
# @generated function cond_lpdf(o::NaiveBayesClassifier{T, G}, k, x) where {T, S, G <: Group{S}}
#     N = length(fieldnames(S))
#     quote 
#         out = 0.0 
#         group_k = o.groups[k]
#         Base.Cartesian.@nexprs $N i -> out += log(_pdf(group_k[i], x[i]))
#         out
#     end
# end


# function _predict(o::NaiveBayesClassifier, x::VectorOb, sortit::Bool, buffer::Vector{Float64})
#     sortit && sort!(o)
#     buffer .= log.(o.nobs ./ sum(o.nobs))
#     for k in 1:nkeys(o)
#         buffer[k] += cond_lpdf(o, k, x)
#     end
#     buffer .= exp.(buffer)
#     buffer .= buffer ./ sum(buffer)
# end
# function _classify(o::NaiveBayesClassifier, x::VectorOb, sortit::Bool, buffer::Vector{Float64})
#     _predict(o, x, sortit, buffer)
#     _, k = findmax(buffer)
#     o.labels[k]
# end

# predict(o::NaiveBayesClassifier, x::VectorOb, sortit = false) = _predict(o, x, sortit, zeros(nkeys(o)))
# classify(o::NaiveBayesClassifier, x::VectorOb, sortit = false) = _classify(o, x, sortit, zeros(nkeys(o)))

# function predict(o::NaiveBayesClassifier, x::AbstractMatrix, sortit=false)
#     sortit && sort!(o)
#     buffer = zeros(nkeys(o))
#     mapslices(x -> _predict(o, x, false, buffer), x, 2)
# end
# function classify(o::NaiveBayesClassifier, x::AbstractMatrix, sortit=false)
#     out = fill(o.labels[1], size(x, 1))
#     buffer = zeros(nkeys(o))
#     for i in eachindex(out)
#         out[i] = _classify(o, @view(x[i, :]), false, buffer)
#     end
#     out
# end


# #-----------------------------------------------------------------------# Decision Splits
# struct NBSplit{T}
#     j::Int 
#     at::T
#     ig::Float64 
#     nleft::Vector{Int}
# end
# NBSplit(at) = NBSplit(0, at, -Inf, Int[])
# NBSplit(o::NBSplit) = NBSplit(o.at)
# Base.show(io::IO, o::NBSplit) = print(io, "NBSplit(j=", o.j, ", at=", o.at, ", ig=", o.ig, ")")

# whichchild(o::NBSplit{T}, x) where {T<:Number} = x[o.j] < o.at ? 1 : 2
# whichchild(o::NBSplit{T}, x) where {T<:Vector} = x[o.j] in o.at ? 1 : 2


# # split(o) --> (o, split, left, right)
# function split(o::NaiveBayesClassifier{T}) where {T}
#     nroot = o.nobs
#     split = NBSplit(-Inf)
#     imp_root = impurity(probs(o))
#     for j in 1:nvars(o)
#         ss = o[j]           # sufficient statistics for each label
#         stat = merge(ss)    # combined sufficient statistics
#         for loc in split_candidates(stat)
#             nleft = zeros(Int, nkeys(o))
#             for k in 1:nkeys(o)
#                 @inbounds nleft[k] = round(Int, n_sent_left(ss[k], loc))
#             end
#             imp_left = impurity(nleft ./ sum(nleft))
#             nright = nroot - nleft 
#             imp_right = impurity(nright ./ sum(nright))
#             imp_after = smooth(imp_right, imp_left, sum(nleft) / sum(nroot))
#             newsplit = NBSplit(j, loc, imp_root - imp_after, nleft)
#             if newsplit.ig > split.ig 
#                 split = newsplit 
#             end
#         end
#     end
#     left_groups =  [copy(o.empty_group) for i in 1:nkeys(o)]
#     right_groups = [copy(o.empty_group) for i in 1:nkeys(o)]
#     left =  NaiveBayesClassifier(left_groups,  copy(o.labels), split.nleft, copy(o.empty_group))
#     right = NaiveBayesClassifier(right_groups, copy(o.labels), nroot - split.nleft, copy(o.empty_group))
#     o, split, left, right
# end

# n_sent_left(o::Union{OrderStats, Hist}, loc) = sum(o, loc)
# n_sent_left(o::CountMap, label) = o[label]






#################################################################################### 
####################################################################################
####################################################################################
####################################################################################
####################################################################################
#################################################################################### 
############## Everything below here will be deprecated

#-----------------------------------------------------------------------# LabelStats
mutable struct LabelStats{T, G <: Group} <: ExactStat{(1, 0)}
    label::T 
    group::G
    nobs::Int
end
LabelStats(label, group::Group) = LabelStats(label, group, 0)
function Base.show(io::IO, o::LabelStats)
    print(io, "LabelStats: ")
    for (i, s) in enumerate(o.group)
        print(io, name(s, false, false), " ")
    end
end
nobs(o::LabelStats) = o.nobs
function fit!(o::LabelStats, xy, γ) 
    o.nobs += 1
    x, y = xy 
    y == o.label || error("observation label doesn't match")
    fit!(o.group, x, γ)
end

#-----------------------------------------------------------------------# NBClassifier 
"""
    NBClassifier(p, label_type::Type)

Naive Bayes Classifier of `p` predictors for classes of type `label_type`.
"""
struct NBClassifier{T, S} <: ExactStat{(1, 0)}
    value::Vector{LabelStats{T, S}}
    empty_stats::S
end
NBClassifier(T::Type, stats) = NBClassifier(LabelStats{T, typeof(stats)}[], stats)
NBClassifier(stats, T::Type) = NBClassifier(T, stats)
NBClassifier(p::Int, T::Type, b=10) = NBClassifier(Group(p, Hist(b)), T)

function Base.show(io::IO, o::NBClassifier)
    print(io, name(o))
    for (v, p) in zip(o.value, probs(o))
        print(io, "\n    > ", v.label, " ($(round(p, 4)))")
    end
end
Base.keys(o::NBClassifier) = [ls.label for ls in o.value]
Base.getindex(o::NBClassifier, j) = [v.group[j] for v in o.value]
Base.length(o::NBClassifier) = length(o.value)
nobs(o::NBClassifier) = length(o) > 0 ? sum(nobs, o.value) : 0
probs(o::NBClassifier) = length(o) > 0 ? nobs.(o.value) ./ nobs(o) : Float64[]
nparams(o::NBClassifier) = length(o.empty_stats)

# P(x_j | label_k)
condprobs(o::NBClassifier, k, xj) = _pdf.(o.value[k].group.stats, xj)

# entropybase2(p) = entropy(p, 2)
# impurity(o::NBClassifier, f::Function = entropybase2) = f(probs(o))
# impurity(probs, f::Function = entropybase2) = f(probs)

function fit!(o::NBClassifier, xy, γ)
    x, y = xy 
    addlabel = true 
    for v in o.value 
        if v.label == y 
            fit!(v, xy, γ)
            addlabel = false 
            break
        end
    end
    if addlabel 
        ls = LabelStats(y, copy.(o.empty_stats))
        fit!(ls, xy)
        push!(o.value, ls)
    end
end

function predict(o::NBClassifier{T, S}, x::VectorOb) where {T, S <: Group}
    pvec = log.(probs(o))  # prior
    for k in eachindex(pvec)
        pvec[k] += sum(log, condprobs(o, k, x) .+ ϵ)
    end
    out = exp.(pvec)
    out ./ sum(out)
end
classify(o::NBClassifier, x::VectorOb) = keys(o)[findmax(predict(o, x))[2]]


for f in [:predict, :classify]
    @eval begin 
        function $f(o::NBClassifier, x::AbstractMatrix, dim::Rows = Rows())
            mapslices(x -> $f(o, x), x, 2)
        end
        function $f(o::NBClassifier, x::AbstractMatrix, dim::Cols)
            mapslices(x -> $f(o, x), x, 1)
        end
    end
end