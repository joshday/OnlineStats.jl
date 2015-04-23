export SparseReg

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors

# This type stores the necessary information to generate estimates from OLS,
# ridge, lasso, and elastic net (types can be extended for others)
type SparseReg{P <: Penalty} <: OnlineStat
    C::CovarianceMatrix  # Cov([X y])
    S::Matrix{Float64}   # "Swept" version of C
    penalty::P           # Type of penalty
    p::Int64             # Number of predictors
    n::Int64             # Number of observations used
end

function SparseReg{T <: Real, S <: Real, P <: Penalty}(X::Array{T}, y::Vector{S},
                                                       ::Type{P})
    n, p = size(X)
    C = CovarianceMatrix([X y])
    LinReg(C, cor(C), p, n)
end


#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# fit!
function StatsBase.fit!(obj::LinReg, ::Type{Ridge}, λ = 0)
    copy!(obj.S, cor(obj.C) + diagm([rep(λ, obj.p), 0]))
    sweep!(obj.S, 1:obj.p)
end
