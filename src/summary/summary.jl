export Summary

#----------------------------------------------------------------------------#
#------------------------------------------------------# Type and Constructors
type Summary <: MultivariateOnlineStat
    mean::Mean        # mean
    var::Var          # variance
    extrema::Extrema  # max and min
    n::Int64          # nobs
end


function Summary{T <: Real}(y::Vector{T})
    Summary(Mean(y), Var(y), Extrema(y), length(y))
end

Summary{T <: Real}(y::T) = Summary([y])

Summary() = Summary(Mean(), Var(), Extrema(), 0)

#----------------------------------------------------------------------------#
#--------------------------------------------------------------------# update!
function update!{T <: Real}(obj::Summary, y::Vector{T})
    update!(obj.mean, y)
    update!(obj.var, y)
    update!(obj.extrema, y)
    obj.n += length(y)
end

update!{T <: Real}(obj::Summary, y::T) = update!(obj, [y])



#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# state
function state(obj::Summary)
    DataFrame(variable = [:μ, :σ², :max, :min],
              value = [mean(obj), var(obj), max(obj), min(obj)],
              n = nobs(obj))
end


#----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# Base
Base.mean(obj::Summary) = return mean(obj.mean)

Base.var(obj::Summary) = return var(obj.var)

Base.max(obj::Summary) = return max(obj.extrema)

Base.min(obj::Summary) = return min(obj.extrema)

Base.copy(obj::Summary) = Summary(obj.mean, obj.var, obj.extrema, obj.n)

function Base.merge(a::Summary, b::Summary)
    Summary(merge(a.mean, b.mean),
            merge(a.var, b.var),
            merge(a.extrema, b.extrema),
            a.n + b.n)
end

function Base.merge!(a::Summary, b::Summary)
    merge!(a.mean, b.mean)
    merge!(a.var, b.var)
    merge!(a.extrema, b.extrema)
    a.n += b.n
end

function Base.show(io::IO, obj::Summary)
    @printf(io, "Online Summary\n")
    @printf(io, " * Mean:     %f\n", obj.mean.mean)
    @printf(io, " * Variance: %f\n", obj.var.var * obj.n / (obj.n - 1))
    @printf(io, " * Max:      %f\n", obj.extrema.max)
    @printf(io, " * Min:      %f\n", obj.extrema.min)
    @printf(io, " * N:        %d\n", obj.n)
    return
end

