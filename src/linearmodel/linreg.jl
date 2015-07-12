#-------------------------------------------------------# Type and Constructors
type LinReg{W <: Weighting} <: OnlineStat
    xycov::CovarianceMatrix{W}  # Cov([X y])
    s::MatF                     # "Swept" version of [X y]' [X y]
    n::Int
    weighting::W
end

function LinReg(x::MatF, y::VecF, wgt::Weighting = default(Weighting))
    n, p = size(x)
    o = LinReg(p, wgt)
    updatebatch!(o, x, y)
    o
end

function LinReg(p, wgt::Weighting = default(Weighting))
    c = CovarianceMatrix(p + 1, wgt)
    LinReg(c, zeros(p + 1, p + 1), 0, wgt)
end


#-----------------------------------------------------------------------# state
statenames(o::LinReg) = [:β, :nobs]
state(o::LinReg) = Any[coef(o), nobs(o)]

mse(o::LinReg) = o.s[end, end] * o.n / (o.n - size(o.s, 1))

coef(o::LinReg) = vec(o.s[end, 1:end - 1])


#---------------------------------------------------------------------# update!
function updatebatch!(o::LinReg, x::AMatF, y::AVecF)
    n, p = size(x)
    updatebatch!(o.xycov, [x y])
    copy!(o.s, o.xycov.A)
    sweep!(o.s, 1:p)
    o.n += n
end

function update!(o::LinReg, x::AMatF, y::AVecF)
    for i in 1:length(y)
        updatebatch!(o, view(x, i, :), view(y, i))
    end
end


#------------------------------------------------------------------------# Base
function coeftable(o::LinReg)
    β = coef(o)
    p = length(β)
    se = stderr(o)
    ts = β ./ se
    CoefTable([β se ts ccdf(FDist(1, o.n - p), abs2(ts))],
              ["Estimate","Std.Error","t value", "Pr(>|t|)"],
              ["x$i" for i = 1:p], 4)
end

function confint{T <: Real}(o::LinReg, level::T = 0.95)
    β = coef(o)
    mult = stderr(o) * quantile(TDist(o.n - length(β)), (1. - level) / 2.)
    hcat(β, β) + mult * [1. -1.]
end

stderr(o::LinReg) = sqrt(diag(vcov(o)))

vcov(o::LinReg) = -mse(o) * (o.s[1:end-1, 1:end-1] / o.n)

predict(o::LinReg, x::Matrix) = x * coef(o)
