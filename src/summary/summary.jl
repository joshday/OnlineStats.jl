#------------------------------------------------------# Type and Constructors
type Summary <: ScalarStat
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


#-------------------------------------------------------------# param and value
param(obj::Summary) = [:μ, :σ², :max, :min]

value(obj::Summary) = [mean(obj), var(obj), max(obj), min(obj)]


#--------------------------------------------------------------------# update!
function update!{T <: Real}(obj::Summary, y::Vector{T})
    update!(obj.mean, y)
    update!(obj.var, y)
    update!(obj.extrema, y)
    obj.n += length(y)
end

update!{T <: Real}(obj::Summary, y::T) = update!(obj, [y])



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
