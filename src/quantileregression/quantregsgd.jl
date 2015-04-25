# Author(s): Josh Day <emailjoshday@gmail.com>

export QuantRegSGD


#-----------------------------------------------------------------------------#
#-------------------------------------------------------------# OnlineQuantReg
type QuantRegSGD <: MultivariateOnlineStat
    β::Vector         # Coefficients
    τ::Float64        # Desired conditional quantile
    r::Float64        # learning rate
    intercept::Bool   # add intercept to model?
    n::Int64          # Number of observations used
    nb::Int64         # Number of batches used
end

function QuantRegSGD(X::Matrix, y::Vector; τ = 0.5, r = 0.51,
                           intercept::Bool = true)
    if intercept
        X = [ones(length(y)) X]
    end
    n, p = size(X)

    X = ((y .< 0) - τ) .* X
    β = - vec(mean(X, 1))

    QuantRegSGD(β, τ, r, intercept, n, 1)
end

function QuantRegSGD(X::Matrix, y::Vector, β::Vector; τ = 0.5, r = 0.51,
                           intercept::Bool = true)
    if intercept
        X = [ones(length(y)) X]
    end
    n, p = size(X)

    X = ((y .< X * β) - τ) .* X
    β -= vec(mean(X, 1))

    QuantRegSGD(β, τ, r, intercept, n, 1)
end

function QuantRegSGD(x::Vector, y::Vector; args...)
    QuantRegSGD(reshape(x, length(x), 1), y; args...)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::QuantRegSGD, X::Matrix, y::Vector)
    n, p = size(X)
    if obj.intercept
        X = [ones(length(y)) X]
    end
    γ = obj.nb ^ -obj.r

    X = ((y .< X*obj.β) - obj.τ) .* X
    obj.β -= γ * vec(mean(X, 1))

    obj.n += n
    obj.nb += 1
end

function update!(obj::QuantRegSGD, x::Vector, y::Vector)
    update!(obj, reshape(x, length(x), 1), y)
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::QuantRegSGD)
    DataFrame(variable = [symbol("β$i") for i in [1:length(obj.β)] - obj.intercept],
              value = obj.β,
              r = obj.r,
              n = nobs(obj))
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
StatsBase.coef(obj::QuantRegSGD) = return obj.β

function Base.show(io::IO, obj::QuantRegSGD)
    println(io, "Online Quantile Regression (SGD Algorithm):\n", state(obj))
end
