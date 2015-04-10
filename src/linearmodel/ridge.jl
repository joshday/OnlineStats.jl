export RidgeReg, mse

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type RidgeReg <: OnlineStat
    A::Matrix{Float64}  # A = [X y]' * [X y] / n
    B::Matrix{Float64}  # "Swept" version of A
    int::Bool           # intercept in model?
    p::Int64            # Number of predictors
    n::Int64            # Number of observations used
    nb::Int64           # Number of batches used
end

function RidgeReg{T <: Real, S <: Real}(X::Matrix{T}, y::Vector{S};
                                        int::Bool = true)
    n, p = size(X)
    if int
        X = [ones(n) X]
        p += 1
    end
    A = BLAS.syrk('L', 'T', 1.0, [X y]) / n
    RidgeReg(A, A, int, p, n, 1)
end

function RidgeReg{T <: Real, S <: Real}(x::Vector{T}, y::Vector{S};
                                                 int::Bool = true)
    RidgeReg(reshape(x, length(x), 1), y, int=int)
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T <: Real, S <: Real}(obj::RidgeReg, X::Matrix{T}, y::Vector{S})
    n, p = size(X)
    if obj.int
        X = [ones(n) X]
        p += 1
    end
    γ = n / (obj.n + n)

    obj.A += γ * (BLAS.syrk('L', 'T', 1.0, [X y]) / n - obj.A)
    obj.n += n
    obj.nb += 1
end

update!{T <: Real, S <: Real}(obj::OnlineLinearModel, x::Vector{T}, y::Vector{S}) =
    update!(obj, reshape(x, length(x), 1), y)



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state{T <: Real}(obj::RidgeReg, λ::T = 0)
    names = [[symbol("x$i") for i in 1:obj.p], :λ, :n, :nb]
    estimates = [coef(obj, λ), λ, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# Other
# Sweep augmented matrix based on lambda value
function sweep!{T}(obj::RidgeReg, λ::T = 0)
    obj.B = copy(obj.A)
    obj.B[1:end-1, 1:end-1] += diagm(fill(λ / obj.n, obj.p))
    sweep!(obj.B, 1:obj.p)
end

function mse{T <: Real}(obj::RidgeReg, λ::T = 0)
    sweep!(obj, λ)
    obj.B[end, end] * (obj.n / (obj.n - obj.p))
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
function StatsBase.coef{T <: Real}(obj::RidgeReg, λ::T = 0)
    sweep!(obj, λ)
    vec(obj.B[end, 1:obj.p])
end

function StatsBase.coeftable{T <: Real}(obj::RidgeReg, λ::T = 0)
    β = coef(obj, λ)
    se = stderr(obj, λ)
    ts = β ./ se
    CoefTable([β se ts ccdf(FDist(1, obj.n - obj.p), abs2(ts))],
              ["Estimate","Std.Error","t value", "Pr(>|t|)"],
              ["x$i" for i = 1:obj.p], 4)
end

function StatsBase.confint{T <: Real}(obj::RidgeReg, λ = 0, level::T = .95)
    hcat(coef(obj, λ),coef(obj, λ)) + stderr(obj, λ) *
    quantile(TDist(obj.n - obj.p), (1. - level)/2.) * [1. -1.]
end

StatsBase.stderr(obj::RidgeReg, λ = 0) = sqrt(diag(vcov(obj, λ)))

StatsBase.vcov(obj::RidgeReg, λ = 0) = -mse(obj, λ) * obj.B[1:end-1, 1:end-1] / obj.n

function StatsBase.predict{T <: Real}(obj::RidgeReg, X::Matrix{T}, λ = 0)
    X * coef(obj, λ)
end

StatsBase.deviance(obj::RidgeReg) = error("Not implemented for RidgeReg")

StatsBase.loglikelihood(obj::RidgeReg) = error("Not implemented for RidgeReg")


function Base.show(io::IO, obj::RidgeReg)
    @printf(io, "Online Ridge Regression:\n")
    @printf(io, " * n = %i\n", obj.n)
    @printf(io, " * p = %i\n", obj.p)
end





# testing

x = randn(100, 10)
y = vec(sum(x, 2)) + randn(100)
obj = OnlineStats.RidgeReg(x, y)
obj1 = OnlineStats.OnlineLinearModel(x, y)


for i in 1:100
    x = randn(100, 10)
    y = vec(sum(x, 2)) + randn(100)
    OnlineStats.update!(obj, x, y)
    OnlineStats.update!(obj1, x, y)
end

