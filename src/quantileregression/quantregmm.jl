# Author(s): Josh Day <emailjoshday@gmail.com>

export QuantRegMM

#-----------------------------------------------------------------------------#
#-----------------------------------------------------------# QuantRegMM
type QuantRegMM <: MultivariateOnlineStat
    β::Vector         # Coefficients
    τ::Float64        # Desired conditional quantile
    r::Float64        # learning rate
    ϵ::Float64        # epsilon for approximate quantile loss function
    V::Matrix         # sufficient statistic 1
    U::Vector         # sufficient statistic 2
    intercept::Bool   # intercept in model?

    n::Int64          # Number of observations used
    nb::Int64         # Number of batches used
end

function QuantRegMM(X::Matrix, y::Vector; τ = 0.5, r = 0.51, ϵ = 1e-8,
                          intercept::Bool = true)
    if intercept
        X = [ones(length(y)) X]
    end
    n, p = size(X)
    w = ϵ + abs(y)
    u = y ./ w + 2*τ - 1
    V = X' * (X ./ w)
    U = X' * u
    β = inv(V) * U
    QuantRegMM(β, τ, r, ϵ, V, U, intercept, n, 1)
end

function QuantRegMM(X::Matrix, y::Vector, β::Vector; τ = 0.5, r = 0.51, ϵ = 1e-8,
                          intercept::Bool = true)
    if intercept
        X = [ones(length(y)) X]
    end
    n, p = size(X)
    w = ϵ + abs(y - X * β)
    u = y ./ w + 2*τ - 1
    V = X' * (X ./ w)
    U = X' * u
    β = inv(V) * U
    QuantRegMM(β, τ, r, ϵ, V, U, intercept, n, 1)
end

function QuantRegMM(x::Vector, y::Vector; args...)
    QuantRegMM(reshape(x, length(x), 1), y; args...)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::QuantRegMM, X::Matrix, y::Vector)
    if obj.intercept
        X = [ones(length(y)) X]
    end
    n, p = size(X)
    γ = obj.nb ^ -obj.r

    w = obj.ϵ + abs(y - X * obj.β)
    u = y ./ w + 2 * obj.τ - 1

    obj.V += γ * (X' * (X ./ w) - obj.V)
    obj.U += γ * (X' * u - obj.U)

    obj.β = inv(obj.V) * obj.U

    obj.n += n
    obj.nb += 1
end

function update!(obj::QuantRegMM, x::Vector, y::Vector)
    update!(obj, reshape(x, length(x), 1), y)
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::QuantRegMM)
    DataFrame(variable = [symbol("β$i") for i in [1:length(obj.β)] - obj.intercept],
              value = obj.β,
              r = obj.r,
              n = nobs(obj))
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
StatsBase.coef(obj::QuantRegMM) = return obj.β

function Base.show(io::IO, obj::QuantRegMM)
    println(io, "Online Quantile Regression (MM Algorithm):\n", state(obj))
end
