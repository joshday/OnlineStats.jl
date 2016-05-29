type LinReg2{W <: Weight} <: OnlineStat{XYInput}
	β0::Float64
	β::VecF
	A::MatF
	S::MatF  # Placeholder for swept version of A
	intercept::Bool
	weight::W
end
function LinReg2(p::Integer, wgt::Weight = EqualWeight(); intercept::Bool = true)
	d = p + 2
    o = LinReg2(0.0, zeros(p), zeros(d, d), zeros(d, d), intercept, wgt)
	o.A[1, 1] = 1.0
	o
end
function LinReg2(x::AMat, y::AVec, wgt::Weight = EqualWeight(); kw...)
    o = LinReg2(size(x, 2), wgt; kw...)
    fit!(o, x, y, size(x, 1))
    o
end
# fitting methods don't create the coefficient vector.
# only "sufficient statistics" are updated.  coef(o) calculates the estimate.
function _fit!(o::LinReg2, x::AVec, y::Real, γ::Float64)
	_fitbatch!(o, x', [y], γ)
end
function _fitbatch!(o::LinReg2, x::AMat, y::AVec, γ::Float64)
	n2, p = size(x)
	rng = 2:p + 1
	# updates look like (1 - γ) * A + γ * x'x / n2
	γ1 = γ / n2
	γ2 = 1.0 - γ
	# update x'x
 	BLAS.syrk!('U', 'T', γ1, x, γ2, sub(o.A, rng, rng))
	# update x'y
	BLAS.gemv!('T', γ1, x, y, γ2, slice(o.A, rng, p + 2))
	# update 1'x
	smooth!(sub(o.A, 1, rng), mean(x, 1), γ)
	# update y'y
	o.A[end, end] = smooth(o.A[end, end], sumabs2(y), γ1)
	# update 1'y
	o.A[1, end] = smooth(o.A[1, end], sum(y), γ1)
end
value(o::LinReg2) = coef(o)


#---------------------------------------------------------------------------# methods
function coef(o::LinReg2)
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
mse(o::LinReg2) = o.S[end, end] * nobs(o) / (nobs(o) - length(o.β) - o.intercept)
function StatsBase.coeftable(o::LinReg2)
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
function StatsBase.confint(o::LinReg2, level::Real = 0.95)
    β = coef(o)
    mult = StatsBase.stderr(o) * quantile(Ds.TDist(nobs(o) - length(β) - 1), (1. - level) / 2.)
    hcat(β, β) + mult * [1. -1.]
end
function StatsBase.vcov(o::LinReg2)
    coef(o)
	rng = (1 + !o.intercept):length(o.β) + 1
    -mse(o) * o.S[rng, rng] / nobs(o)
 end
StatsBase.stderr(o::LinReg2) = sqrt(diag(StatsBase.vcov(o)))


# function predict(o::LinReg2, x::AVec)
# 	β = coef(o)
# 	if o.intercept
# 		return β[1] + dot(x, β[2:end])
# 	else
# 		return dot(x, β)
# 	end
# 	dot(x, coef(o))
# end
#
# function predict(o::LinReg2, x::AMat)
# 	β = coef(o)
# 	storage = zeros(size(x, 1))
# 	if intercept
# 		storage[:] = x * coef(o)[2:end]
# 		β0 = β[1]
# 		for i in eachindex(storage)
# 			storage[i] += β0
# 		end
# 		return storage
# 	else
# 		return x * coef(o)
# 	end
# end
#
# # loss
# function loss(o::LinReg2, x, y)
#     0.5 * mean(abs2(y - predict(o, x)))
# end
