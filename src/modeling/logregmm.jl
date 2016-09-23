# TODO: optimize

# Q(Θ) = Θ'AΘ + b'Θ + c
# A is stochastic average of .25 * X'X
# b is stochastic average of ∇f(Θ) - .25 * X'X * Θ
type LogRegMM{W <: Weight} <: OnlineStat{XYInput}
	β::VecF
    H::Matrix{Float64}  # Storage
    A::Matrix{Float64}
    b::VecF
    η::Float64
    weight::W
end
function LogRegMM(p::Integer, wt::Weight = LearningRate(); η::Float64 = 1.0)
    @assert 0.0 < η <= 1.0
    LogRegMM(zeros(p), zeros(p, p), zeros(p, p), zeros(p), η, wt)
end
function LogRegMM(x::AMat, y::AVec, wt::Weight = LearningRate())
    o = LogRegMM(size(x, 2), wt)
    fit!(o, x, y)
    o
end
function Base.show(io::IO, o::LogRegMM)
    printheader(io, name(o))
    print_item(io, "β", coef(o))
    print_item(io, "nobs", nobs(o))
end

function _fit!(o::LogRegMM, x::AVec, y::Real, γ::Float64)
    γ *= o.η
    BLAS.syrk!('U', 'N', γ, x / 2., 1.0 - γ, o.H)
    H = Symmetric(o.H)
    smooth!(o.A, H, γ)
    smooth!(o.b, (y - predict(o, x)) * x + H * o.β, γ)
    # try
    #     o.β = o.A \ o.b
    # end
    o.β = o.β + γ * inv(o.H) * (y - predict(o, x)) * x
end



value(o::LogRegMM) = coef(o)
coef(o::LogRegMM) = o.β
linpred(o::LogRegMM, x::AVec) = dot(x, o.β)
linpred(o::LogRegMM, x::AMat) = x * o.β
predict(o::LogRegMM, x) = predict(LogisticRegression(), linpred(o, x))
loss(o::LogRegMM, x, y) = loss(LogisticRegression(), y, linpred(o, x))
