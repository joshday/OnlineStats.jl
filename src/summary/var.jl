#-------------------------------------------------------# Type and Constructors
type Var <: ScalarStat
    mean::Float64
    var::Float64    # BIASED variance (makes for easier update)
    n::Int64
end

function Var{T <: Real}(y::Vector{T})
    n = length(y)
    if n > 1
        Var(mean(y), var(y) * ((n -1) / n), length(y))
    else
        Var(mean(y), 0.0, 1)
    end
end

Var{T <: Real}(y::T) = Var([y])

Var() = Var(0.0, 0.0, 0)


#-----------------------------------------------------------------------# state
state_names(obj::Var) = [:μ, :σ²]
state(obj::Var) = [mean(obj), var(obj)]


#---------------------------------------------------------------------# update!
function update!{T <: Real}(obj::Var, y::Vector{T})
    var2 = Var(y) # to get unbiased variance
    n1 = obj.n
    n2 = var2.n
    n = n1 + n2
    μ1 = obj.mean
    μ2 = mean(y)
    δ = μ2 - μ1
    γ = n2 / n

    obj.mean += γ * δ

    obj.var += γ * (var2.var - obj.var) + γ * (1 - γ) * δ ^ 2

    obj.n = n
end

function update!{T <: Real}(obj::Var, y::T)
    δ = y - obj.mean
    obj.n += 1
    obj.var = ((obj.n - 1) / obj.n) * obj.var + δ ^ 2 / obj.n
end


#------------------------------------------------------------------------# Base
Base.mean(obj::Var) = return obj.mean

Base.var(obj::Var) = return obj.var * (obj.n / (obj.n - 1))

Base.copy(obj::Var) = Var(obj.mean, obj.var, obj.n)

function Base.merge(a::Var, b::Var)
    n1 = a.n
    n2 = b.n
    n = n1 + n2
    μ1 = a.mean
    μ2 = b.mean
    δ = μ2 - μ1
    γ = n2 / n

    m = a.mean + γ * δ
    if n2 > 1
        v = a.var + γ * (b.var - a.var) + γ * (1 - γ) * δ^2
    else
        v = (n1 / n) * a.var + (y[1] - μ1) * (y[1] - b.mean) /n
    end
    Var(m, v, n)
end

function Base.merge!(a::Var, b::Var)
    n1 = a.n
    n2 = b.n
    n = n1 + n2
    μ1 = a.mean
    μ2 = b.mean
    δ = μ2 - μ1
    γ = n2 / n

    a.mean += γ * δ

    if n2 > 1
        a.var += γ * (b.var - a.var) + γ * (1 - γ) * δ^2
    else
        a.var = (n1 / n) * a.var + (y[1] - μ1) * (y[1] - b.mean) /n
    end
    a.n = n
end
