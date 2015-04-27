export Var



#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
# type Var <: UnivariateOnlineStat
type Var{W<:Weighting} <: OnlineStat  # NOTE: i'm assuming we can remove the parameter from OnlineStat, but it may be required for a reason I don't understand
    # mean::Float64
    mean::Mean{W}
    var::Float64    # BIASED variance (makes for easier update)
    n::Int64
    weighting::W
end

# NOTE: if y was empty, mean(y) == NaN... probably don't want that
# function Var{T <: Real}(y::Vector{T})
#     n = length(y)
#     if n > 1
#         Var(mean(y), var(y) * ((n -1) / n), length(y))
#     else
#         Var(mean(y), 0.0, 1)
#     end
# end

const DEFAULT_WEIGHTING = EqualWeighting()

function Var{T <: Real}(y::Vector{T}, wgt::Weighting = DEFAULT_WEIGHTING)
    obj = Var(wgt)
    update!(obj, y)  # apply the weighting scheme, as opposed to initializing with classic variance
    obj
end

# Var{T <: Real}(y::T) = Var([y])

# NOTE: you don't need the parametric method signature here if you're not using the type T in the method
# NOTE: since you're implicitly converting to a Float64 anyway, you might as well expect that and force the call to convert immediately... it's clearer
# Var(y::Float64, wgt::Weighting = DEFAULT_WEIGHTING) = Var(y, 0., 1, wgt)

# pass to vector constructor
Var(y::Float64, wgt::Weighting = DEFAULT_WEIGHTING) = Var([y], wgt)

Var(wgt::Weighting = DEFAULT_WEIGHTING) = Var(Mean(wgt), 0., 0, wgt)


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
# function update!{T <: Real}(obj::Var, y::Vector{T})
#     var2 = Var(y)
#     n1 = obj.n
#     n2 = var2.n
#     n = n1 + n2
#     μ1 = obj.mean
#     μ2 = var2.mean
#     δ = μ2 - μ1
#     γ = n2 / n

#     obj.mean += γ * δ

#     if n2 > 1
#         obj.var += γ * (var2.var - obj.var) + γ * (1 - γ) * δ^2
#     else
#         obj.var = (n1 / n) * obj.var + (y[1] - μ1) * (y[1] - obj.mean) /n
#     end
#     obj.n = n
# end

# function update!{T <: Real}(obj::Var, y::T)
#     update!(obj, [y])
# end


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



# # NOTE: a test... 
# reload("/home/tom/.julia/v0.4/OnlineStats.jl/src/OnlineStats.jl")
# y = randn(1000000) + collect(1:1000000)/1000000;

# # test equal weighting
# v = OnlineStats.Var()
# means1 = Float64[(OnlineStats.update!(v,x); mean(v)) for x in y]
# empty!(v)
# vars1 = Float64[(OnlineStats.update!(v,x); var(v)) for x in y]

# # test exponential weighting
# v = OnlineStats.Var(OnlineStats.ExponentialWeighting(100))
# means2 = Float64[(OnlineStats.update!(v,x); mean(v)) for x in y]
# empty!(v)
# vars2 = Float64[(OnlineStats.update!(v,x); var(v)) for x in y]




#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
# NOTE: i'm a little confused why you create a dataframe at all here... it's it always 1 row? wouldn't a tuple or something be more appropriate?  i'm not sure i see how state() is used...
# state(obj::Var) = DataFrame(variable = :σ², value = var(obj), n = nobs(obj))

state(obj::Var) = var(obj)

#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.mean(obj::Var) = obj.mean

# NOTE: previous version isn't safe for n < 2
# Base.var(obj::Var) = return obj.var * (obj.n / (obj.n - 1))
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
#     n1 = a.n
#     n2 = b.n
#     n = n1 + n2
#     μ1 = a.mean
#     μ2 = b.mean
#     δ = μ2 - μ1
#     γ = n2 / n

#     m = a.mean + γ * δ
#     if n2 > 1
#         v = a.var + γ * (b.var - a.var) + γ * (1 - γ) * δ^2
#     else
#         v = (n1 / n) * a.var + (y[1] - μ1) * (y[1] - b.mean) /n
#     end
#     Var(m, v, n)
# end

# function Base.merge!(a::Var, b::Var)
#     n1 = a.n
#     n2 = b.n
#     n = n1 + n2
#     μ1 = a.mean
#     μ2 = b.mean
#     δ = μ2 - μ1
#     γ = n2 / n

#     a.mean += γ * δ

#     if n2 > 1
#         a.var += γ * (b.var - a.var) + γ * (1 - γ) * δ^2
#     else
#         a.var = (n1 / n) * a.var + (y[1] - μ1) * (y[1] - b.mean) /n
#     end
#     a.n = n
# end

function Base.show(io::IO, obj::Var)
    @printf(io, "Online Variance\n")
    @printf(io, " * Mean:     %f\n", mean(obj))
    @printf(io, " * Variance: %f\n", var(obj))
    @printf(io, " * N:        %d\n", nobs(obj))
    return
end

