#-------------------------------------------------------# Type and Constructors
type FitGamma{W <: Weighting} <: ScalarStat
    d::Gamma
    m::Mean{W}
    mlog::Mean{W}
    n::Int64
    weighting::W
end

function onlinefit(::Type{Gamma},
                   y::Vector{Float64},
                   wgt::Weighting = DEFAULT_WEIGHTING)
    o = FitGamma(wgt)
    update!(o, y)
    o
end

FitGamma(y::Vector{Float64}, wgt::Weighting = DEFAULT_WEIGHTING) =
    onlinefit(Gamma, y, wgt)

FitGamma(wgt::Weighting = DEFAULT_WEIGHTING) =
    FitGamma(Gamma(), Mean(wgt), Mean(wgt), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::FitGamma) = [:α, :β, :nobs]

state(o::FitGamma) = [o.d.α, o.d.β, o.n]


#---------------------------------------------------------------------# update!
function update!(obj::FitGamma, y::Vector{Float64})
    update!(obj.m, y)
    update!(obj.mlog, log(y))
    obj.n = nobs(obj.m)
    obj.d = fit_mle(Gamma, obj)
end


# Adapted from Distributions:
function fit_mle(::Type{Gamma}, obj::FitGamma;
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

    Gamma(a, mx / a)
end
function gamma_mle_update(logmx::Float64, mlogx::Float64, a::Float64)
    ia = 1.0 / a
    z = ia + (mlogx - logmx + log(a) - digamma(a)) / (abs2(a) * (ia - trigamma(a)))
    1.0 / z
end


#------------------------------------------------------------------------# Base
Base.copy(obj::FitGamma) = FitGamma(obj.d, obj.m, obj.mlog, obj.n, obj.weighting)
