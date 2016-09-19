"Online MM Algorithm for Quantile Regression."
type QuantRegMM{W <: Weight} <: OnlineStat{XYInput}
    β::VecF
    τ::Float64
    XWX::MatF
    Xu::VecF
    A::MatF  # memory placeholder
    weight::W
end
function QuantRegMM(p::Integer, τ::Real = 0.5, wgt::Weight = LearningRate())
    QuantRegMM(zeros(p), Float64(τ), zeros(p, p), zeros(p), zeros(p, p), wgt)
end
function QuantRegMM(x::AMat, y::AVec, τ::Real = 0.5, wgt::Weight = LearningRate())
    o = QuantRegMM(size(x, 2), τ, wgt)
    fit!(o, x, y)
    o
end
value(o::QuantRegMM) = coef(o)
coef(o::QuantRegMM) = o.β
function Base.show(io::IO, o::QuantRegMM)
    printheader(io, "QuantRegMM")
    print_item(io, "value", value(o))
    print_item(io, "τ", o.τ)
    print_item(io, "nobs", nobs(o))
end
function _fit!{T<:Real}(o::QuantRegMM, x::AVec{T}, y::Real, γ::Float64)
    w = _ϵ + abs(y - dot(x, o.β))
    u = y / w + 2.0 * o.τ - 1.0
    for j in 1:length(o.β)
        @inbounds o.Xu[j] = smooth(o.Xu[j], x[j] * u, γ)
    end
    γ2 = γ / w
    for j in 1:size(o.XWX, 2), i in 1:j
        @inbounds o.XWX[i, j] = (1.0 - γ) * o.XWX[i, j] + γ2 * x[i] * x[j]
    end
    o.β = copy(o.Xu)
    copy!(o.A, o.XWX)

    try LAPACK.sysv!('U', o.A, o.β)
    catch warn("System is singular.  β not updated.")
    end
end
function _fitbatch!{T<:Real}(o::QuantRegMM, x::AMat{T}, y::AVec, γ::Float64)
    n, p = size(x)

    w = 1 ./ (_ϵ + abs(y - x * o.β))
    u = y .* w + 2.0 * o.τ - 1.0
    wx = scale!(w, copy(x))
    smooth!(o.XWX, x' * wx, γ)
    smooth!(o.Xu, x' * u, γ)

    o.β = copy(o.Xu)
    copy!(o.A, o.XWX)

    try LAPACK.sysv!('U', o.A, o.β)
    catch warn("System is singular.  β not updated.")
    end
    o
end
