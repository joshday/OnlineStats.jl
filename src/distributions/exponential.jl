#-------------------------------------------------------# Type and Constructors
type FitExponential{W <: Weighting} <: DistributionStat
    d::Exponential
    n::Int64
    weighting::W
end

function distributionfit(::Type{Exponential}, y::AVecF, wgt::Weighting = default(Weighting))
    o = FitExponential(wgt)
    update!(o, y)
    o
end

FitExponential(y::AVecF, wgt::Weighting = default(Weighting)) =
    distributionfit(Exponential, y, wgt)

FitExponential(wgt::Weighting = default(Weighting)) =
    FitExponential(Exponential(), 0, wgt)


#---------------------------------------------------------------------# update!
function update!(o::FitExponential, y::Real)
    λ = weight(o)
    if o.n > 0
        θ = smooth(o.d.θ, y, λ)
    else
        θ = smooth(0., y, λ)
    end
    o.d = Exponential(θ)
    o.n += 1
end
