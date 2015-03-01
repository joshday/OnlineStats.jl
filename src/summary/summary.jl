export Summary

#----------------------------------------------------------------------------#
#------------------------------------------------------# Type and Constructors
type Summary <: ContinuousUnivariateOnlineStat
    mean::Mean        # mean
    var::Var          # variance
    extrema::Extrema  # max and min
    n::Int64          # nobs
end


function Summary(y::Vector)
    Summary(Mean(y), Var(y), Extrema(y), length(y))
end

Summary(y::Real) = Summary([y])

Summary() = Summary(Mean(), Var(), Extrema(), 0)

#----------------------------------------------------------------------------#
#--------------------------------------------------------------------# update!
function update!(obj::Summary, y::Vector)
    update!(obj.mean, y)
    update!(obj.var, y)
    update!(obj.extrema, y)
    obj.n += obj.mean.n
end

function update!(obj::Summary, y::Real)
    update!(obj.mean, [y])
    update!(obj.var, [y])
    update!(obj.extrema, [y])
    obj.n += 1
end


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# state
function state(obj::Summary)
    names = [:mean, :var, :max, :min, :n]
    estimates = [obj.mean.mean, obj.var.var * (obj.n - 1) / obj.n,
                 obj.extrema.max, obj.extrema.min,
                 obj.n]
    return([names estimates])
end


#----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# Base
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

