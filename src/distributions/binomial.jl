#------------------------------------------------------# Type and Constructors
type FitBinomial{W <: Weighting} <: ScalarStat
    d::Binomial
    p::Float64
    n::Int64  # Number of observations.  Ntrials is stored in :d
    weighting::W
end

function onlinefit{T <: Integer}(::Type{Binomial},
                                 y::Vector{T},
                                 wgt::Weighting = default(Weighting);
                                 n = 1) # n = number of independent Bernoulli trials
    obj = FitBinomial(wgt, n = n)
    update!(obj, y)
    obj
end

FitBinomial{T <: Integer}(y::Vector{T}, wgt::Weighting = default(Weighting); n = 1) =
    onlinefit(Binomial, y, wgt, n = n)

FitBinomial(wgt::Weighting = default(Weighting); n = 1) =
    FitBinomial(Binomial(n, 0), 0., 0, wgt)


#-----------------------------------------------------------------------# state
statenames(obj::FitBinomial) = [:n, :p, :nobs]

state(obj::FitBinomial) = [obj.d.n, obj.d.p, obj.n]


#---------------------------------------------------------------------# update!
function update!(obj::FitBinomial, y::Integer)
    λ = weight(obj)
    obj.p = smooth(obj.p, @compat(Float64(y / obj.d.n)), λ)
    obj.d = Binomial(obj.d.n, obj.p)
    obj.n += 1
    return
end


#-----------------------------------------------------------------------# Base
function Base.copy(obj::FitBinomial)
    FitBinomial(obj.d, obj.p, obj.n, obj.weighting)
end
