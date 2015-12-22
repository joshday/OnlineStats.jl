abstract AbstractSparsity

"""
After `burnin` observations, coefficients will be set to zero if they are less
than `ϵ`.
"""
immutable HardThreshold <: AbstractSparsity
    burnin::Int
    ϵ::Float64
end
function HardThreshold(;burnin::Integer = 1000, threshold::Real = .01)
    @assert burnin > 0
    @assert threshold > 0
    HardThreshold(Int(burnin), Float64(threshold))
end

"""
### Enforce sparsity on a `StatLearn` object

`StatLearnSparse(o::StatLearn, s::AbstractSparsity)`
"""
type StatLearnSparse{S <: AbstractSparsity} <: OnlineStat
    o::StatLearn
    s::S
end
function StatLearnSparse(o::StatLearn, s::AbstractSparsity = HardThreshold())
    StatLearnSparse(o, s)
end
function Base.show(io::IO, o::StatLearnSparse)
    printheader(io, "StatLearnSparse")
    show(o.o)
end
nobs(o::StatLearnSparse) = nobs(o.o)
value(o::StatLearnSparse) = value(o.o)
coef(o::StatLearnSparse) = coef(o.o)
function fit!(o::StatLearnSparse, x::AVec, y::Real)
    fit!(o.o, x, y)
    fit!(o.o, o.s)
end
function fitbatch!(o::StatLearnSparse, x::AMat, y::AVec)
    fitbatch!(o.o, x, y)
    fit!(o.o, o.s)
end
function fit!(o::StatLearn, s::HardThreshold)
    if nobs(o) > s.burnin
        for j in 1:length(o.β)
            if abs(o.β[j]) < s.ϵ
                o.β[j] = 0.0
            end
        end
    end
end




# #-------------------------------------------------------------# Cross Validation
# type StatLearnCV{W<:Weight} <: OnlineStat
#     o::StatLearn
#     burnin::Int
#     weight::W
#     n::Int
#     nup::Int
# end
# function StatLearnCV(o::StatLearn, xtest::AMat, ytest::AVec,
#         wgt::Weight = LearningRate(); burnin = 1000
#     )
#     StatLearnCV(o, burnin, wgt, 0, 0)
# end
# function fit!(o::StatLearnCV, x::AMat, y::AVec)
#     if nobs(o) < o.burnin
#         fit!(o.o, x, y)
#     else
#         selftune!(o, x, y)
#     end
# end
#
# # NoPenalty
# function selftune!(o::StatLearnCV, x::AMat, y::AVec)
#     fit!(o.o, x, y)
# end
#
#
#
#
# #----------------------------------------------------------------------# update!
# # NoPenalty
# function updateλ!{A <: Algorithm, M <: ModelDefinition}(
#         o::StatLearn{A, M, NoPenalty},
#         x::AVecF, y::Float64, xtest, ytest, λrate::LearningRate)
#     update!(o, x, y)
# end
#
# # Actual penalties
# function updateλ!(o::StatLearn, x::AVecF, y::Float64, xtest, ytest, λrate)
#     # alter λ for o_l and o_h
#     γ = weight(λrate, 1, 1)
#     o_l = copy(o)
#     o_h = copy(o)
#
#     o_l.penalty.λ = max(0.0, o_l.penalty.λ - γ)
#     o_h.penalty.λ += γ
#
#     # update all three models
#     update!(o, x, y)
#     update!(o_l, x, y)
#     update!(o_h, x, y)
#
#     # Find best model for test data
#     loss_low = loss(o_l, xtest, ytest)
#     loss_mid = loss(o, xtest, ytest)
#     loss_hi = loss(o_h, xtest, ytest)
#     v = vcat(loss_low, loss_mid, loss_hi)
#     _, j = findmin(v)
#
#     if j == 1 # o_l is winner
#         o.β0 = o_l.β0
#         o.β = o_l.β
#         o.algorithm = o_l.algorithm
#         o.penalty = o_l.penalty
#     elseif j == 3 # o_h is winner
#         o.β0 = o_h.β0
#         o.β = o_h.β
#         o.algorithm = o_h.algorithm
#         o.penalty = o_h.penalty
#     end
# end
#
# function fit!(o::StatLearnCV, x::AVecF, y::Float64)
#     if nobs(o) < o.burnin
#         fit!(o.o, x, y)
#     else
#         updateλ!(o.o, x, y, o.xtest, o.ytest, o.λrate)
#     end
# end
#
# rmse(yhat, y) = mean(abs2(yhat - y))
#
# #------------------------------------------------------------------------# state
# value(o::StatLearnCV) = value(o.o)
# coef(o::StatLearnCV) = coef(o.o)
# predict(o::StatLearnCV, x) = predict(o, x)
# nobs(o::StatLearnCV) = nobs(o.o)
#
# function Base.show(io::IO, o::StatLearnCV)
#     printheader(io, "StatLearnCV")
#     print_item(io, "Burnin", o.burnin)
#     print_value_and_nobs(io, o)
# end
