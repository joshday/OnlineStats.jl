#-------------------------------------------------------# Type and Constructors
type FitBernoulli{W <: Weighting} <: DistributionStat
    d::Bernoulli
    p::Float64  # success probability
    n::Int64
    weighting::W
end

function onlinefit{T <: Integer}(::Type{Bernoulli}, y::Vector{T}, wgt::Weighting = default(Weighting))
    o = FitBernoulli(wgt)
    update!(o, y)
    o
end

FitBernoulli{T <: Integer}(y::Vector{T}, wgt::Weighting = default(Weighting)) =
    onlinefit(Bernoulli, y, wgt)

FitBernoulli(wgt::Weighting = default(Weighting)) =
    FitBernoulli(Bernoulli(0), 0., 0, wgt)


#---------------------------------------------------------------------# update!
function update!(obj::FitBernoulli, y::Integer)
    λ = weight(obj)
    obj.p = smooth(obj.p, @compat(Float64(y)), λ)
    obj.d = Bernoulli(obj.p)
    obj.n += 1
    return
end

