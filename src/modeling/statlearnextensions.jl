#-------------------------------------------------------------# Cross Validation
"""
`StatLearnCV(o::StatLearn, xtest, ytest)`

Automatically tune the regularization parameter λ for `o` by minimizing loss on
test data `xtest`, `ytest`.

```julia
sl = StatLearn(size(x, 2), LassoPenalty(.1))
o = StatLearnCV(sl, xtest, ytest)
fit!(o, x, y)
```
"""
type StatLearnCV{T<:Real, S<:Real, W<:Weight} <: OnlineStat{XYInput}
    o::StatLearn
    burnin::Int
    xtest::AMat{T}
    ytest::AVec{S}
    weight::W
end
function StatLearnCV(o::StatLearn, xtest::AMat, ytest::AVec, burnin = 1000; wgt::LearningRate = LearningRate())
    @assert length(o.β) == size(xtest, 2) "number of predictors doesn't match test data"
    StatLearnCV(o, burnin, xtest, ytest, wgt)
end

function _fit!(o::StatLearnCV, x::AVec, y::Real, γ::Float64)
    if nobs(o) < o.burnin
        _fit!(o.o, x, y, γ)
    else
        tuneλ!(o.o, x, y, γ, o.xtest, o.ytest)
    end
    o
end
# function _fit!(o::StatLearnCV, x::AMat, y::AVec, γ::Float64)
#     if nobs(o) < o.burnin
#         _fit!(o.o, x, y, γ)
#     else
#         tuneλ!(o.o, x, y, γ, o.xtest, o.ytest)
#     end
#     o
# end


function tuneλ!{A<:Algorithm, M<:ModelDefinition}(
        o::StatLearn{A, M, NoPenalty}, x, y, γ, xtest, ytest
    )
    fit!(o, x, y)
end
function tuneλ!(o::StatLearn, x, y, γ, xtest, ytest)
    o_l = copy(o)
    o_h = copy(o)
    o_l.penalty.λ = max(0.0, o_l.penalty.λ - γ)
    o_h.penalty.λ += γ

    fit!(o, x, y)
    fit!(o_l, x, y)
    fit!(o_h, x, y)

    loss_low = loss(o_l, xtest, ytest)
    loss_mid = loss(o, xtest, ytest)
    loss_hi = loss(o_h, xtest, ytest)
    best = min(loss_low, loss_mid, loss_hi)

    if best == loss_low # o_l is winner
        o.β0 = o_l.β0
        o.β = o_l.β
        o.algorithm = o_l.algorithm
        o.penalty.λ = o_l.penalty.λ
    elseif best == loss_hi # o_h is winner
        o.β0 = o_h.β0
        o.β = o_h.β
        o.algorithm = o_h.algorithm
        o.penalty.λ = o_h.penalty.λ
    end

end
nobs(o::StatLearnCV) = nobs(o.o)
nups(o::StatLearnCV) = nups(o.o)
value(o::StatLearnCV) = value(o.o)
coef(o::StatLearnCV) = coef(o.o)
predict(o::StatLearnCV, x) = predict(o.o, x)
loss(o::StatLearnCV, x, y) = loss(o.o, x, y)
loss(o::StatLearnCV) = loss(o, o.xtest, o.ytest)

function Base.show(io::IO, o::StatLearnCV)
    printheader(io, "StatLearnCV")
    print_item(io, "burnin", o.burnin)
    print_item(io, "loss", loss(o))
    show(io, o.o)
end
