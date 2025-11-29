# #-----------------------------------------------------------------------# NBClassifier
# mutable struct NBClassifier{T, G<:Group, F} <: OnlineStat{XY}
#     d::OrderedDict{T, G}
#     init::F
#     n::Int
# end
# function NBClassifier(T::Type, xtypes)
#     init = () -> Group(nbclassifier_stat.(xtypes)...)
#     NBClassifier(OrderedDict{T, typeof(init())}(), init, 0)
# end

# nbclassifier_stat(x) = nbclassifier_stat(typeof(x))
# nbclassifier_stat(::Type{<:Number}) = ExpandingHist(100)
# nbclassifier_stat(::Type{T}) where {T} = CountMap{T}()

# AbstractTrees.printnode(io::IO, ::NBClassifier{T}) where {T} = print(io, "NBClassifier | $T")
# AbstractTrees.children(o::NBClassifier) = collect(o.d)
# Base.show(io::IO, o::NBClassifier) = AbstractTrees.print_tree(io, o)

# function _fit!(o::NBClassifier, xy)
#     x, y = xy
#     if haskey(o.d, y)
#         _fit!(o.d[y], x)
#     else
#         o.d[y] = fit!(o.init(), x)
#     end
# end

# _merge!(a::NBClassifier, b::NBClassifier) = merge!(merge!, a.d, b.d)

# function _predict(o::NBClassifier, x, p = zeros(nkeys(o)), n = nobs(o))
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
#     sp == 0.0 ? p : rmul!(p, inv(sp))
# end


"""
    NBClassifier(p::Int, T::Type; stat = Hist(15))

Calculate a naive bayes classifier for classes of type `T` and `p` predictors.  For each
class `K`, predictor variables are summarized by the `stat`.

# Example

```julia
x, y = randn(10^4, 10), rand(Bool, 10^4)

o = fit!(NBClassifier(10, Bool), zip(eachrow(x),y))
collect(keys(o))
probs(o)

xi = randn(10)
predict(o, xi)
classify(o, xi)
```
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

function _predict(o::NBClassifier, x::VectorOb{Number}, p = zeros(nkeys(o)), n = nobs(o))
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
function _classify(o::NBClassifier, x::VectorOb{Number}, p = zeros(nkeys(o)), n = nobs(o))
    _, k = findmax(_predict(o, x, p, n))
    index_to_key(o, k)
end
function index_to_key(d, i)
    for (k, ky) in enumerate(keys(d))
        k == i && return ky
    end
end

predict(o::NBClassifier, x::VectorOb{Number}) = _predict(o, x)
predict(o::NBClassifier, x) = [predict(o, xi) for xi in x]
predict(o::NBClassifier, x::AbstractMatrix) = predict(o, OnlineStatsBase.eachrow(x))

classify(o::NBClassifier, x::VectorOb{Number}) = _classify(o, x)
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
