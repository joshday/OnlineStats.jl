#-----------------------------------------------------------------------# NaiveBayesClassifier 
"""
    NaiveBayesClassifier(T::Type, group::Group)

Build a naive bayes classifier for lables with type `T`.  The `group` stores the sufficient 
statistics of the predictor variables and group stats can be `Hist(nbins)` (continuous), 
`OrderStats(n)` (continuous), or `CountMap(type)` (categorical).
"""
struct NaiveBayesClassifier{T, G<:Group} <: OnlineStat{(1, 0)}
    groups::Vector{G}
    labels::Vector{T}
    nobs::Vector{Int}
    empty_group::G
end
NaiveBayesClassifier(T::Type, g::G) where {G} = NaiveBayesClassifier(G[], T[], Int[], g)
default_weight(o::NaiveBayesClassifier) = default_weight(o.empty_group)
function Base.show(io::IO, o::NaiveBayesClassifier)
    println(io, name(o))
    println(io, "    > N Variables: ", nvars(o))
    print(io, "    > Labels: ")
    for (lab, prob) in zip(o.labels, probs(o))
        print(io, "\n        > $lab ($(round(prob, 3)))")
    end
end
probs(o::NaiveBayesClassifier) = length(o.nobs) > 0 ? o.nobs ./ sum(o.nobs) : Float64[]
function fit!(o::NaiveBayesClassifier, xy, γ)
    x, y = xy 
    add = true 
    for i in eachindex(o.labels)
        @inbounds if y == o.labels[i]
            fit!(o.groups[i], x, 1 / (o.nobs[i] += 1))
            add = false
        end
    end
    if add
        push!(o.nobs, 1)
        push!(o.labels, y)
        g = copy(o.empty_group)
        fit!(g, x, 1.0)
        push!(o.groups, g)
    end
end
Base.getindex(o::NaiveBayesClassifier, i) = getindex.(o.groups, i)
Base.keys(o::NaiveBayesClassifier) = o.labels
impurity(probs, f::Function = x -> entropy(x, 2)) = f(probs)
nvars(o::NaiveBayesClassifier) = length(o.empty_group)
nkeys(o::NaiveBayesClassifier) = length(o.labels)

function Base.sort!(o::NaiveBayesClassifier)
    perm = sortperm(o.labels)
    o.groups[:] = o.groups[perm]
    o.labels[:] = o.labels[perm]
    o.nobs[:] = o.nobs[perm]
    o
end

# log P(x | class_k)
# generated function to unroll loop
@generated function cond_lpdf(o::NaiveBayesClassifier{T, G}, k, x) where {T, S, G <: Group{S}}
    N = length(fieldnames(S))
    quote 
        out = 0.0 
        group_k = o.groups[k]
        Base.Cartesian.@nexprs $N i -> out += log(_pdf(group_k[i], x[i]))
        out
    end
end

function _predict(o::NaiveBayesClassifier, x::VectorOb, sortit::Bool, buffer::Vector{Float64})
    sortit && sort!(o)
    buffer .= log.(o.nobs ./ sum(o.nobs))
    for k in 1:nkeys(o)
        buffer[k] += cond_lpdf(o, k, x) + ϵ
    end
    buffer .= exp.(buffer)
    buffer .= buffer ./ sum(buffer)
end
function _classify(o::NaiveBayesClassifier, x::VectorOb, sortit::Bool, buffer::Vector{Float64})
    _predict(o, x, sortit, buffer)
    _, k = findmax(buffer)
    o.labels[k]
end

predict(o::NaiveBayesClassifier, x::VectorOb, sortit = false) = _predict(o, x, sortit, zeros(nkeys(o)))
classify(o::NaiveBayesClassifier, x::VectorOb, sortit = false) = _classify(o, x, sortit, zeros(nkeys(o)))

function predict(o::NaiveBayesClassifier, x::AbstractMatrix, sortit=false)
    sortit && sort!(o)
    buffer = zeros(nkeys(o))
    mapslices(x -> _predict(o, x, false, buffer), x, 2)
end
function classify(o::NaiveBayesClassifier, x::AbstractMatrix, sortit=false)
    out = fill(o.labels[1], size(x, 1))
    buffer = zeros(nkeys(o))
    for i in eachindex(out)
        out[i] = _classify(o, @view(x[i, :]), false, buffer)
    end
    out
end


#-----------------------------------------------------------------------# Decision Splits
function make_splits(o::NaiveBayesClassifier)
    splits = []
    impurity_root = impurity(probs(o))
    nleft = zeros(Int, nkeys(o))
    for j in 1:nvars(o)
        push!(splits, best_split(o, j, nleft))
    end
    splits
end

# best split possible on variable j
function best_split(o::NaiveBayesClassifier, j, nleft)
    ss = op[j]
    stat = merge(ss)
    candidates = split_candidates(stat)
    splits = [split(ss, j, candidates[1])]
    for loc in candidates[2:end]
        push!(splits, split(stat, j, loc, nleft))
    end
end

function split(stat::Hist, j::Int, at, nleft::Vector{Int})

end

function make_splits(v::Vector{<:Hist}, nleft, ntotal, impurity_root, j)
    splits = []
    for loc in split_candidates(merge(v))
        nleft .= 0
        for (k, h) in enumerate(v)
            nleft[k] += round(Int, sum(h, loc))
        end
        nleft_sum = sum(nleft)
        impurity_left = impurity(nleft ./ nleft_sum)
        impurity_right = impurity((ntotal .- nleft) ./ (sum(ntotal) - nleft_sum))
        impurity_after = smooth(impurity_right, impurity_left, nleft_sum / sum(ntotal))
        ig = impurity_root - impurity_after
        push!(splits, ContinuousSplit())
    end
end


struct ContinuousSplit{T}
    j::Int 
    loc::T  
    ig::Float64 
end
struct CategoricalSplit{T}
    j::Int 
    left::Vector{T}  # categories going into left child
    ig::Float64
end



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
