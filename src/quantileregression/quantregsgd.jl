# Author(s): Josh Day <emailjoshday@gmail.com>

export QuantRegSGD


#-----------------------------------------------------------------------------#
#-------------------------------------------------------------# OnlineQuantReg
type QuantRegSGD <: OnlineStat
    β::Vector         # Coefficients
    τ::Float64        # Desired conditional quantile
    r::Float64        # learning rate
    intercept::Bool   # intercept in model?
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
    names = [[symbol("β$i") for i in [1:length(obj.β)] - obj.intercept];
             :n; :nb]
    estimates = [obj.β, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# x1 = randn(1000)
# y1 = x1 + randn(1000)
# obj = OnlineStats.QuantRegSGD(x1, y1, τ=.9)
# df = OnlineStats.make_df(obj)

# display(OnlineStats.state(obj))
# for i in 1:1000
#     x = randn(1000)
#     y = x + randn(1000)
#     OnlineStats.update!(obj, x, y)
# end
# display(OnlineStats.state(obj))

# OnlineStats.make_df!(obj, df)

# OnlineStats.make_df(obj)
