export OnlineLinearModel
export mse

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type OnlineLinearModel <: OnlineStat
    A::Matrix         # A = [X y]' * [X y]
    B::Matrix         # "Swept" version of A
    int::Bool         # intercept in model?
    p::Int64          # Number of predictors
    n::Int64          # Number of observations used
    nb::Int64         # Number of batches used
end

function OnlineLinearModel(X::Matrix, y::Vector; int::Bool = true)
    n, p = size(X)
    if int
        X = [ones(n) X]
        p += 1
    end
    A = BLAS.syrk('L', 'T', 1.0, [X y]) / n
    B = sweep!(copy(A), 1:p)
    OnlineLinearModel(A, B, int, p, n, 1)
end

function OnlineLinearModel(x::Vector, y::Vector; int::Bool = true)
    n = length(x)
    OnlineLinearModel(reshape(x, n, 1), y, int=int)
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base

mse(obj::OnlineLinearModel) = obj.B[end, end] * (obj.n / (obj.n - obj.p))

StatsBase.coef(obj::OnlineLinearModel) = vec(obj.B[end, 1:obj.p])

function StatsBase.coeftable(obj::OnlineLinearModel)
    β = coef(obj)
    se = stderr(obj)
    ts = β ./ se
    CoefTable([β se ts ccdf(FDist(1, obj.n - obj.p), abs2(ts))],
              ["Estimate","Std.Error","t value", "Pr(>|t|)"],
              ["x$i" for i = 1:obj.p], 4)
end

function StatsBase.confint{T <: Real}(obj::OnlineLinearModel, level::T = 0.95)
    hcat(coef(obj),coef(obj)) + stderr(obj) *
    quantile(TDist(obj.n - obj.p), (1. - level)/2.) * [1. -1.]
end

StatsBase.stderr(obj::OnlineLinearModel) = sqrt(diag(vcov(obj)))

StatsBase.vcov(obj::OnlineLinearModel) = -mse(obj) * obj.B[1:end-1, 1:end-1] / obj.n

StatsBase.predict(obj::OnlineLinearModel, X::Matrix) = X * coef(obj)

StatsBase.deviance(obj::OnlineLinearModel) =
    error("Not implemented for OnlineLinearModel")

StatsBase.loglikelihood(obj::OnlineLinearModel) =
    error("Not implemented for OnlineLinearModel")


# function Base.merge(m1::OnlineLinearModel, m2::OnlineLinearModel)
# end

# function Base.merge!(m1::OnlineLinearModel, m2::OnlineLinearModel)
# end

function Base.show(io::IO, obj::OnlineLinearModel)
    println(io, "Online Linear Model:\n", coeftable(obj))
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineLinearModel, X::Matrix, y::Vector)
    n, p = size(X)
    if obj.int
        X = [ones(n) X]
        p += 1
    end
    γ = n / (obj.n + n)

    obj.A += γ * (BLAS.syrk('L', 'T', 1.0, [X y]) / n - obj.A)
    obj.B = sweep!(copy(obj.A), 1:obj.p)
    obj.n += n
    obj.nb += 1
end

update!(obj::OnlineLinearModel, x::Vector, y::Vector) =
    update!(obj, reshape(x, length(x), 1), y)

#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineLinearModel)
    names = [[symbol("x$i") for i in 1:obj.p], :n, :nb]
    estimates = [coef(obj), obj.n, obj.nb]
    return([names estimates])
end

