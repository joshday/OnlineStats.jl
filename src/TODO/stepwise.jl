# type StepReg{W<:Weight} <: OnlineStat
#     β0::Float64
#     β::VecF
#     intercept::Bool
#     c::CovMatrix{W}
#     s::MatF         # placeholder for swept version of c
#     set::IntSet
#     weight::W
#     n::Int
#     nup::Int
# end
# function StepReg(p::Integer, wgt::Weight = EqualWeight(); intercept::Bool = true)
#     StepReg(
#         0.0, zeros(p), intercept, CovMatrix(p), zeros(p, p), IntSet([]),
#         wgt, 0, 0
#     )
# end
# function StepReg(x::AMat, y::AVec, wgt::Weight = EqualWeight())
#     o = StepReg(size(x, 2), wgt)
#     fit!(o, x, y)
#     o
# end
#
# function StatsBase.fit!(o::StepReg, x::AVec, y::Real)
#     fit!(o.c, vcat(x, y))
# end
# function value(o::StepReg)
#     o.intercept ? vcat(o.β0, o.β) : o.β
# end
#
# ## TESTING
# n, p = 1000, 10
# x = randn(n, p)
# β = collect(1.:p)
# y = x * β + randn(n)
# o = StepReg(x, y)
# display(o)
#
# # # Online Stepwise Regression
# # #
# # # With each updated batch, there is the possibility of one variable
# # # entering or leaving the model based on Mallow's Cp
# #
# # #-------------------------------------------------------# Type and Constructors
# # """
# # Online stepwise regression.
# #
# # At each update, there is the possible of one variable entering or leaving the model.
# # Performs best using `fitbatch!()` with large batches.
# # """
# # type StepwiseReg{W <: Weight} <: OnlineStat
# #     C::CovarianceMatrix{W}  # Cov([X y])
# #     s::MatF                 # "Swept" version of [X y]' [X y] / n
# #     set::IntSet             # set of coefficients included in the model
# #     n::Int
# # end
# #
# # function StepwiseReg(x::AMatF, y::AVecF, wgt::Weight = EqualWeight())
# #     n, p = size(x)
# #     o = StepwiseReg(p, wgt)
# #     fitbatch!(o, x, y)
# #     o
# # end
# #
# # function StepwiseReg(p::Integer, wgt::Weighting = default(Weighting))
# #     c = CovarianceMatrix(p + 1, wgt)
# #     StepwiseReg(c, zeros(p + 1, p + 1), IntSet([]), 0)
# # end
# #
# #
# # #-----------------------------------------------------------------------# state
# # statenames(o::StepwiseReg) = [:β, :nobs]
# # state(o::StepwiseReg) = Any[coef(o), nobs(o)]
# #
# # function StatsBase.coef(o::StepwiseReg)
# #     β = vec(o.s[end, 1:end - 1])
# #     for i in setdiff(1:length(β), o.set)
# #         β[i] = 0.
# #     end
# #     β
# # end
# #
# # #----------------------------------------------------------------------# fit!
# # function fit!(o::StepwiseReg, x::AVecF, y::Float64)
# #     fitbatch!(o, x', collect(y))
# # end
# #
# # function fitbatch!(o::StepwiseReg, x::AMatF, y::AVecF)
# #     n, p = size(x)
# #     o.n += n
# #     fitbatch!(o.C, hcat(x, y))
# #     copy!(o.s, o.C.A)
# #
# #     # get average squared error using all predictors
# #     sweep!(o.s, 1:p)
# #     ase = o.s[end, end]
# #
# #     copy!(o.s, o.C.A)
# #     sweep!(o.s, collect(o.set))
# #
# #     # Find best index to add/remove
# #     s = 1
# #     val = o.s[end, 1] ^ 2 / (o.s[1, 1] * ase) * (o.n - in(1, o.set)) + 2.0 - in(1, o.set)
# #     for i in 2:p
# #         newval = o.s[end, i] ^ 2 / (o.s[i, i] * ase) * (o.n - in(i, o.set)) - 2.0 * in(i, o.set)
# #         if newval > val
# #             val = newval
# #             s = i
# #         end
# #     end
# #
# #     if s in o.set
# #         delete!(o.set, s)
# #     else
# #         push!(o.set, s)
# #     end
# #
# #     DEBUG("Active set: ", o.set)
# # end
# #
# #
# # ########## TEST code
# # # log_severity!(DebugSeverity)
# # #
# # # n,p = 10_000, 10
# # # x = randn(n,p)
# # # β = collect(1.:p)
# # # β[5] = 0.
# # # y = x*β + randn(n)
# # #
# # # o = StepwiseReg(p)
# # # @time fit!(o, x, y, 500)
# # # print(coef(o))
