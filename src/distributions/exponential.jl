#-------------------------------------------------------# Type and Constructors
type FitExponential{W <: Weighting} <: ScalarStat
    d::Exponential
    n::Int64
    weighting::W
end

function onlinefit(::Type{Exponential},
                   y::Vector{Float64},
                   wgt::Weighting = DEFAULT_WEIGHTING)
    o = FitExponential(wgt)
    update!(o, y)
    o
end

FitExponential(y::Vector{Float64}, wgt::Weighting = DEFAULT_WEIGHTING) =
    onlinefit(Exponential, y, wgt)

FitExponential(wgt::Weighting = DEFAULT_WEIGHTING) =
    FitExponential(Exponential(), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::FitExponential) = [:β, :nobs]

state(o::FitExponential) = [o.d.β, o.n]


#---------------------------------------------------------------------# update!
function update!(o::FitExponential, y::Float64)
    λ = weight(o)
    if o.n > 0
        β = smooth(o.d.β, y, λ)
    else
        β = smooth(0., y, λ)
    end
    o.d = Exponential(β)
    o.n += 1
end


#------------------------------------------------------------------------# Base
Base.copy(o::FitExponential) = FitExponential(o.d, o.n, o.weighting)
