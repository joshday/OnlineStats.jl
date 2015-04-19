export RidgeReg

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type RidgeReg <: OnlineStat
    C::CovarianceMatrix  # Cov([X y])
    S::Matrix{Float64}   # "Swept" version of C
    p::Int64             # Number of predictors
    n::Int64             # Number of observations used
    nb::Int64            # Number of batches used
end

function RidgeReg{T <: Real}(X::Array{T}, y::Vector{T})
    n, p = size(X)
    C = CovarianceMatrix([X y])
    RidgeReg(C, cov(C), p, n, 1)
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T <: Real}(obj::RidgeReg, X::Array{T}, y::Vector{T})
    update!(obj.C, [X y])
    obj.n += size(X, 1)
    obj.nb += 1
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# fit!
function StatsBase.fit!(obj::RidgeReg, λ)
    obj.S = cov(obj.C)
    obj.S[1:end-1, 1:end-1] += diagm(rep(λ, obj.p))
    sweep!(obj.S, 1:obj.p)
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state{T <: Real}(obj::RidgeReg, λ::T = 0)
    names = [[symbol("x$i") for i in 1:obj.p], :λ, :n, :nb]
    estimates = [coef(obj, λ), λ, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
function mse{T <: Real}(obj::RidgeReg, λ::T = 0)
    fit!(obj, λ)
    obj.S[end, end] * (obj.n / (obj.n - obj.p))
end

function StatsBase.coef{T <: Real}(obj::RidgeReg, λ::T = 0)
    fit!(obj, λ)
    vec(obj.S[end, 1:obj.p])
end

# function StatsBase.coeftable{T <: Real}(obj::RidgeReg, λ::T = 0)
#     β = coef(obj, λ)
#     se = stderr(obj, λ)
#     ts = β ./ se
#     CoefTable([β se ts ccdf(FDist(1, obj.n - obj.p), abs2(ts))],
#               ["Estimate","Std.Error","t value", "Pr(>|t|)"],
#               ["x$i" for i = 1:obj.p], 4)
# end

# function StatsBase.confint{T <: Real}(obj::RidgeReg, λ = 0, level::T = .95)
#     hcat(coef(obj, λ),coef(obj, λ)) + stderr(obj, λ) *
#     quantile(TDist(obj.n - obj.p), (1. - level)/2.) * [1. -1.]
# end

# StatsBase.stderr(obj::RidgeReg, λ = 0) = sqrt(diag(vcov(obj, λ)))

# StatsBase.vcov(obj::RidgeReg, λ = 0) = -mse(obj, λ) * obj.S[1:end-1, 1:end-1] / obj.n

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

n, p = 100, 50
x = randn(n, p)
β = [1:p]
y = x * β + randn(n)
obj = OnlineStats.RidgeReg(x, y)
obj1 = OnlineStats.OnlineLinearModel(x, y)


for i in 1:100
    x = randn(n, p)
    y = x * β + randn(n)
    OnlineStats.update!(obj, x, y)
    OnlineStats.update!(obj1, x, y)
end

λs = 0:.1:6
results = zeros(length(λs), obj.p + 1)
for i in 1:length(λs)
    results[i, :] = [coef(obj, λs[i])' λs[i]]
end

df = convert(DataFrame, results)
names!(df, [[symbol("x$i") for i in 1:obj.p], :λ])
df_melt = melt(df, obj.p + 1)
plot(df_melt, x=:λ, y=:value, color=:variable, Geom.line)
