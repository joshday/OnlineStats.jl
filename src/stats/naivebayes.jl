#-----------------------------------------------------------------------# CDists 
# Conditional Distributions
struct CDists{T, G<:Group} <: OnlineStat{(1, 0)}
    groups::Vector{G}
    labels::Vector{T}
    nobs::Vector{Int}
    empty_group::G
end
CDists(T::Type, g::G) where {G} = CDists(G[], T[], Int[], g)
default_weight(o::CDists) = default_weight(o.empty_group)
function Base.show(io::IO, o::CDists)
    print(io, name(o))
    for (lab, prob) in zip(o.labels, probs(o))
        print(io, "\n    > ", lab, "(", prob, ")")
    end
end
probs(o::CDists) = length(o.nobs) > 0 ? o.nobs ./ sum(o.nobs) : [0.0]
function fit!(o::CDists, xy, γ)
    x, y = xy 
    add = true 
    for i in eachindex(o.labels)
        if y == o.labels[i]
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
Base.getindex(o::CDists, i) = getindex.(o.groups, i)

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

entropybase2(p) = entropy(p, 2)
impurity(o::NBClassifier, f::Function = entropybase2) = f(probs(o))
impurity(probs, f::Function = entropybase2) = f(probs)

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
