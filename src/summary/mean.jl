export Mean

#----------------------------------------------------------------------------#
#------------------------------------------------------# Type and Constructors
type Mean <: ContinuousUnivariateOnlineStat
    mean::Float64
    n::Int64
end

Mean{T <: Real}(y::Vector{T}) = Mean(mean(y), length(y))

Mean(y::Real) = Mean([y])

Mean() = Mean(0.0, 0)


#----------------------------------------------------------------------------#
#--------------------------------------------------------------------# update!
function update!{T <: Real}(obj::Mean, y::Vector{T})
    n2 = length(y)
    obj.n += n2
    obj.mean += (n2 / obj.n) * (mean(y) - obj.mean)
end

update!(obj::Mean, y::Real) = update!(obj, [y])


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# state
function state(obj::Mean)
    names = [:mean, :n]
    values = [obj.mean, obj.n]
    return([names values])
end


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# Base
Base.copy(obj::Mean) = Mean(obj.mean, obj.n)

function Base.merge(a::Mean, b::Mean)
    m = a.mean + (b.n / (a.n + b.n)) * (b.mean - a.mean)
    n = a.n + b.n
    return Mean(m, n)
end

function Base.merge!(a::Mean, b::Mean)
    a.mean += (b.n / (a.n + b.n)) * (b.mean - a.mean)
    a.n += b.n
end

function Base.show(io::IO, obj::Mean)
    @printf(io, "Online Mean\n")
    @printf(io, " * Mean: %f\n", obj.mean)
    @printf(io, " * N:    %d\n", obj.n)
    return
end
