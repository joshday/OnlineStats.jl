#-------------------------------------------------------# Type and Constructors
type FitBernoulli{W <: Weighting} <: ScalarStat
    d::Bernoulli
    p::Float64  # success probability
    n::Int64
    weighting::W
end

function onlinefit{T <: Integer}(::Type{Bernoulli},
                                 y::Vector{T},
                                 wgt::Weighting = DEFAULT_WEIGHTING)
    obj = FitBernoulli(wgt)
    update!(obj, y)
    obj
end

FitBernoulli{T <: Integer}(y::Vector{T}, wgt::Weighting = DEFAULT_WEIGHTING) =
    onlinefit(Bernoulli, y, wgt)

FitBernoulli(wgt::Weighting = DEFAULT_WEIGHTING) =
    FitBernoulli(Bernoulli(0), 0., 0, wgt)


#-----------------------------------------------------------------------# state
statenames(obj::FitBernoulli) = [:p, :nobs]

state(obj::FitBernoulli) = [obj.d.p, obj.n]


#---------------------------------------------------------------------# update!
function update!{T <: Integer}(obj::FitBernoulli, y::Vector{T})
    for yi in y
        update!(obj, yi)
    end
end

function update!(obj::FitBernoulli, y::Integer)
    λ = weight(obj)
    obj.p = smooth(obj.p, float64(y), λ)
    obj.d = Bernoulli(obj.p)
    obj.n += 1
    return
end


#------------------------------------------------------------------------# Base
function Base.copy(obj::FitBernoulli)
    FitBernoulli(obj.d, obj.n1, obj.n)
end
