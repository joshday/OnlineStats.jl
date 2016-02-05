type KMeans{W<:Weight} <: OnlineStat{VectorInput}
    value::MatF
    v::VecF
    weight::W
    n::Int
    nups::Int
end
function KMeans(d::Integer, k::Integer, wgt::Weight = LearningRate())
    KMeans(randn(d, k), zeros(k), wgt, 0, 0)
end
function KMeans{T<:Real}(x::AMat{T}, k::Integer, wgt::Weight = LearningRate())
    o = KMeans(size(x, 2), k, wgt)
    fit!(o, x)
    o
end
function KMeans{T<:Real}(x::AMat{T}, k::Integer, b::Integer, wgt::Weight = LearningRate())
    o = KMeans(size(x, 2), k, wgt)
    fit!(o, x, b)
    o
end
function Base.show(io::IO, o::KMeans)
    printheader(io, "KMeans")
    print_item(io, "value", value(o))
    print_item(io, "K", length(o.v))
    print_item(io, "nobs", nobs(o))
end

function fit!{T<:Real}(o::KMeans, x::AVec{T})
    γ = weight!(o, 1)
    d, k = size(o.value)
    @assert length(x) == d
    for j in 1:k
        o.v[j] = sumabs2(x - col(o.value, j))
    end
    kstar = indmin(o.v)
    for i in 1:d
        o.value[i, kstar] = smooth(o.value[i, kstar], x[i], γ)
    end
end
function fitbatch!{T<:Real}(o::KMeans, x::AMat{T})
    γ = weight!(o, size(x, 1))
    d, k = size(o.value)
    @assert size(x, 2) == d
    x̄ = vec(mean(x, 1))
    for j in 1:k
        o.v[j] = sumabs2(x̄ - col(o.value, j))
    end
    kstar = indmin(o.v)
    for i in 1:d
        o.value[i, kstar] = smooth(o.value[i, kstar], x̄[i], γ)
    end
end
