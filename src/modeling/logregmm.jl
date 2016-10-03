type LogRegMM2{W <: Weight} <: OnlineStat{XYInput}
    β0::Float64
    β::VecF
    buffer::VecF
    weight::W
end
function LogRegMM2(p::Integer, wt::Weight = LearningRate())
    LogRegMM2(0.0, zeros(p), zeros(p), wt)
end
function LogRegMM2(x::AMat, y::AVec, wt::Weight = LearningRate())
    o = LogRegMM2(size(x, 2), wt)
    fit!(o, x, y)
    o
end

value(o::LogRegMM2) = coef(o)
coef(o::LogRegMM2) = o.β0, o.β

function _fit!(o::LogRegMM2, x::AVec, y::Real, γ::Float64)
    p = length(o.β)
    if y == 1.0
        yϵ = y - _ϵ
    else
        yϵ = y + _ϵ
    end
    η = o.β0 + dot(o.β, x)
    for j in 1:p
        x_α = sign(x[j] / sumabs(x))
        c = x_α * o.β[j] - η
        βj = -(1 / x_α) * (log(1.0 - yϵ) - c * log(yϵ))
        o.β[j] = smooth(o.β[j], βj, γ)
    end
end




# TODO: optimize

# Q(Θ) = Θ'AΘ + b'Θ + c
# A is stochastic average of .25 * X'X
# b is stochastic average of ∇f(Θ) - .25 * X'X * Θ
type LogRegMM{W <: Weight} <: OnlineStat{XYInput}
	β::VecF
    H::Matrix{Float64}  # Storage
    A::Matrix{Float64}  # X'X
    b::VecF
    Δ::VecF
    weight::W
end
function LogRegMM(p::Integer, wt::Weight = LearningRate())
    LogRegMM(zeros(p), zeros(p, p), zeros(p, p), zeros(p), zeros(p), wt)
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
    rank1_smooth!(o.A, x, γ)
    smooth!(o.b, (y - predict(o, x)) * x + BLAS.symv('U', 1.0, o.A, o.β), γ)
    # smooth!(o.b, - (y - predict(o, x)) * x, γ)
    copy!(o.H, o.A)
    copy!(o.Δ, o.b)
    try
        LAPACK.sysv!('U', o.H, o.Δ)
        for j in eachindex(o.β)
            o.β[j] = o.Δ[j]
        end
    catch
        warn("Singular system")
    end
    # "wrong" version that seems to work better
    # o.β = o.β + γ * inv(o.H) * (y - predict(o, x)) * x
end



value(o::LogRegMM) = coef(o)
coef(o::LogRegMM) = o.β
linpred(o::LogRegMM, x::AVec) = dot(x, o.β)
linpred(o::LogRegMM, x::AMat) = x * o.β
predict(o::LogRegMM, x) = predict(LogisticRegression(), linpred(o, x))
loss(o::LogRegMM, x, y) = loss(LogisticRegression(), y, linpred(o, x))
