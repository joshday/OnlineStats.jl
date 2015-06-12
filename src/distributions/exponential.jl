#-------------------------------------------------------# Type and Constructors
type FitExponential{W <: Weighting} <: DistributionStat
    d::Exponential
    n::Int64
    weighting::W
end

function onlinefit(::Type{Exponential}, y::VecF, wgt::Weighting = default(Weighting))
    o = FitExponential(wgt)
    update!(o, y)
    o
end

FitExponential(y::Vector{Float64}, wgt::Weighting = default(Weighting)) =
    onlinefit(Exponential, y, wgt)

FitExponential(wgt::Weighting = default(Weighting)) =
    FitExponential(Exponential(), 0, wgt)


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
