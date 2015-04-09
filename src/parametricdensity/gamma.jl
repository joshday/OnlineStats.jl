export OnlineFitGamma

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type OnlineFitGamma <: ContinuousUnivariateOnlineStat
    d::Distributions.Gamma
    m::Mean
    mlog::Mean
    n::Int64
    nb::Int64
end

function onlinefit{T<:Real}(::Type{Gamma}, y::Vector{T})
    n::Int64 = length(y)
    OnlineFitGamma(fit(Gamma, y), Mean(y), Mean(log(y)), n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
# Adapted from Distributions package:
    function gamma_mle_update(logmx::Float64, mlogx::Float64, a::Float64)
        ia = 1.0 / a
        z = ia + (mlogx - logmx + log(a) - digamma(a)) / (abs2(a) * (ia - trigamma(a)))
        1.0 / z
    end

    function fit_mle(::Type{Gamma}, obj::OnlineFitGamma;
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


function update!(obj::OnlineFitGamma, newdata::Vector)
    update!(obj.m, newdata)
    update!(obj.mlog, log(newdata))
    obj.n = nobs(obj.m)
    obj.d = fit_mle(Gamma, obj)
    obj.nb += 1
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitGamma)
    names = [:α, :β, :n, :nb]
    estimates = [obj.d.α, obj.d.β, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::OnlineFitGamma) =
    OnlineFitGamma(obj.d, obj.m, obj.mlog, obj.n, obj.nb)

function Base.show(io::IO, obj::OnlineFitGamma)
    @printf(io, "OnlineFit (nobs = %i)\n", obj.n)
    show(obj.d)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
x1 = rand(Gamma(4, 2), 100)
obj = OnlineStats.onlinefit(Gamma, x1)
OnlineStats.state(obj)

for i in 1: 1000
    x2 = rand(Gamma(4, 2), 100)
    OnlineStats.update!(obj, x2)
end
OnlineStats.state(obj)

