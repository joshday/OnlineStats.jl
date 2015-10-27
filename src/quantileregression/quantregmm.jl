#-------------------------------------------------------# Type and Constructors
"""
Quantile regression using an online MM algorithm.
"""
type QuantRegMM{W <: Weighting} <: OnlineStat
    β::VecF
    τ::Float64        # Desired conditional quantile
    ϵ::Float64        # epsilon for approximate quantile loss function
    XtWX::MatF         # "sufficient statistic" 1
    Xu::VecF          # "sufficient statistic" 2
    n::Int64
    weighting::W
end

function QuantRegMM(p::Integer, wgt::Weighting = LearningRate(r = .51);
                    τ::Float64 = .5, start::VecF = zeros(p), ϵ::Float64 = 1e-8)
    @assert τ > 0 && τ < 1
    QuantRegMM(start, τ, ϵ, zeros(p, p), zeros(p), 0, wgt)
end

function QuantRegMM(x::AMatF, y::AVecF, wgt::Weighting = LearningRate(r = .51);
                    τ::Float64 = .5, start::VecF = zeros(ncols(x)), ϵ::Float64 = 1e-8,
                    batch = true)
    o = QuantRegMM(ncols(x), wgt, τ = τ, start = start, ϵ = ϵ)
    batch ? updatebatch!(o, x, y) : update!(o, x, y)
    o
end

#-----------------------------------------------------------------------# state
statenames(o::QuantRegMM) = [:β, :τ, :nobs]
state(o::QuantRegMM) = Any[coef(o), o.τ, nobs(o)]

coef(o::QuantRegMM) = copy(o.β)

#---------------------------------------------------------------------# update!
function update!(o::QuantRegMM, x::AVecF, y::Float64)
    γ = weight(o)

    w = o.ϵ + abs(y - x' * o.β)[1]
    u = y / w + 2.0 * o.τ - 1.0

    smooth!(o.XtWX, x * (x / w)', γ)
    smooth!(o.Xu, x .* u, γ)
    o.β = o.XtWX \  o.Xu
    o.n += 1
end

function updatebatch!(o::QuantRegMM, x::AMatF, y::AVecF)
    n = size(x, 1)
    γ = weight(o)

    w = 1 ./ (o.ϵ + abs(y - x * o.β))
    u = y .* w + 2 * o.τ - 1

    wx = scale!(w, copy(x))

    smooth!(o.XtWX, x' * wx, γ)
    smooth!(o.Xu, x' * u, γ)

    o.β = o.XtWX \ o.Xu
    o.n += n
end
