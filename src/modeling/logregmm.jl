# TODO: optimize

# Q(Θ) = Θ'AΘ + b'Θ + c
# A is stochastic average of .25 * X'X
# b is stochastic average of ∇f(Θ) - .25 * X'X * Θ
type LogRegMM{W <: Weight} <: OnlineStat{XYInput}
	β::VecF
    A::MatF
    b::VecF
    weight::W
end
function LogRegMM(p::Integer, wt::Weight = LearningRate())
    LogRegMM(zeros(p), zeros(p, p), zeros(p), wt)
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
    H = x * x' / 4
    smooth!(o.A, H, γ)
    smooth!(o.b, (y - predict(o, x)) * x + H * o.β, γ)
    try
        o.β = o.A \ o.b
    end
end



value(o::LogRegMM) = coef(o)
coef(o::LogRegMM) = o.β


predict(o::LogRegMM, x::AVec) = predict(LogisticRegression(), dot(x, o.β))
predict(o::LogRegMM, x::AMat) = predict(LogisticRegression(), x * o.β)
