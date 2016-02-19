#------------------------------------------------------------# Enforced Sparsity
abstract AbstractSparsity

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
Enforce sparsity on a `StatLearn` object.  Currently, the only option is
`HardThreshold`, which after `burnin` observations, any coefficient less than
`threshold` is set to 0.

```julia
StatLearnSparse(StatLearn(size(x,2)), HardThreshold(burnin = 1000, threshold = .01))
fit!(o, x, y)
```
"""
type StatLearnSparse{S <: AbstractSparsity} <: OnlineStat{XYInput}
    o::StatLearn
    s::S
end
function StatLearnSparse(o::StatLearn, s::AbstractSparsity = HardThreshold())
    StatLearnSparse(o, s)
end
function Base.show(io::IO, o::StatLearnSparse)
    printheader(io, "StatLearnSparse")
    print_item(io, "nonzero", mean(o.o.β .!= 0.0))
    show(o.o)
end
nobs(o::StatLearnSparse) = nobs(o.o)
value(o::StatLearnSparse) = value(o.o)
coef(o::StatLearnSparse) = coef(o.o)
function fit!(o::StatLearnSparse, x::AVec, y::Real)
    fit!(o.o, x, y)
    make_sparse!(o.o, o.s)
    o
end
function fitbatch!(o::StatLearnSparse, x::AMat, y::AVec)
    fitbatch!(o.o, x, y)
    make_sparse!(o.o, o.s)
    o
end


function make_sparse!(o::StatLearn, s::HardThreshold)
    if nobs(o) > s.burnin
        for j in 1:length(o.β)
            if abs(o.β[j]) < s.ϵ
                o.β[j] = 0.0
            end
        end
    end
end



#-------------------------------------------------------------# Cross Validation
"""
`StatLearnCV(o::StatLearn, xtest, ytest)`

Automatically tune the regularization parameter λ for `o` by minimizing loss on
test data `xtest`, `ytest`.

```julia
sl = StatLearn(size(x, 2), L1Penalty(.1))
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

function fit!(o::StatLearnCV, x::AVec, y::Real)
    if nobs(o) < o.burnin
        fit!(o.o, x, y)
    else
        γ = weight!(o, 1)
        tuneλ!(o.o, x, y, γ, o.xtest, o.ytest)
    end
    o
end
# TODO: fitbatch!
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
