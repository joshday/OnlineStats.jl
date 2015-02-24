# Author(s): Josh Day <emailjoshday@gmail.com>

export OnlineQuantRegSGD


#-----------------------------------------------------------------------------#
#-------------------------------------------------------------# OnlineQuantReg
type OnlineQuantRegSGD <: OnlineStat
    β::Vector         # Coefficients
    τ::Float64        # Desired conditional quantile
    r::Float64        # learning rate
    n::Int64          # Number of observations used
    nb::Int64         # Number of batches used
end

function OnlineQuantRegSGD(X::Matrix, y::Vector; τ = 0.5, r = 0.51)
    n, p = size(X)
    X = [ones(n) X]  # add intercept
    β = zeros(p + 1)
    X = ((y .< X*β) - τ) .* X
    β = - vec(mean(X, 1))

    OnlineQuantRegSGD(β, τ, r, n, 1)
end

function OnlineQuantRegSGD(x::Vector, y::Vector)
    OnlineQuantRegSGD(reshape(x, length(x), 1), y)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineQuantRegSGD, X::Matrix, y::Vector)
    n, p = size(X)
    X = [ones(n) X]  # add intercept
    γ = obj.nb ^ -obj.r

    X = ((y .< X*obj.β) - obj.τ) .* X
    obj.β -= vec(mean(X, 1))

    obj.n += n
    obj.nb += 1
end

function update!(obj::OnlineQuantRegSGD, x::Vector, y::Vector)
    update!(obj, reshape(x, length(x), 1), y)
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineQuantRegSGD)
    names = [[symbol("β$i") for i in 0:length(obj.β)-1], :n, :nb]
    estimates = [obj.β, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
x1 = randn(1000)
y1 = x1 + randn(1000)
obj = OnlineStats.OnlineQuantRegSGD(x1, y1)
df = OnlineStats.make_df(obj)

display(OnlineStats.state(obj))
for i in 1:1000
    x = randn(1000)
    y = x + randn(1000)
    OnlineStats.update!(obj, x, y)
end
display(OnlineStats.state(obj))

OnlineStats.make_df!(obj, df)

