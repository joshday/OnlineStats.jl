"""
    NBClassifier(p, T, b = 20)

Create a Naive Bayes classifier for `p` predictors for classes of type `T`.  Conditional
probabilities are estimated using the [`Hist`](@ref) (with `AdaptiveBins`) type with `b` bins.

# Example

    x = randn(100, 5)
    y = rand(Bool, 100)
    o = NBClassifier(5, Bool)
    Series((x,y), o)
    predict(o, x)
    classify(o,x)
"""
struct NBClassifier{T} <: ExactStat{(1, 0)}
    cat::CountMap{T}
    h::Vector{Dict{T, Hist{AdaptiveBins}}}
    b::Int
end
function NBClassifier(p::Integer, T::Type, b::Integer = 20) 
    cat = CountMap(T)
    h = [Dict{T, Hist{AdaptiveBins}}() for i in 1:p]
    NBClassifier(cat, h, b)
end
Base.show(io::IO, o::NBClassifier) = print(io, "NBCLassifier with labels: $(keys(o.cat))")

function fit!(o::NBClassifier, xy::Tuple{VectorOb, ScalarOb}, γ::Float64)
    x, y = xy
    if !haskey(o, y)
        for j in eachindex(x)
            o.h[j][y] = Hist(o.b)
        end
    end
    for j in eachindex(x)
        fit!(o.h[j][y], x[j], γ)
    end
    fit!(o.cat, y, γ)
end

Base.haskey(o::NBClassifier, key) = haskey(o.cat, key)
Base.keys(o::NBClassifier) = keys(o.cat)
Base.values(o::NBClassifier) = values(o.cat)

function predict(o::NBClassifier, x::AbstractVector)
    kys = collect(keys(o))
    vals = values(o)
    probs = log.(collect(vals) ./ sum(vals))
    for i in eachindex(probs)
        for j in eachindex(x)
            probs[i] += log(discretized_pdf(o.h[j][kys[i]], x[j]))
        end
    end
    probs = exp.(probs)
    probs ./ sum(probs)
end

predict(o::NBClassifier, x::AbstractMatrix) = mapslices(x -> predict(o, x), x, 2)

function classify(o::NBClassifier, x::AbstractVector)
    probs = predict(o, x)
    p, i = findmax(probs)
    return collect(keys(o))[i]
end

classify(o::NBClassifier, x::AbstractMatrix) = mapslices(x -> classify(o, x), x, 2)