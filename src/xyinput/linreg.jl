mutable struct LinReg <: OnlineStat{(1,0), 1}
    β::VecF
    A::MatF
    S::MatF
    nobs::Int
    swept::Bool
    function LinReg(p::Integer)
        d = p + 1
        new(zeros(p), zeros(d, d), zeros(d, d), 0, false)
    end
end
fields_to_show(o::LinReg) = [:β]
nobs(o::LinReg) = o.nobs

function matviews(o::LinReg)
    p = length(o.β)
    @views o.A[1:p, 1:p], o.A[1:p, end]
end

function fit!(o::LinReg, x::AVec, y::Real, γ::Float64)
    xtx, xty = matviews(o)
    smooth_syr!(xtx, x, γ)
    smooth!(xty, x .* y, γ)
    o.A[end] = smooth(o.A[end], y * y, γ)
    o.nobs += 1
    o.swept = false
end

function fitbatch!(o::LinReg, x::AMat, y::AVec, γ::Float64)
    xtx, xty = matviews(o)
    n2, p = size(x)
    γ1 = γ / n2
    γ2 = 1 - γ
    BLAS.syrk!('U', 'T', γ1, x, γ2, xtx)
    BLAS.gemv!('T', γ1, x, y, γ2, xty)
    o.A[end] = smooth(o.A[end], mean(abs2, y), γ)
    o.nobs += n2
    o.swept = false
end

function value(o::LinReg, λ::Float64 = 0.0)
    if !o.swept
        copy!(o.S, o.A)
        p = length(o.β)
        if λ != 0
            for i in 1:p
                o.S[i, i] += λ
            end
        end
        SweepOperator.sweep!(o.S, 1:p)
        copy!(o.β, o.S[1:p, end])
        o.swept = true
    end
    o.β
end
coef(o::LinReg, λ::Float64 = 0.0) = value(o, λ)
predict(o::LinReg, x::AMat) = x * coef(o)


mse(o::LinReg) = (coef(o); o.S[end] * nobs(o) / (nobs(o) - length(o.β)))
function coeftable(o::LinReg)
    β = coef(o)
    p = length(β)
    se = stderr(o)
    ts = β ./ se
    CoefTable(
        [β se ts Ds.ccdf(Ds.FDist(1, nobs(o) - p), abs2.(ts))],
        ["Estimate", "Std.Error", "t value", "Pr(>|t|)"],
        ["x$i" for i in 1:p],
        4
    )
end
function confint(o::LinReg, level::Real = 0.95)
    β = coef(o)
    mult = stderr(o) * quantile(Ds.TDist(nobs(o) - length(β) - 1), (1 - level) / 2)
    hcat(β, β) + mult * [1. -1.]
end
function vcov(o::LinReg)
    coef(o)
    p = length(o.β)
    -mse(o) * o.S[1:p, 1:p] / nobs(o)
 end
stderr(o::LinReg) = sqrt.(diag(vcov(o)))
