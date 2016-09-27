# # Experimental StatLearn-esque type using online MM algorithm
#
# function α1!(storage, x)
#     sumabsx = sumabs(x)
#     for i in eachindex(storage)
#         storage[i] = abs(x[i]) / sumabsx
#     end
# end
# function α2!(storage, x)
#     sumabs2x = sumabs2(x)
#     for i in eachindex(storage)
#         storage[i] = x[i] ^ 2 / sumabs2x
#     end
# end
#
# denom(::LinearRegression, xj, ŷ, αj)   = xj ^ 2 / αj
# denom(::LogisticRegression, xj, ŷ, αj) = xj ^ 2 / αj * ŷ * (1.0 - ŷ)
# denom(::PoissonRegression, xj, ŷ, αj)  = xj ^ 2 / αj * ŷ
#
#
# type StatLearnMM{W <: Weight, F <: Function, M <: Model} <: OnlineStat{XYInput}
#     β0::Float64
#     β::VecF
#     intercept::Bool
#     model::M
#     H0::Float64 # sufficient statistic for intercept
#     H::VecF     # sufficient statistics for coefficients
#     α::F        # Function for creating weights (in place) from De Pierro majorization
#     αvec::VecF  # Vector to store α weights
#     weight::W
# end
# function StatLearnMM(p::Integer, model::Model = LinearRegression(),
#         wt::Weight = LearningRate(); α::Function = α1!, intercept::Bool = true,
#         )
#     StatLearnMM(0.0, zeros(p), intercept, model, 0.0, zeros(p), α, zeros(p), wt)
# end
#
# function _fit!(o::StatLearnMM, x::AVec, y::Real, γ::Float64)
#     o.α(o.αvec, x)
#     ŷ = predict(o, x)
#     if o.intercept
#
#         o.H0 = smooth(o.H0, denom(o.model, 1.0, ŷ, ))
#     end
#
#     for j in eachindex(o.β)
#
#     end
# end
#
#
# coef(o::StatLearnMM) = vcat(o.β0, o.β)
# value(o::StatLearnMM) = coef(o)
# predict(o::StatLearnMM, x::AVec) = o.β0 + dot(x, o.β)
#
#
# using DataGenerator
# x, y, β = linregdata(1000, 5)
# o = StatLearnMM(5)
# fit!(o, x, y)
# @show o
