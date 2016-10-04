# Online MM algorithm(s) via quadratic upper bound

# Majorizing function:
#   g_t(Θ) = f_t(u) + ∇f_t(u)'(Θ - u) + .5 * (Θ - u)'H_t(Θ - u)
#   where H_t = eigmax(x * x') * I
#   NOTE: This works because H_t - d^2 f_t(u) is nonnegative definite

# Using the stochastic average of majorizing functions g_t(Θ):
#   Q_t(Θ) = aΘ'Θ / 2 - v'Θ + c
# Where:
#   a = (1 - γ) * λ + γ * λmax (largest eigenvalue of current batch's Hessian)
#   v = (1 - γ) * v + γ * (Θ / λmax - ∇f_t(Θ))

# Online update is then:
#   βj = v_j / a


type FastGLM{M <: Model, W <: Weight} <: OnlineStat{XYInput}
    model::M
    β0::Float64
    β::VecF
    v0::Float64
    v::VecF
    λ::Float64
    intercept::Bool
    weight::W
end
function FastGLM(p::Integer, m::Model = LinearRegression(), wt::Weight = LearningRate();
        intercept::Bool = true
    )
    FastGLM(m, 0.0, zeros(p), 0.0, zeros(p), 0.0, intercept, wt)
end
function FastGLM(x::AMat, y::AVec, m::Model = LinearRegression(),
        wt::Weight = LearningRate(); kw...
    )
    o = FastGLM(size(x, 2), m, wt; kw...)
    fit!(o, x, y)
    o
end

getλmax(o::FastGLM, x) = error("FastGLM is only for LinearRegression and LogisticRegression")
getλmax(o::FastGLM{LinearRegression}, x::AVec) = svdfact(x').S[1]
getλmax(o::FastGLM{LogisticRegression}, x::AVec) = .25 * svdfact(x').S[1]
getλmax(o::FastGLM{PoissonRegression}, x::AVec) = predict(o, x) * svdfact(x').S[1]


function _fit!(o::FastGLM, x::AVec, y::Real, γ::Float64)
    η = xβ(o, x)
    g = lossderiv(o.model, y, η)
    λmax = getλmax(o, x) ^ 2
    o.λ = smooth(o.λ, λmax, γ)
    λ = o.λ
    if o.intercept
        o.v0 = smooth(o.v0, λmax * o.β0 - g, γ)
        o.β0 = o.v0 / λ
    end
    for j in eachindex(o.β)
        o.v[j] = smooth(o.v[j], λmax * o.β[j] - g * x[j], γ)
        @inbounds o.β[j] = o.v[j] / λ
    end
end


loss(o::FastGLM, x, y) = loss(o.model, y, xβ(o, x))
