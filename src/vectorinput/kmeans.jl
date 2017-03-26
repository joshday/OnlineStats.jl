mutable struct KMeans <: OnlineStat{VectorIn, MatrixOut}
    value::MatF
    v::VecF
    KMeans(p::Integer, k::Integer) = new(randn(p, k), zeros(k))
end
fields_to_show(o::KMeans) = [:value]
function fit!{T<:Real}(o::KMeans, x::AVec{T}, γ::Float64)
    d, k = size(o.value)
    @assert length(x) == d
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
    @assert size(x, 2) == d
    x̄ = vec(mean(x, 1))
    for j in 1:k
        o.v[j] = sum(abs2, x̄ - view(o.value, :, j))
    end
    kstar = indmin(o.v)
    for i in 1:d
        o.value[i, kstar] = smooth(o.value[i, kstar], x̄[i], γ)
    end
end
