# Author(s): Josh Day <emailjoshday@gmail.com>

export OnlineLinearModel
export mse, coef, coeftable, confint, stderr, vcov, predict


#-----------------------------------------------------------------------------#
#----------------------------------------------------------# OnlineLinearModel
type OnlineLinearModel <: OnlineStat
    A::Matrix         # A = [X y]' * [X y]
    B::Matrix         # "Swept" version of A
    p::Int64          # Number of predictors
    n::Int64          # Number of observations used
    nb::Int64         # Number of batches used
end

function OnlineLinearModel(X::Matrix, y::Vector)
    n, p = size(X)
    A = BLAS.syrk('L', 'T', 1.0, [X y]) / n
    B = sweep!(copy(A), 1:p)
    OnlineLinearModel(A, B, p, n, 1)
end

function OnlineLinearModel(x::Vector, y::Vector)
    n = length(x)
    OnlineLinearModel(reshape(x, n, 1), y)
end



#-----------------------------------------------------------------------------#
#----------------------------------------------------# StatsBase-ish functions

mse(obj::OnlineLinearModel) = obj.B[end, end] * (obj.n / (obj.n - obj.p))

coef(obj::OnlineLinearModel) = vec(obj.B[end, 1:obj.p])

function coeftable(obj::OnlineLinearModel)
    β = coef(obj)
    se = stderr(obj)
    ts = β ./ se
    CoefTable([β se ts ccdf(FDist(1, obj.n - obj.p), abs2(ts))],
              ["Estimate","Std.Error","t value", "Pr(>|t|)"],
              ["x$i" for i = 1:obj.p], 4)
end

function confint(obj::OnlineLinearModel, level::Real)
    hcat(coef(obj),coef(obj)) + stderr(obj) *
    quantile(TDist(obj.n - obj.p), (1. - level)/2.) * [1. -1.]
end
confint(obj::OnlineLinearModel) = confint(obj, 0.95)

stderr(obj::OnlineLinearModel) = sqrt(diag(vcov(obj)))

vcov(obj::OnlineLinearModel) = -mse(obj) * obj.B[1:end-1, 1:end-1] / obj.n

predict(obj::OnlineLinearModel, X::Matrix) = X * coef(obj)


deviance(obj::OnlineLinearModel) =      error("Not Implemented")
loglikelihood(obj::OnlineLinearModel) = error("Not Implemented")


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineLinearModel, X, y)
    n, p = size(X)
    γ = n / (obj.n + n)

    obj.A += γ * (BLAS.syrk('L', 'T', 1.0, [X y]) / n - obj.A)
    obj.B = sweep!(copy(obj.A), 1:obj.p)
    obj.n += n
    obj.nb += 1
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineLinearModel)
    names = [[symbol("x$i") for i in 1:obj.p], :n, :nb]
    estimates = [coef(obj), obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# Batch 1
x1 = randn(1000, 3)
y1 = vec(sum(x1, 2)) + randn(1000)
obj = OnlineStats.OnlineLinearModel(x1, y1)
OnlineStats.coef(obj)
OnlineStats.mse(obj)

using GLM
fit = lm(x1, y1)
StatsBase.coef(fit)
sum(residuals(fit) .^ 2) / (1000 - 3)

# # Batch 2
x2 = rand(1002, 3)
y2 = vec(sum(x2, 2)) + randn(1002)
OnlineStats.update!(obj, x2, y2)

OnlineStats.coef(obj)
OnlineStats.mse(obj)
OnlineStats.vcov(obj)
OnlineStats.stderr(obj)

OnlineStats.state(obj)
OnlineStats.coeftable(obj)
OnlineStats.confint(obj)

fit = lm([x1, x2], [y1, y2])
GLM.coef(fit)
GLM.confint(fit)
sum(residuals(fit) .^ 2) / (2002 - 3)

