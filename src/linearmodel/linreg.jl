export LinReg

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors

# This type stores the necessary information to generate OLS estimates
type LinReg <: OnlineStat
    C::CovarianceMatrix  # Cov([X y])
    S::Matrix{Float64}   # "Swept" version of C
    p::Int64             # Number of predictors
    n::Int64             # Number of observations used
end

function LinReg{T <: Real, S <: Real}(X::Array{T}, y::Vector{S})
    n, p = size(X)
    C = CovarianceMatrix([X y])
    LinReg(C, cor(C), p, n)
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T <: Real, S <: Real}(obj::LinReg, X::Array{T}, y::Vector{S})
    update!(obj.C, [X y])
    obj.n += size(X, 1)
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# fit!
function StatsBase.fit!(obj::LinReg)
    copy!(obj.S, cor(obj.C))
    sweep!(obj.S, 1:obj.p)
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::LinReg)
    names = [[symbol("x$i") for i in 1:obj.p], :n, :nb]
    estimates = [coef(obj), obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#-------------------------------------------------------------------------# mse
function mse(obj::LinReg)
    fit!(obj)
    obj.S[end, end] * (obj.n / (obj.n - obj.p))
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base

# By default, coefficients are based on standardized y and x (thus no intercept)
# If standardized = false, returns p + 1 vector (includes intercept)
function StatsBase.coef(obj::LinReg; original_y = false)
    fit!(obj)
    if original_y
        σ = std(obj.C)[end]
        μ = mean(obj.C)[end]
        β = vec(obj.S[end, 1:obj.p])
        return [ μ; σ * β]
    else
        return vec(obj.S[end, 1:obj.p])
    end

end

function StatsBase.coeftable(obj::LinReg)
    β = coef(obj)
    se = stderr(obj)
    ts = β ./ se
    CoefTable([β se ts ccdf(FDist(1, obj.n - obj.p), abs2(ts))],
              ["Estimate","Std.Error","t value", "Pr(>|t|)"],
              ["x$i" for i = 1:obj.p], 4)
end

function StatsBase.confint{T <: Real}(obj::LinReg, level::T = 0.95)
    hcat(coef(obj),coef(obj)) + stderr(obj) *
    quantile(TDist(obj.n - obj.p), (1. - level)/2.) * [1. -1.]
end

StatsBase.stderr(obj::LinReg) = sqrt(diag(vcov(obj)))

StatsBase.vcov(obj::LinReg) = -mse(obj) * obj.S[1:end-1, 1:end-1] / obj.n

# Predict original scale y values from original scale X matrix
function StatsBase.predict(obj::LinReg, X::Matrix)
    σ = std(obj.C)
    μ = mean(obj.C)
    scale(X .- μ[1:end-1]', 1 ./ σ[1:end-1]) *
        (coef(obj) * σ[end]) + μ[end]
end

function Base.show(io::IO, obj::LinReg)
    @printf(io, "Online Linear Regression\n")
    @printf(io, "Standardized coefficients: \n")
    println(coeftable(obj))
    return
end









# Testing

using StatsBase
n, p = 1000, 250
truep = [1:10]
x = randn(n, p)
β = [truep; zeros(p - length(truep))]
y = x * β + randn(n)

obj = OnlineStats.LinReg(x, y)
@time for i in 2:100
    copy!(x, randn(n, p))
    copy!(y, x * β + randn(n))
    OnlineStats.update!(obj, x, y)
end
resid = y - predict(obj, x)
