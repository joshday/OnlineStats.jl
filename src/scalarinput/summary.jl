#-----------------------------------------------------------------------# Quantiles
"""
    Quantiles(q = [.25, .5, .75])  # default algorithm is :MSPI
    Quantiles{:SGD}(q = [.25, .5, .75])
    Quantiles{:MSPI}(q = [.25, .5, .75])

Approximate quantiles via the specified `algorithm` (`:SGD` or `:MSPI`).
### Example
    s = Series(randn(10_000), Quantiles(.1:.1:.9)
"""
struct Quantiles{T} <: OnlineStat{0, LearningRate}
    value::VecF
    τvec::VecF
    function Quantiles{T}(value, τvec) where {T}
        for τ in τvec
            0 < τ < 1 || throw(ArgumentError("provided quantiles must be in (0, 1)"))
        end
        new(value, τvec)
    end
end
Quantiles{T}(τvec::AVecF = [.25, .5, .75]) where {T} = Quantiles{T}(zeros(τvec), τvec)
Quantiles(τvec::AVecF = [.25, .5, .75]) = Quantiles{:MSPI}(τvec)

function fit!(o::Quantiles{:SGD}, y::Float64, γ::Float64)
    for i in eachindex(o.τvec)
        @inbounds o.value[i] -= γ * deriv(QuantileLoss(o.τvec[i]), y, o.value[i])
    end
end
function fit!(o::Quantiles{:MSPI}, y::Real, γ::Float64)
    for i in eachindex(o.τvec)
        w = abs(y - o.value[i]) + ϵ
        b = o.τvec[i] - .5 * (1 - y / w)
        o.value[i] = (o.value[i] + γ * b) / (1 + γ / 2w)
    end
end
# TODO
# function fit!(o::Quantiles{:OMAP}, y::Real, γ::Float64)
#     for i in eachindex(o.τvec)
#         u = y - o.value[i]
#         l = QuantileLoss(o.τvec[i])
#         c = (value(l, -u) - value(l, u) - 2deriv(l, u) * u) / (2 * u ^ 2)
#         o.value[i] -= γ * deriv(l, u) / c
#     end
# end

function Base.merge!(o::Quantiles, o2::Quantiles, γ::Float64)
    o.τvec == o2.τvec || throw(ArgumentError("objects track different quantiles"))
    smooth!(o.value, o2.value, γ)
end
