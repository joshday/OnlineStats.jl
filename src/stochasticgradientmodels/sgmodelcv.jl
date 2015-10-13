#--------------------------------------------------------# Type and Constructors
"""
Automatically tune the penalty parameter for an SGModel by finding the best fit
to the test data.

`SGModelCV(o::SGModel, xtest, ytest; λrate = LearningRate(), burnin = 1000)`

`SGModelCV(x, y, xtest, ytest; λrate = LearningRate(), burnin = 1000)`

Each call to `update!(o::SGModelCV, x, y)` updates the penalty parameter λ by
choosing the parameter which provides the best prediction on `y`, where `step`
is decided by `λrate`:

- `λ - step`
- `λ`
- `λ + step`
"""
type SGModelCV <: StochasticGradientStat
    o::SGModel
    o_l::SGModel    # low
    o_h::SGModel    # high
    λrate::LearningRate
    xtest::AMatF
    ytest::AVecF
    burnin::Int
    function SGModelCV(o::SGModel, xtest, ytest; λrate = LearningRate(), burnin = 1000)
        new(o, copy(o), copy(o), λrate, xtest, ytest, burnin)
    end
end

function SGModelCV(x, y, xtest, ytest; λrate = LearningRate(), burnin = 1000, kw...)
    o = SGModel(size(x, 2); kw...)
    ocv = SGModelCV(o, xtest, ytest; λrate = λrate, burnin = burnin)
    update!(ocv, x, y)
    ocv
end

#----------------------------------------------------------------------# update!
# NoPenalty
function updateλ!{A <: SGAlgorithm, M <: ModelDefinition}(
        o::SGModel{A, M, NoPenalty},
        o_l::SGModel{A, M, NoPenalty},
        o_h::SGModel{A, M, NoPenalty},
        x::AVecF, y::Float64, xtest, ytest, λrate::LearningRate)
    update!(o, x, y)
end

# L2Penalty and L1Penalty
function updateλ!(o::SGModel, o_l::SGModel, o_h::SGModel, x::AVecF, y::Float64, xtest, ytest, λrate)
    # alter λ for o_l and o_h
    # γ = η / (nobs(o) + 1) ^ decay
    γ = weight(λrate, 1, 1)
    o_l.penalty.λ = max(0.0, o_l.penalty.λ - γ)
    o_h.penalty.λ += γ

    # update all three models
    update!(o, x, y)
    update!(o_l, x, y)
    update!(o_h, x, y)

    # Find best model for test data
    loss_low = loss(o_l, xtest, ytest)
    loss_mid = loss(o, xtest, ytest)
    loss_hi = loss(o_h, xtest, ytest)
    v = vcat(loss_low, loss_mid, loss_hi)
    _, j = findmin(v)

    if j == 1 # o_l is winner
        o.penalty.λ = o_l.penalty.λ
        o_h.penalty.λ = o_l.penalty.λ
    elseif j == 2 # o is winner
        o_l.penalty.λ = o.penalty.λ
        o_h.penalty.λ = o.penalty.λ
    else # o_h is winner
        o_l.penalty.λ = o_h.penalty.λ
        o.penalty.λ = o_h.penalty.λ
    end
end

function update!(o::SGModelCV, x::AVecF, y::Float64)
    if nobs(o) < o.burnin
        update!(o.o, x, y)
        update!(o.o_l, x, y)
        update!(o.o_h, x, y)
    else
        updateλ!(o.o, o.o_l, o.o_h, x, y, o.xtest, o.ytest, o.λrate)
    end
end

rmse(yhat, y) = mean(abs2(yhat - y))

#------------------------------------------------------------------------# state
statenames(o::SGModelCV) = [:β, :penalty, :nobs]
state(o::SGModelCV) = Any[coef(o), copy(o.o.penalty), nobs(o)]
whatisλ(o::SGModelCV) = o.o.penalty.λ

StatsBase.coef(o::SGModelCV) = coef(o.o)
StatsBase.nobs(o::SGModelCV) = nobs(o.o)
StatsBase.predict(o::SGModelCV, x) = predict(o.o, x)

function Base.show(io::IO, o::SGModelCV)
    println(io, "Cross-Validated SGModel:")
    show(o.o)
end



# Testing
if false
    function linearmodeldata(n, p)
        x = randn(n, p)
        β = (collect(1:p) - .5*p) / p
        y = x*β + randn(n)
        (β, x, y)
    end
    n,p = 10_000, 10
    β, x, y = linearmodeldata(n,p)

    _, x2, y2 = linearmodeldata(1000, 10)  # test set

    o = OnlineStats.SGModel(p, penalty = OnlineStats.L2Penalty(.1), algorithm = OnlineStats.RDA(), model = L1Regression())
    ocv = OnlineStats.SGModelCV(o, x2, y2)
    update!(ocv, x, y)
end
