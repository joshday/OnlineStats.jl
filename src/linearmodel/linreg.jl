#-------------------------------------------------------# Type and Constructors
"""
`LinReg(x, y)`

Analytical linear regression via the sweep operator.
"""
type LinReg{W <: Weighting} <: OnlineStat
    c::CovarianceMatrix{W}  # Cov([X y])
    s::MatF                 # "Swept" version of [X y]' [X y]
    weighting::W
end

function LinReg(x::AMatF, y::AVecF, wgt::Weighting = default(Weighting))
    p = size(x, 2)
    o = LinReg(p, wgt)
    updatebatch!(o, x, y)
    o
end

function LinReg(p::Integer, wgt::Weighting = default(Weighting))
    c = CovarianceMatrix(p + 1, wgt)
    LinReg(c, zeros(p + 1, p + 1), wgt)
end


#-----------------------------------------------------------------------# state
statenames(o::LinReg) = [:β, :nobs]
state(o::LinReg) = Any[coef(o), nobs(o)]

nobs(o::LinReg) = nobs(o.c)

"Estimate of the error variance"
mse(o::LinReg) = o.s[end, end] * nobs(o) / (nobs(o) - size(o.s, 1))

StatsBase.coef(o::LinReg) = vec(o.s[end, 1:end - 1])


#---------------------------------------------------------------------# update!
function updatebatch!(o::LinReg, x::AMatF, y::AVecF)
    p = ncols(x)
    updatebatch!(o.c, hcat(x, y))
    copy!(o.s, o.c.A)
    sweep!(o.s, 1:p)
    nothing
end

function update!(o::LinReg, x::AVecF, y::Float64)
    update!(o.c, vcat(x, y))
    copy!(o.s, o.c.A)
    sweep!(o.s, 1:nrows(o.s) - 1)
    nothing
end

# special update to avoid sweeping at each row update
function update!(o::LinReg, x::AMatF, y::AVecF)
    update!(o.c, hcat(x, y))
    copy!(o.s, o.c.A)
    sweep!(o.s, 1:nrows(o.s) - 1)
    nothing
end


#------------------------------------------------------------------------# Base
function StatsBase.coeftable(o::LinReg)
    β = coef(o)
    p = length(β)
    se = StatsBase.stderr(o)
    ts = β ./ se
    StatsBase.CoefTable(
        [β se ts Distributions.ccdf(Dist.FDist(1, nobs(o) - p), abs2(ts))],
        ["Estimate","Std.Error","t value", "Pr(>|t|)"],
        ["x$i" for i = 1:p],
        4
    )
end

function StatsBase.confint(o::LinReg, level::Real = 0.95)
    β = coef(o)
    mult = StatsBase.stderr(o) * quantile(Dist.TDist(nobs(o) - length(β)), (1. - level) / 2.)
    hcat(β, β) + mult * [1. -1.]
end

StatsBase.stderr(o::LinReg) = sqrt(diag(StatsBase.vcov(o)))

StatsBase.vcov(o::LinReg) = -mse(o) * (o.s[1:end-1, 1:end-1] / nobs(o))

StatsBase.predict(o::LinReg, x::AVec) = dot(x, coef(o))
StatsBase.predict(o::LinReg, x::AMat) = x * coef(o)
