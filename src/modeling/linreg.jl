"""
Analytical Linear Regression.

With `EqualWeight`, this is equivalent to offline linear regression.
```
using OnlineStats, StatsBase
o = LinReg(x, y, wgt = EqualWeight())
coef(o)
coeftable(o)
vcov(o)
stderr(o)
predict(o, x)
confint(o, .95)
```
"""
type LinReg{W <: Weight} <: OnlineStat{XYInput}
	β0::Float64
	β::VecF
	A::MatF
	S::MatF  # Placeholder for swept version of A
	intercept::Bool
	weight::W
end
function LinReg(p::Integer, wgt::Weight = EqualWeight(); intercept::Bool = true)
	d = p + 2
    o = LinReg(0.0, zeros(p), zeros(d, d), zeros(d, d), intercept, wgt)
	o.A[1, 1] = 1.0
	o
end
function LinReg(x::AMat, y::AVec, wgt::Weight = EqualWeight(); kw...)
    o = LinReg(size(x, 2), wgt; kw...)
    fit!(o, x, y, size(x, 1))
    o
end
# fitting methods don't create the coefficient vector.
# only "sufficient statistics" are updated.  coef(o) calculates the estimate.
# TODO: make singleton version better
function _fit!(o::LinReg, x::AVec, y::Real, γ::Float64)
	_fitbatch!(o, x', [y], γ)
end
function _fitbatch!(o::LinReg, x::AMat, y::AVec, γ::Float64)
	n2, p = size(x)
	rng = 2:p + 1
	# updates look like (1 - γ) * A + γ * x'x / n2
	γ1 = γ / n2
	γ2 = 1.0 - γ
	# update x'x
 	BLAS.syrk!('U', 'T', γ1, x, γ2, view(o.A, rng, rng))
	# update x'y
	BLAS.gemv!('T', γ1, x, y, γ2, view(o.A, rng, p + 2))
	# update 1'x
	smooth!(view(o.A, 1:1, rng), mean(x, 1), γ)
	# update y'y
	o.A[end, end] = smooth(o.A[end, end], sumabs2(y), γ1)
	# update 1'y
	o.A[1, end] = smooth(o.A[1, end], sum(y), γ1)
end
value(o::LinReg) = coef(o)


#---------------------------------------------------------------------------# methods
function coef(o::LinReg)
	swp = (1 + !o.intercept):length(o.β) + 1  # indices to sweep on
    if nobs(o) > 0
        copy!(o.S, o.A)
        sweep!(o.S, swp)
        copy!(o.β, o.S[2:length(o.β) + 1, end])
		o.β0 = o.S[1, end]
    end
	if o.intercept
		return vcat(o.β0, o.β)
	else
		return o.β
	end
end
# mse is only correct when coef(o) is used before
mse(o::LinReg) = o.S[end, end] * nobs(o) / (nobs(o) - length(o.β) - o.intercept)
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
    coef(o)
	rng = (1 + !o.intercept):length(o.β) + 1
    -mse(o) * o.S[rng, rng] / nobs(o)
 end
StatsBase.stderr(o::LinReg) = sqrt(diag(StatsBase.vcov(o)))
predict(o::LinReg, x::AVec) = o.β0 * o.intercept + dot(x, o.β)
function predict(o::LinReg, x::AMat)
	η = x * o.β
	if o.intercept
		β0 = o.β0
		for i in eachindex(η)
			@inbounds η[i] += β0
		end
	end
	return η
end
function loss(o::LinReg, x, y)
    0.5 * mean(abs2(y - predict(o, x)))
end



# TODO: get penalized estimates
# # coef for Ridge
# function coef(o::LinReg, pen::RidgePenalty)
#     copy!(o.S, o.A)
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
