#--------------------------------------------------------# Type and Constructors
"""
Automatically tune the penalty parameter for an StochasticModelCV by finding the best fit
to the test data.

`StochasticModelCV(o::StochasticModelCV, xtest, ytest; λrate = LearningRate(), burnin = 1000)`

`StochasticModelCV(x, y, xtest, ytest; λrate = LearningRate(), burnin = 1000)`

Each call to `update!(o::StochasticModelCV, x, y)` updates the penalty parameter λ by
choosing the parameter which provides the best prediction on `y`, where `step`
is decided by `λrate`:

- `λ - step`
- `λ`
- `λ + step`
"""
type StochasticModelCV <: StochasticGradientStat
    o::StochasticModel
    λrate::LearningRate
    xtest::AMatF
    ytest::AVecF
    burnin::Int
    function StochasticModelCV(o::StochasticModel, xtest, ytest; λrate = LearningRate(), burnin = 1000)
        new(o, λrate, xtest, ytest, burnin)
    end
end

function StochasticModelCV(x, y, xtest, ytest; λrate = LearningRate(), burnin = 1000, kw...)
    o = StochasticModel(size(x, 2); kw...)
    ocv = StochasticModelCV(o, xtest, ytest; λrate = λrate, burnin = burnin)
    update!(ocv, x, y)
    ocv
end

#----------------------------------------------------------------------# update!
# NoPenalty
function updateλ!{A <: Algorithm, M <: ModelDefinition}(
        o::StochasticModel{A, M, NoPenalty},
        x::AVecF, y::Float64, xtest, ytest, λrate::LearningRate)
    update!(o, x, y)
end

# Actual penalties
function updateλ!(o::StochasticModel, x::AVecF, y::Float64, xtest, ytest, λrate)
    # alter λ for o_l and o_h
    γ = weight(λrate, 1, 1)
    o_l = copy(o)
    o_h = copy(o)

    o_l.penalty.λ = max(0.0, o_l.penalty.λ - γ)
    o_h.penalty.λ += γ

    # update all three models
    update!(o, x, y)
    update!(o_l, x, y)
    update!(o_h, x, y)

    # Find best model for test data
    loss_low = cv_criteria(o_l, xtest, ytest)
    loss_mid = cv_criteria(o, xtest, ytest)
    loss_hi = cv_criteria(o_h, xtest, ytest)
    v = vcat(loss_low, loss_mid, loss_hi)
    _, j = findmin(v)

    if j == 1 # o_l is winner
        o.β0 = o_l.β0
        o.β = o_l.β
        o.algorithm = o_l.algorithm
        o.penalty = o_l.penalty
    elseif j == 3 # o_h is winner
        o.β0 = o_h.β0
        o.β = o_h.β
        o.algorithm = o_h.algorithm
        o.penalty = o_h.penalty
    end
end

function update!(o::StochasticModelCV, x::AVecF, y::Float64)
    if nobs(o) < o.burnin
        update!(o.o, x, y)
    else
        updateλ!(o.o, x, y, o.xtest, o.ytest, o.λrate)
    end
end

rmse(yhat, y) = mean(abs2(yhat - y))

#------------------------------------------------------------------------# state
statenames(o::StochasticModelCV) = [:β, :penalty, :nobs]
state(o::StochasticModelCV) = Any[coef(o), copy(o.o.penalty), nobs(o)]
whatisλ(o::StochasticModelCV) = o.o.penalty.λ

StatsBase.coef(o::StochasticModelCV) = coef(o.o)
StatsBase.nobs(o::StochasticModelCV) = nobs(o.o)
StatsBase.predict(o::StochasticModelCV, x) = predict(o.o, x)

function Base.show(io::IO, o::StochasticModelCV)
    print_with_color(:blue, io, "Cross-Validated StochasticModel:\n")
    println(io, "  > Burnin:     ", o.burnin)
    println(io, "  > Avg. loss:  ", cv_criteria(o.o, o.xtest, o.ytest))
    show(io, o.o)
end

#-----------------------------------------------------# cross validation critera
"Cross validation criteria, average loss"
function cv_criteria(o::StochasticModel, x, y)
    mean(abs2(y - predict(o, x)))
end

function cv_criteria{A<:Algorithm, P<:Penalty}(o::StochasticModel{A, HuberRegression, P}, x, y)
    resid = y - predict(o, x)
    for i in 1:length(resid)
        if abs(resid[i]) > o.model.δ
            resid[i] = 0.5 * resid[i] ^ 2
        else
            resid[i] = o.model.δ * abs(resid[i] - 0.5 * o.model.δ)
        end
    end
    mean(resid)
end

function cv_criteria{A<:Algorithm, P<:Penalty}(o::StochasticModel{A, L1Regression, P}, x, y)
    mean(abs(y - predict(o, x)))
end

function cv_criteria{A<:Algorithm, P<:Penalty}(o::StochasticModel{A, LogisticRegression, P}, x, y)
    # p = predict(o, x)
    # mean([p[i] * y[i] + (1 - p[i]) * (1 - y[i]) for i in 1:length(p)])
    mean(abs(y - (predict(o, x) .> .5)))
end

function cv_criteria{A<:Algorithm, P<:Penalty}(o::StochasticModel{A, PoissonRegression, P}, x, y)
    mean(abs(y - predict(o, x)))
end

function cv_criteria{A<:Algorithm, P<:Penalty}(o::StochasticModel{A, QuantileRegression, P}, x, y)
    resid = y - predict(o, x)
    mean([resid[i] * (o.model.τ - (resid[i] < 0)) for i in 1:length(y)])
end

function cv_criteria{A<:Algorithm, P<:Penalty}(o::StochasticModel{A, SVMLike, P}, x, y)
    pred = predict(o, x)
    mean([max(0.0, 1.0 - y[i] * pred[i]) for i in 1:length(pred)])
end
