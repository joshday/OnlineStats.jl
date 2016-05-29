type LinReg2{W <: Weight} <: OnlineStat{XYInput}
	value::VecF
	A::MatF
	S::MatF  # Placeholder for swept version of A
	intercept::Bool
	weight::W
end
function LinReg2(p::Integer, wgt::Weight = EqualWeight(); intercept::Bool = true)
	d = p + 2
    o = LinReg2(zeros(p + intercept), zeros(d, d), zeros(d, d), intercept, wgt)
	o.A[1, 1] = 1.0
	o
end
function LinReg2(x::AMat, y::AVec, wgt::Weight = EqualWeight(); kw...)
    o = LinReg2(size(x, 2), wgt; kw...)
    fit!(o, x, y, size(x, 1))
    o
end
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
	o.A[end, end] = smooth(o.A[end, end], sumabs(y), γ1)
	# update 1'y
	o.A[1, end] = smooth(o.A[1, end], mean(y), γ1)
end
value(o::LinReg2) = coef(o)

#---------------------------------------------------------------------------# methods
function coef(o::LinReg2)
	rng = 1:length(o.value)
	rng += !o.intercept
    if nobs(o) > 0
        copy!(o.S, o.A)
        sweep!(o.S, rng)
        copy!(o.value, o.S[rng, end])
    end
    o.value
end
mse(o::LinReg2) = (coef(o); o.S[end, end] * nobs(o) / (nobs(o) - length(o.value)))
