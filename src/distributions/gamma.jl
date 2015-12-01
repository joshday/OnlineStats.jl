#-------------------------------------------------------# Type and Constructors
type FitGamma{W <: Weighting} <: DistributionStat
    d::Dist.Gamma
    m::Mean{W}
    mlog::Mean{W}
    n::Int64
    weighting::W
end

function distributionfit(::Type{Dist.Gamma}, y::AVecF, wgt::Weighting = default(Weighting))
    o = FitGamma(wgt)
    update!(o, y)
    o
end

FitGamma(y::AVecF, wgt::Weighting = default(Weighting)) =
    distributionfit(Dist.Gamma, y, wgt)

FitGamma(wgt::Weighting = default(Weighting)) =
    FitGamma(Dist.Gamma(), Mean(wgt), Mean(wgt), 0, wgt)


#---------------------------------------------------------------------# update!
function update!(obj::FitGamma, y::AVecF)
    update!(obj.m, y)
    update!(obj.mlog, log(y))
    obj.n = StatsBase.nobs(obj.m)
    obj.d = fit_mle(Dist.Gamma, obj)
end


# Adapted from Distributions:
function fit_mle(::Type{Dist.Gamma}, obj::FitGamma;
                 alpha0::Float64=NaN, maxiter::Int=1000, tol::Float64=1.0e-16)

    mx = mean(obj.m)
    logmx = log(mx)
    mlogx = mean(obj.mlog)

    a::Float64 = isnan(alpha0) ? 0.5 / (logmx - mlogx) : alpha0
    converged = false

    t = 0
    while !converged && t < maxiter
        t += 1
        a_old = a
        a = gamma_mle_update(logmx, mlogx, a)
        converged = abs(a - a_old) <= tol
    end

    Dist.Gamma(a, mx / a)
end
function gamma_mle_update(logmx::Float64, mlogx::Float64, a::Float64)
    ia = 1.0 / a
    z = ia + (mlogx - logmx + log(a) - digamma(a)) / (abs2(a) * (ia - trigamma(a)))
    1.0 / z
end


#------------------------------------------------------------------------# Base
Base.copy(obj::FitGamma) = FitGamma(obj.d, obj.m, obj.mlog, obj.n, obj.weighting)
