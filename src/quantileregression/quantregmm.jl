#-------------------------------------------------------# Type and Constructors
type QuantRegMM{W <: Weighting} <: OnlineStat
    β::Vector         # Coefficients
    τ::Float64        # Desired conditional quantile
    ϵ::Float64        # epsilon for approximate quantile loss function
    V::Matrix         # sufficient statistic 1
    U::Vector         # sufficient statistic 2

    n::Int64          # Number of observations used
    weighting::W
end

function QuantRegMM(p::Int, wgt::Weighting = StochasticWeighting();
                    τ::Float64 = .5, start = zeros(p))
    @assert τ > 0 && τ < 1
    QuantRegMM(start, τ, 0, wgt)
end


#---------------------------------------------------------------------# update!
function update!(obj::QuantRegMM, X::Matrix, y::Vector)
    n, p = size(X)
    γ = weight(o)

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
