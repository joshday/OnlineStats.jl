#-------------------------------------------------------# Type and Constructors
type QuantRegSGD{W <: Weighting} <: OnlineStat
    β::VecF           # Coefficients
    τ::Float64        # Desired conditional quantile
    n::Int            # Number of observations used
    weighting::W
end

function QuantRegSGD(p::Integer, wgt::Weighting = StochasticWeighting();
                     τ::Float64 = .5, start = zeros(p))
    @assert τ > 0 && τ < 1
    QuantRegSGD(start, τ, 0, wgt)
end

function QuantRegSGD(x::AMatF, y::AVecF, wgt::Weighting = StochasticWeighting();
                     τ::Float64 = .5, start = zeros(ncols(x)))
    n, p = size(x)
    o = QuantRegSGD(p, wgt, τ = τ, start = start)
    update!(o, x, y)
    o
end


#-----------------------------------------------------------------------# state
statenames(o::QuantRegSGD) = [:β, :τ, :nobs]
state(o::QuantRegSGD) = Any[copy(o.β), o.τ, nobs(o)]

coef(o::QuantRegSGD) = copy(o.β)


#---------------------------------------------------------------------# update!
function updatebatch!(o::QuantRegSGD, x::AMatF, y::AVecF)
    n = length(y)
#     γ = weight(o)
#     o.β -= γ * vec(mean(((y .< x * o.β) - o.τ) .* x, 1))
    addgradient!(o.β, -vec(mean(((y .< x * o.β) - o.τ) .* x, 1)), weight(o))
    o.n += n
end

function update!(o::QuantRegSGD, x::AVecF, y::Float64)
    γ = weight(o)
    o.β -= γ * ((y < (x' * o.β)[1]) - o.τ) * x
    o.n += 1
end

# function update!(o::QuantRegSGD, x::AMatF, y::AVecF)
#     for i in 1:length(y)
#         update!(o, vec(x[i, :]), y[i])
#     end
# end
