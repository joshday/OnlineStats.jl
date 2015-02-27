export Var

#----------------------------------------------------------------------------#
#------------------------------------------------------# Type and Constructors
type Var <: ContinuousUnivariateOnlineStat
    mean::Float64        # Mean
    var::Float64         # Biased variance (easier to update)
    n::Int64             # Number of observations used
end

function Var{T <: Real}(y::Vector{T})
    n = length(y)
    if n > 1
        Var(mean(y), var(y) * ((n -1) / n), length(y))
    else
        Var(mean(y), 0.0, 1)
    end
end

Var(y::Real) = Var([y])

Var() = Var(0.0, 0.0, 0)


#----------------------------------------------------------------------------#
#--------------------------------------------------------------------# update!
function update!{T <: Real}(obj::Var, y::Vector{T})
    var2 = Var(y)
    n1 = obj.n
    n2 = var2.n
    n = n1 + n2
    μ1 = obj.mean
    μ2 = var2.mean
    δ = μ2 - μ1
    γ = n2 / n

    obj.mean += γ * δ

    if n2 > 1
        obj.var += γ * (var2.var - obj.var) + γ * (1 - γ) * δ^2
    else
        obj.var = (n1 / n) * obj.var + (y[1] - μ1) * (y[1] - obj.mean) /n
    end
    obj.n = n
end

function update!(obj::Var, y::Real)
    update!(obj, [y])
end


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# state
function state(obj::Var)
    names = [:mean, :var, :n]
    values = [obj.mean, obj.var, obj.n]
    return([names values])
end


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# Base
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

function Base.show(io::IO, obj::Var)
    @printf(io, "Online Variance\n")
    @printf(io, " * Mean:     %f\n", obj.mean)
    @printf(io, " * Variance: %f\n", obj.var)
    @printf(io, " * N:        %d\n", obj.n)
    return
end



x1 = randn(100)
x2 = randn(100)
x = [x1; x2]
obj = OnlineStats.Var(x1)
OnlineStats.update!(obj, x2)
obj.var - var(x) * 199 / 200

for i in 1:1000
    xnew = randn()
    OnlineStats.update!(obj, xnew)
    x = [x; xnew]
end
obj.var - var(x) * ((length(x) - 1) / length(x))
OnlineStats.state(obj)

y = randn(100123)
obj2 = OnlineStats.Var(y)
merge!(obj, obj2)

obj.mean - mean([x; y])
obj.var - var([x; y]) * (length([x;y]) - 1) / length([x;y])

obj3 = merge(obj, obj2)
