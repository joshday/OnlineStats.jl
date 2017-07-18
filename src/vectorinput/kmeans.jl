"""
```julia
KMeans(p, k)
```
Approximate K-Means clustering of `k` clusters of `p` variables
### Example
```julia
using OnlineStats, Distributions
d = MixtureModel([Normal(0), Normal(5)])
y = rand(d, 100_000, 1)
s = Series(y, LearningRate(.6), KMeans(1, 2))
```
"""
mutable struct KMeans <: OnlineStat{1, 2, LearningRate}
    value::MatF
    v::VecF
    KMeans(p::Integer, k::Integer) = new(randn(p, k), zeros(k))
end
Base.show(io::IO, o::KMeans) = print(io, "KMeans($(value(o)'))")
function fit!(o::KMeans, x::VectorOb, γ::Float64)
    d, k = size(o.value)
    length(x) == d || throw(DimensionMismatch())
    for j in 1:k
        o.v[j] = sum(abs2, x - view(o.value, :, j))
    end
    kstar = indmin(o.v)
    for i in 1:d
        o.value[i, kstar] = smooth(o.value[i, kstar], x[i], γ)
    end
end

function fitbatch!{T<:Real}(o::KMeans, x::AMat{T}, γ::Float64)
    d, k = size(o.value)
    size(x, 2) == d || throw(DimensionMismatch())
    x̄ = vec(mean(x, 1))
    for j in 1:k
        o.v[j] = sum(abs2, x̄ - view(o.value, :, j))
    end
    kstar = indmin(o.v)
    for i in 1:d
        o.value[i, kstar] = smooth(o.value[i, kstar], x̄[i], γ)
    end
end
