#-------------------------------------------------------# Type and Constructors
type LinReg{W <: Weighting} <: OnlineStat
    xycov::CovarianceMatrix{W}  # Cov([X y])
    s::MatF                     # "Swept" version of cor(C)
    n::Int64
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
    s = cor(c)
    LinReg(c, zeros(p + 1, p + 1), 0, wgt)
end


#-----------------------------------------------------------------------# state
statenames(o::LinReg) = [:β, :nobs]
state(o::LinReg) = Any[coef(o), nobs(o)]

function StatsBase.coef(o::LinReg)
    σ = std(o.xycov)
    μ = mean(o.xycov)
    β = vec(o.s[end, 1:end-1])
    β₀ = μ[end] - σ[end] * (sum(β .* μ[1:end-1] ./ σ[1:end-1]))
    β = [β₀; vec(o.s[end, 1:end-1]) * σ[end] ./ σ[1:end-1] ]
end

mse(o::LinReg) = o.s[end, end] * var(o.xycov)[end]


#---------------------------------------------------------------------# update!
function updatebatch!(o::LinReg, x::MatF, y::VecF)
    n, p = size(x)
    updatebatch!(o.xycov, [x y])
    copy!(o.s, cor(o.xycov))
    sweep!(o.s, 1:p)
    o.n += size(x, 1)
end




#------------------------------------------------------------------------# Base
# function StatsBase.coeftable(o::LinReg)
#     β = coef(o)
#     se = stderr(o)
#     ts = β ./ se
#     CoefTable([β se ts ccdf(FDist(1, o.n - o.p), abs2(ts))],
#               ["Estimate","Std.Error","t value", "Pr(>|t|)"],
#               ["x$i" for i = 1:o.p], 4)
# end

# function StatsBase.confint{T <: Real}(o::LinReg, level::T = 0.95)
#     hcat(coef(o),coef(o)) + stderr(o) *
#     quantile(TDist(o.n - o.p), (1. - level)/2.) * [1. -1.]
# end

# StatsBase.stderr(o::LinReg) = sqrt(diag(vcov(o)))

# StatsBase.vcov(o::LinReg) = -mse(o) * o.S[1:end-1, 1:end-1] / o.n


function StatsBase.predict(o::LinReg, x::Matrix)
    β = coef(o)
    β[1] + x * β[2:end]
end


