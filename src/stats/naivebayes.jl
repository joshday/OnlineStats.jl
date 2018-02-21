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
NBClassifier(p::Int, T::Type) = NBClassifier(p * Hist(10), T)

function Base.show(io::IO, o::NBClassifier)
    print(io, name(o))
    for (v, p) in zip(o.value, probs(o))
        print(io, "\n    > ", v.label, " ($(round(p, 4)))")
    end
end
Base.keys(o::NBClassifier) = [ls.label for ls in o.value]
Base.getindex(o::NBClassifier, j) = [v.stats[j] for v in o.value]
Base.length(o::NBClassifier) = length(o.value)
nobs(o::NBClassifier) = length(o) > 0 ? sum(nobs, o.value) : 0
probs(o::NBClassifier) = length(o) > 0 ? nobs.(o.value) ./ nobs(o) : Float64[]
nparams(o::NBClassifier) = length(o.empty_stats)


# P(x_j | y_k)
condprobs(o::NBClassifier{T, <:Tuple}, k, xj) where {T} = _pdf.(o.value[k].stats, xj)
condprobs(o::NBClassifier{T, <:MV}, k, xj) where {T} = _pdf.(o.value[k].stats.stats, xj)

entropybase2(p) = entropy(p, 2)
impurity(o::NBClassifier, f::Function = entropybase2) = f(probs(o))

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


# IG from splitting on variable j at point x
function info_gain(o::NBClassifier, j, x)
    stats = o[j]

end


# TODO: something smarter
function split_candidates(o::NBClassifier, j)
    μs = mean.(o[j])
    sort!(μs)
    [(mean(μs[i]) + mean(μs[i-1])) / 2 for i in 2:length(μs)]
end




# information gain from splitting on variable j
function info_gain(o::NBClassifier, j)
    xs = trysplits(o, j)
    stats = o[j]

end


# nobs of left and right children after splitting on variable j at point x
function split_nobs(o::NBClassifier{T, MV{S}}, j, x) where {T, S <: Hist}
    out_left = Int[]
    out_right = Int[]
    stats = o[j]  # stats[1] = key 1's Hist
    for s in stats 
        n1, n2 = splitcounts(s, x)
        push!(out_left, n1)
        push!(out_right, n2)
    end
    out_left, out_right
end

