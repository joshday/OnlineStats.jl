#------------------------------------------------------# Type and Constructors
"""
Univariate summary statistics:  Mean, variance, maximum, and minimum.
"""
type Summary{W <: Weighting} <: OnlineStat
    var::Variance{W}  # mean and variance
    extrema::Extrema  # max and min
    n::Int64          # nobs
    weighting::W
end


function Summary{T<:Real}(y::AVec{T}, wgt::Weighting = default(Weighting))
    o = Summary(wgt)
    update!(o, y)
    o
end

Summary(y::Float64, wgt::Weighting = default(Weighting)) = Summary([y], wgt)
Summary(wgt::Weighting = default(Weighting)) = Summary(Variance(wgt), Extrema(), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::Summary) = [:μ, :σ², :max, :min, :nobs]
state(o::Summary) = Any[mean(o), var(o), maximum(o), minimum(o), nobs(o)]

Base.mean(o::Summary) = mean(o.var)
Base.var(o::Summary) = var(o.var)
Base.std(o::Summary) = std(o.var)
Base.maximum(o::Summary) = maximum(o.extrema)
Base.minimum(o::Summary) = minimum(o.extrema)


#--------------------------------------------------------------------# update!
function update!(o::Summary, y::Float64)
    update!(o.var, y)
    update!(o.extrema, y)
    o.n += 1
end


#-----------------------------------------------------------------------# Base
function Base.merge!(a::Summary, b::Summary)
    merge!(a.var, b.var)
    merge!(a.extrema, b.extrema)
    a.n += b.n
end
