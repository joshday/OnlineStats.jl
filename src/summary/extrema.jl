#------------------------------------------------------# Type and Constructors
type Extrema <: OnlineStat
    max::Float64
    min::Float64
    n::Int64
end

Extrema{T <: Real}(y::Vector{T}) = Extrema(maximum(y), minimum(y), length(y))

Extrema{T <: Real}(y::T) = Extrema([y])

Extrema() = Extrema(-Inf, Inf, 0)


#-----------------------------------------------------------------------# state
statenames(o::Extrema) = [:max, :min, :nobs]
state(o::Extrema) = Any[maximum(o), minimum(o), nobs(o)]

maximum(o::Extrema) = o.max
minimum(o::Extrema) = o.min


#--------------------------------------------------------------------# update!
function update!(o::Extrema, y::Float64)
    o.max = max(o.max, y)
    o.min = min(o.min, y)
    o.n += 1
end

function updatebatch!(o::Extrema, y::VecF)
    o.max = max(o.max, maximum(y))
    o.min = min(o.min, minimum(y))
    o.n += length(y)
end

#----------------------------------------------------------------------# Base
function Base.merge!(a::Extrema, b::Extrema)
    a.max = max(a.max, b.max)
    a.min = min(a.min, b.min)
    a.n += b.n
end
