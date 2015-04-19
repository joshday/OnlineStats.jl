export LinReg

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors

# This type stores the necessary information to generate OLS, ridge, lasso, and
# elastic net estimates
type LinReg <: OnlineStat
    C::CovarianceMatrix  # Cov([X y])
    S::Matrix{Float64}   # "Swept" version of C
    intercept::Bool      # Include intercept?
    standardize_x::Bool  # Standardize X?
    standardize_y::Bool  # Standardize y?
    p::Int64             # Number of predictors
    n::Int64             # Number of observations used
end

function LinReg{T <: Real, S <: Real}(X::Array{T}, y::Vector{S};
                                      intercept = true,
                                      standardize_x = true,
                                      standardize_y = false)
    n, p = size(X)
    C = CovarianceMatrix([X y])
    LinReg(C, cor(C), intercept, standardize_x, standardize_y, p, n)
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T <: Real, S <: Real}(obj::LinReg, X::Array{T}, y::Vector{S})
    update!(obj.C, [X y])
    obj.n += size(X, 1)
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# fit!
# OLS
function StatsBase.fit!(obj::LinReg, standardize::Bool = false)
    if standardize
        obj.S = cor(obj.C)
    else
        obj.S = copy(obj.C.A)
    end
    sweep!(obj.S, 1:obj.p)
end

# Ridge
# function fit!{P <: Penalty}(obj::LinReg, p::Type{P}, λ = 0)
#     obj.S = cor(obj.C)
#     if λ != 0
#         obj.S += diagm([rep(λ, obj.p), 0])
#     end
#     sweep!(obj.S, 1:obj.p)
# end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::LinReg, standardize::Bool = false)
    names = [[symbol("x$i") for i in 1:obj.p], :n, :nb]
    estimates = [coef(obj, standardize), obj.n, obj.nb]
    return([names estimates])
end

# function state(obj::LinReg, ::Type{Ridge}, λ)
#     names = [[symbol("x$i") for i in 1:obj.p], :λ, :n, :nb]
#     estimates = [coef(obj, Ridge, λ), λ, obj.n, obj.nb]
#     return([names estimates])
# end


#-----------------------------------------------------------------------------#
#-------------------------------------------------------------------------# mse
function mse(obj::LinReg)
    fit!(obj)
    obj.S[end, end] * (obj.n / (obj.n - obj.p))
end

# function mse(obj::LinReg, ::Type{Ridge}, λ)
#     fit!(obj, Ridge, λ)
#     obj.S[end, end] * (obj.n / (obj.n - obj.p))
# end


#-----------------------------------------------------------------------------#
#-------------------------------------------------------------------# OLS: Base
function StatsBase.coef(obj::LinReg, standardize::Bool = false)
    fit!(obj, standardize)
    vec(obj.S[end, 1:obj.p])
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

StatsBase.predict(obj::LinReg, X::Matrix) = X * coef(obj)

function Base.show(io::IO, obj::LinReg)
    println(io, "Online Linear Model:\n", coeftable(obj))
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------# Ridge: Base
# function StatsBase.coef(obj::LinReg, ::Type{Ridge}, λ)
#     fit!(obj, Ridge, λ)
#     σ = std(obj.C)
#     μ = mean(obj.C)
#     β = vec(obj.S[end, 1:obj.p]) .* (σ[end] ./ σ[1:end-1])
#     β₀ = μ[end] - β' * μ[1:end-1]
#     return [β₀; β]
# end








# Testing

n, p = 100, 50
x = randn(n, p)
β = [1:p]
y = x * β + randn(n)
obj = OnlineStats.LinReg(x, y)





# for i in 1:1000
#     x = randn(n, p)
#     y = x * β + randn(n)
#     OnlineStats.update!(obj, x, y)
# end

# coef(obj)
# coef(obj, OnlineStats.Ridge, 1)
