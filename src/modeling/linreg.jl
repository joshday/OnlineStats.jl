 """
Linear regression with optional regularization.

```julia
LinReg(x::Matrix, y::Vector)
```

Examples:
```julia
using  StatsBase
n, p = 100_000, 10
x = randn(n, p)
y = x * collect(1.:p) + randn(n)
```

Methods for `LinReg`:
```julia
o = LinReg(x, y)
coef(o)
predict(o, x)
confint(o, .95)
vcov(o)
stderr(o)
coeftable(o)
using Plots; coefplot(o)
```
"""
type LinReg{W<:Weight} <: OnlineStat{XYInput}
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

updatecounter!(o::LinReg, n2::Int) = updatecounter!(o.c, n2)
weight(o::LinReg, n2::Int) = weight(o.c, n2)
_fit!(o::LinReg, x::AVec, y::Real, γ::Float64) = _fit!(o.c, vcat(x, y), γ)
_fitbatch!(o::LinReg, x::AMat, y::AVec, γ::Float64) = _fitbatch!(o.c, hcat(x, y), γ)
value(o::LinReg) = coef(o)


function coef(o::LinReg)
    if nobs(o) > 0
        copy!(o.s, o.c.A)
        sweep!(o.s, 1:length(o.value))
        copy!(o.value, o.s[1:end-1, end])
    end
    o.value
end
mse(o::LinReg) = o.s[end, end] * nobs(o) / (nobs(o) - size(o.s, 1))
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

# predict for vector
predict(o::LinReg, x::AVec) = dot(x, coef(o))
predict(o::LinReg, x::AMat) = x * coef(o)

# loss
function loss(o::LinReg, x::AVecF, y::Float64)
    loss(L2Regression(), y, predict(o, x))
end
function loss(o::LinReg, x::AMatF, y::AVecF)
    loss(L2Regression(), y, predict(o, x))
end

# # coef for Ridge
# function coef(o::LinReg, pen::RidgePenalty)
#     copy!(o.s, o.c.A)
#     for j in 1:length(o.value)
#         o.s[j] += pen.λ
#     end
#     sweep!(o.s, 1:length(o.value))
#     copy!(o.value, o.s[1:end-1, end])
#     o.value
# end

# # coef for Lasso, ElasticNet, SCAD
# function coef(o::LinReg, penalty::Penalty;
#         maxit::Integer = 200,
#         tol::Real = 1e-6,
#         step::Real = 1.0,
#         verbose::Bool = false
#     )
#     s = Float64(step)
#     p = length(o.value)
#     copy!(o.s, cor(o.c))
#     β = zeros(p)
#     βold = zeros(p)
#     old_tolerance = Inf
#     tolerance = 0.0
#     iters = 0
#
#     xtx = o.s[1:p, 1:p]  # x'x / n
#     xty = o.s[1:p, end]  # x'y / n
#
#     for i in 1:maxit
#         iters += 1
#         copy!(βold, β)
#         β = β + ((i - 2) / (i + 1)) * (β - βold)
#         g = (xty - xtx * β)
#         β = β + s * g
#         prox!(penalty, β, s)
#         tolerance = βtol(β, βold, xtx, xty, penalty)
#         tolerance < tol && break
#     end
#
#     tolerance < tol || warn("Algorithm did not achieve convergence (tolerance = $tolerance)")
#     verbose && println("tolerance:                ", tolerance)
#     verbose && println("iterations:               ", iters)
#     verbose && println("penalized log-likelihood: ", _penloglik(β, xtx, xty, penalty))
#     scaled_to_original!(β, o)
# end
# function scaled_to_original!(β::VecF, o::LinReg)
#     μ = mean(o.c)   # mean(y) is μ[end]
#     σ = std(o.c)    # std(y) is σ[end]
#     σy = σ[end]
#     β₀ = μ[end] - σy * sum(μ[1:end-1] ./ σ[1:end-1] .* β)
#     for j in eachindex(β)
#         β[j] = β[j] * σy / σ[j]
#     end
#     [β₀; β]
# end
# function _penloglik(β::VecF, xtx::MatF, xty::VecF, penalty::Penalty)
#     # propto penalized likelihood
#     .5 * dot(β, xtx * β) - dot(β, xty) + _j(penalty, β)
# end
# function βtol(β::VecF, βold::VecF, xtx::MatF, xty::VecF, penalty::Penalty)
#     # convergence criteria
#     v = _penloglik(β, xtx, xty, penalty)
#     u = _penloglik(βold, xtx, xty, penalty)
#     abs(u - v) / abs(v)
# end
