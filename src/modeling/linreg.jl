"""
Linear regression with optional regularization.

```julia
using  StatsBase
n, p = 100_000, 10
x = randn(n, p)
y = x * collect(1.:p) + randn(n)

o = LinReg(x, y)
coef(o)
predict(o, x)
confint(o, .95)
vcov(o)
stderr(o)
coeftable(o)
using Plots; coefplot(o)

# regularized estimates
coef(o, L2Penalty(.1))  # Ridge
coef(o, L1Penalty(.1))  # LASSO
coef(o, ElasticNetPenalty(.1, .5))
coef(o, SCADPenalty(.1, 3.7))
```
"""
type LinReg{W <: Weight} <: OnlineStat{XYInput}
    value::VecF
    c::CovMatrix{W}  # Cov([X y])
    s::MatF          # "Swept" version of [X y]' [X y]
end
nobs(o::LinReg) = nobs(o.c)
function LinReg(p::Integer, wgt::Weight = EqualWeight())
    o = LinReg(zeros(p), CovMatrix(p + 1, wgt), zeros(p + 1, p + 1))
end
function LinReg(x::AMat, y::AVec, wgt::Weight = EqualWeight())
    o = LinReg(size(x, 2), wgt)
    fit!(o, x, y, size(x, 1))
    o
end
function fit!(o::LinReg, x::AVec, y::Real)
    fit!(o.c, vcat(x, y))
    o
end
function fitbatch!(o::LinReg, x::AMat, y::AVec)
    fitbatch!(o.c, hcat(x, y))
    o
end
function value(o::LinReg)
    copy!(o.s, o.c.A)
    sweep!(o.s, 1:length(o.value))
    copy!(o.value, o.s[1:end-1, end])
    o.value
end
mse(o::LinReg) = o.s[end, end] * nobs(o) / (nobs(o) - size(o.s, 1))
# invlink(o::LinReg, η::Real) = η
function StatsBase.coeftable(o::LinReg)
    β = coef(o)
    p = length(β)
    se = StatsBase.stderr(o)
    ts = β ./ se
    StatsBase.CoefTable(
        [β se ts Ds.ccdf(Ds.FDist(1, nobs(o) - p), abs2(ts))],
        ["Estimate","Std.Error","t value", "Pr(>|t|)"],
        ["x$i" for i = 1:p],
        4
    )
end
function StatsBase.confint(o::LinReg, level::Real = 0.95)
    β = coef(o)
    mult = StatsBase.stderr(o) * quantile(Ds.TDist(nobs(o) - length(β) - 1), (1. - level) / 2.)
    hcat(β, β) + mult * [1. -1.]
end
function StatsBase.vcov(o::LinReg)
    value(o)
    -mse(o) * o.s[1:end-1, 1:end-1] / nobs(o)
 end
StatsBase.stderr(o::LinReg) = sqrt(diag(StatsBase.vcov(o)))
loss(o::LinReg, x::AMatF, y::AVecF) = mean(abs2(y - predict(o, x)))
function StatsBase.coef(o::LinReg, penalty::Penalty = NoPenalty();
        maxiters::Integer = 50,
        tolerance::Real = 1e-4,
        step::Real = 1.0,
        verbose::Bool = false
    )
    s = Float64(step)
    p = length(o.value)
    copy!(o.s, cor(o.c))
    β = zeros(p)
    βold = zeros(p)
    tol = 0.0
    iters = 0

    xtx = o.s[1:p, 1:p]  # x'x
    xty = o.s[1:p, end]  # x'y

    for i in 1:maxiters
        iters += 1
        copy!(βold, β)
        β = β + ((i - 2) / (i + 1)) * (β - βold)
        g = (xty - xtx * β)
        β = β + s * g
        prox!(penalty, β, s)
        tol = βtol(β, βold, xtx, xty, penalty)
        tol < tolerance && break
    end

    tol < tolerance || warn("Algorithm did not achieve convergence")
    verbose && println("tolerance:                ", tol)
    verbose && println("iterations:               ", iters)
    verbose && println("penalized log-likelihood: ", _penloglik(β, xtx, xty, λ, penalty))
    scaled_to_original!(β, o)
end

function scaled_to_original!(β::VecF, o::LinReg)
    μ = mean(o.c)
    σ = std(o.c)
    β₀ = μ[end] - σ[end] * sum(μ[1:end-1] ./ σ[1:end-1] .* β)
    for i in 1:length(β)
        β[i] = β[i] * σ[end] / σ[i]
    end
    [β₀; β]
end
function _penloglik(β::VecF, xtx::MatF, xty::VecF, penalty::Penalty)
    # propto penalized likelihood
    dot(β, xtx * β) - 2.0 * dot(β, xty) + _j(penalty, β)
end
function βtol(β::VecF, βold::VecF, xtx::MatF, xty::VecF, penalty::Penalty)
    # convergence criteria
    v = _penloglik(β, xtx, xty, penalty)
    u = _penloglik(βold, xtx, xty, penalty)
    abs(u - v) / (abs(v) + 1.0)
end

StatsBase.coef(o::LinReg) = value(o)
StatsBase.predict{T<:Real}(o::LinReg, x::AVec{T}) = dot(x, coef(o))
StatsBase.predict{T<:Real}(o::LinReg, x::AMat{T}) = x * value(o)
