# Stochastic Gradient Descent algorithm for linear models
#-------------------------------------------------------# Type and Constructors
type FastLM <: OnlineStat
    p::Int64       # length(β)
    β::VecF
    xyvar::Variances{ExponentialWeighting}
    n::Int64
    weighting::StochasticWeighting
end

# function FastLM(x::MatF, y::VecF, wgt::StochasticWeighting = StochasticWeighting(),
#                 start = zeros(length(y)))
#     o = FastLM(size(x, 2), wgt, start)
#     update!(o, x, y)
#     o
# end

# function FastLM(x::VecF, y::Float64, wgt::StochasticWeighting = StochasticWeighting,
#                 start = size(x, 2))
#     o = FastLM(length(x), wgt, start)
#     update!(o, x, y)
#     o
# end

FastLM(p::Int, wgt::StochasticWeighting = StochasticWeighting(), start = zeros(p)) =
    FastLM(p, start, Variances(p, ExponentialWeighting(wgt.λ)), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::FastLM) = [:β, :nobs]
state(o::FastLM) = Any[o.β, nobs(o)]

# function originalβ(scaledβ, xμ, xσ, yμ, yσ)
#     β₀ = yμ - yσ * (sum(scaledβ .* xμ ./ xσ))
#     return [β₀; yσ * scaledβ ./ xσ]
# end

# StatsBase.coef(o::FastLM) = copy(o.β)


#---------------------------------------------------------------------# update!
# function update!(o::FastLM, x::VecF, y::Float64)
#     o.β += (y - sum(x .* o.β)) * x
#     o.n += 1
# end

# function update!(o::FastLM, x::MatF, y::VecF)
#     for i in 1:size(x,1)
#         update!(o, vec(x[i, :]), y[i])
#     end
# end


#------------------------------------------------------------------------# Base
# function StatsBase.predict(o::FastLM, x::Matrix)
#     β = coef(o)
#     β[1] + x * β[2:end]
# end


