export Extrema

#----------------------------------------------------------------------------#
#------------------------------------------------------# Type and Constructors
type Extrema <: ContinuousUnivariateOnlineStat
    max::Float64
    min::Float64
    n::Int64
end

Extrema{T <: Real}(y::Vector{T}) = Extrema(maximum(y), minimum(y), length(y))

Extrema{T <: Real}(y::T) = Extrema([y])

Extrema() = Extrema(-Inf, Inf, 0)


#----------------------------------------------------------------------------#
#--------------------------------------------------------------------# update!
function update!{T <: Real}(obj::Extrema, y::Vector{T})
    obj.max = maximum([obj.max; y])
    obj.min = minimum([obj.min; y])
    obj.n += length(y)
end

update!{T <: Real}(obj::Extrema, y::T) = update!(obj, [y])


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# state
function state(obj::Extrema)
    names = [:max, :min, :n]
    values = [obj.max, obj.min, obj.n]
    return([names values])
end


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# Base
Base.max(obj::Extrema) = return obj.max

Base.min(obj::Extrema) = return obj.min

Base.maximum(obj::Extrema) = return obj.max

Base.minimum(obj::Extrema) = return obj.min

Base.copy(obj::Extrema) = Extrema(obj.max, obj.min, obj.n)

function Base.merge(a::Extrema, b::Extrema)
    Extrema(maximum([a.max, b.max]), minimum([a.min, b.min]), a.n + b.n)
end

function Base.merge!(a::Extrema, b::Extrema)
    a.max = max(a.max, b.max)
    a.min = min(a.min, b.min)
    a.n += b.n
end

function Base.show(io::IO, obj::Extrema)
    @printf(io, "Online Extrema\n")
    @printf(io, " * Max: %f\n", obj.max)
    @printf(io, " * Min: %f\n", obj.min)
    @printf(io, " * N:   %d\n", obj.n)
    return
end

