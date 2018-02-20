#-----------------------------------------------------------------------# LabelStats
mutable struct LabelStats{T, S} <: ExactStat{(1, 0)}
    label::T 
    stats::S  # Tuple or MV
    nobs::Int
end
LabelStats(label, stats::Tuple) = LabelStats(label, stats, 0)
LabelStats(label, stats::MV) = LabelStats(label, stats, 0)
function Base.show(io::IO, o::LabelStats)
    print(io, "LabelStats: ")
    for (i, s) in enumerate(o.stats)
        print(io, name(s, false, false), " ")
    end
end
nobs(o::LabelStats) = o.nobs
function fit!(o::LabelStats, xy, γ) 
    o.nobs += 1
    x, y = xy 
    y == o.label || error("observation label doesn't match")
    fitstats!(o.stats, x, γ)
end
function fitstats!(o::Tuple, x, γ)
    for (oi, xi) in zip(o.stats, x)
        fit!(oi, xi, γ)
    end
end
fitstats!(o::MV, y, γ) = fit!(o, y, γ)

#-----------------------------------------------------------------------# Labels 
struct Labels{T, S} <: ExactStat{(1, 0)}
    value::Vector{LabelStats{T, S}}
    empty_stats::S
end
Labels(T::Type, stats) = Labels(LabelStats{T, typeof(stats)}[], stats)
function Base.show(io::IO, o::Labels)
    print(io, name(o))
    for (v, p) in zip(o.value, probs(o))
        print(io, "\n    > ", v.label, " ($(round(p, 4)))")
    end
end
Base.keys(o::Labels) = [ls.label for ls in o.value]
Base.length(o::Labels) = length(o.value)
nobs(o::Labels) = length(o) > 0 ? sum(nobs, o.value) : 0
probs(o::Labels) = length(o) > 0 ? nobs.(o.value) ./ nobs(o) : Float64[]

# P(x_j | y_k)
condprobs(o::Labels{T, <:Tuple}, k, xj) where {T} = _pdf.(o.value[k].stats, xj)
condprobs(o::Labels{T, <:MV}, k, xj) where {T} = _pdf.(o.value[k].stats.stats, xj)

function fit!(o::Labels, xy, γ)
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

#------------------------------------------------------------------# NBClassifier
"""
    NBClassifier(p, label_type::Type)

Naive Bayes Classifier of `p` predictors for classes of type `label_type`.
"""
struct NBClassifier{T, S} <: ExactStat{(1, 0)}
    labels::Labels{T, S}
end
NBClassifier(stats, T::Type) = NBClassifier(Labels(T, stats))
NBClassifier(p::Int, T::Type) = NBClassifier(p * Hist(10), T)

for f in [:nobs, :probs, :(Base.keys), :(Base.length)]
    @eval $f(o::NBClassifier) = $f(o.labels)
end
condprobs(o::NBClassifier, k, x) = condprobs(o.labels, k, x)

function Base.show(io::IO, o::NBClassifier{T}) where {T}
    println(io, "NBClassifier{$T}")
    print(io, "  ", o.labels)
end
fit!(o::NBClassifier, xy, γ) = fit!(o.labels, xy, γ)

function predict(o::NBClassifier{T, S}, x::VectorOb) where {T, S <: MV}
    pvec = log.(probs(o))  # prior
    for k in eachindex(pvec)
        pvec[k] += sum(log, condprobs(o, k, x))
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