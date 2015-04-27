export Var


#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type Var{W<:Weighting} <: ScalarStat
    mean::Mean{W}
    var::Float64    # BIASED variance (makes for easier update)
    n::Int64
    weighting::W
end

const DEFAULT_WEIGHTING = EqualWeighting()

function Var{T <: Real}(y::Vector{T}, wgt::Weighting = DEFAULT_WEIGHTING)
    obj = Var(wgt)
    update!(obj, y)  # apply the weighting scheme, as opposed to initializing with classic variance
    obj
end

# pass to vector constructor
Var(y::Float64, wgt::Weighting = DEFAULT_WEIGHTING) = Var([y], wgt)

Var(wgt::Weighting = DEFAULT_WEIGHTING) = Var(Mean(wgt), 0., 0, wgt)


#-----------------------------------------------------------------------# state
state_names(obj::Var) = [:μ, :σ²]
state(obj::Var) = [mean(obj), var(obj)]


#---------------------------------------------------------------------# update!


# NOTE: does this seem cleaner to you?  I don't think it's (much) slower in the vector case, but the singleton case *should* be faster... but i haven't tested at all
function update!(obj::Var, y::Vector)
    for yi in y
        update!(obj, yi)
    end
end

function update!(obj::Var, y::Float64)
    n = nobs(obj)
    λ = weight(obj)
    μ = mean(obj)

    # obj.mean = smooth(μ, y, λ)
    update!(obj.mean, y)
    obj.var = smooth(obj.var, (y - μ) * (y - mean(obj)), λ)
    obj.n += 1
    return
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state

state(obj::Var) = var(obj)

#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.mean(obj::Var) = obj.mean
Base.var(obj::Var) = (n = nobs(obj); (n < 2 ? 0. : obj.var * n / (n - 1)))

Base.copy(obj::Var) = Var(obj.mean, obj.var, obj.n, obj.weighting)

# NOTE:
function Base.empty!(obj::Var)
    obj.mean = 0.
    obj.var = 0.
    obj.n = 0
    return
end

# function Base.merge(a::Var, b::Var)
# end



