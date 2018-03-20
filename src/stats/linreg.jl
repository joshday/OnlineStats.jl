

#-----------------------------------------------------------------------# LinReg
"""
    LinReg(p)

Ridge regression of `p` variables with elementwise regularization.

# Example

    x = randn(100, 10)
    y = x * linspace(-1, 1, 10) + randn(100)
    o = LinReg(10)
    Series((x,y), o)
    value(o)
"""
mutable struct LinReg{W} <: OnlineStat{(1,0)}
    β::Vector{Float64}
    A::Matrix{Float64}
    weight::W
    n::Int
end
LinReg(;weight=EqualWeight()) = LinReg(zeros(0), zeros(1, 1), weight, 0)

function matviews(o::LinReg)
    p = length(o.β)
    @views o.A[1:p, 1:p], o.A[1:p, end]
end
function _fit!(o::LinReg, xy)
    γ = o.weight(o.n += 1)
    x, y = xy 
    if o.n == 1 
        p = length(x)
        o.β = zeros(p)
        o.A = zeros(p + 1, p + 1)
    end
    for j in 1:(size(o.A, 2)-1)
        xj = x[j]
        o.A[j, end] = smooth(o.A[j, end], xj * y, γ)    # x'y
        for i in 1:j
            o.A[i, j] = smooth(o.A[i,j], x[i] * xj, γ)  # x'x
        end
    end
    o.A[end] = smooth(o.A[end], y * y, γ)  # y'y
end
value(o::LinReg, args...) = coef(o, args...)
function coef(o::LinReg) 
    o.β[:] = Symmetric(o.A[1:(end-1), 1:(end-1)]) \ o.A[1:(end-1), end]
end
function coef(o::LinReg, λ::Real) 
    o.β[:] = Symmetric(o.A[1:(end-1), 1:(end-1)] + λ*I) \ o.A[1:(end-1), end]
end
function coef(o::LinReg, λ::Vector{<:Real})
    o.β[:] = Symmetric(o.A[1:(end-1), 1:(end-1)] + Diagonal(λ)) \ o.A[1:(end-1), end]
end

predict(o::LinReg, x::AbstractVector) = x'o.β
predict(o::LinReg, x::AbstractMatrix) = x * o.β

function Base.merge!(o::LinReg, o2::LinReg)
    o.n += o2.n
    smooth!(o.A, o2.A, nobs(o2) / nobs(o))
    o
end

# #-----------------------------------------------------------------------# LinRegBuilder
# """
#     LinRegBuilder(p)

# Create an object from which any variable can be regressed on any other set of variables,
# optionally with ridge (`PenaltyFunctions.L2Penalty`) regularization.  The main function
# to use with `LinRegBuilder` is `coef`:

#     coef(o::LinRegBuilder, λ = 0; y=1, x=[2,3,...], bias=true, verbose=false)

# Return the coefficients of a regressing column `y` on columns `x` with ridge (`L2Penalty`) 
# parameter `λ`.  An intercept (`bias`) term is added by default.

# # Examples

#     x = randn(1000, 10)
#     o = LinRegBuilder(10)
#     s = Series(x, o)

#     # let response = x[:, 3]
#     coef(o; y=3, verbose=true) 

#     # let response = x[:, 7], predictors = x[:, [2, 5, 4]]
#     coef(o; y = 7, x = [2, 5, 4]) 

#     # 
# """
# struct LinRegBuilder <: ExactStat{1}
#     A::Matrix{Float64}  #  x'x, pretend that x = [x, 1]
#     function LinRegBuilder(p::Integer) 
#         o = new(Matrix{Float64}(p + 1, p + 1))
#         o.A[end] = 1.0 
#         o
#     end
# end

# function Base.show(io::IO, o::LinRegBuilder) 
#     print(io, "LinRegBuilder of $(size(o.A, 1) - 1) variables")
# end

# fit!(o::LinRegBuilder, y::VectorOb, γ::Float64) = smooth_syr!(o.A, BiasVec(y), γ)

# value(o::LinRegBuilder) = coef(o)

# function coef(o::LinRegBuilder, λ = 0.0; 
#               y = 1, 
#               x = setdiff(1:size(o.A, 2) - 1, y), 
#               bias::Bool = true,
#               verbose::Bool = false
#               )
#     if verbose 
#         s = "Regress $y on $x"
#         if bias 
#             s *= " with bias"
#         end
#         info(s)
#     end
#     if bias 
#         x = vcat(x, size(o.A, 2))
#     end
#     Ainds = vcat(x, y)
#     S = Symmetric(o.A)[Ainds, Ainds]
#     for i in 1:length(x) - bias    
#         S[i, i] += λ
#     end
#     SweepOperator.sweep!(S, 1:length(x))
#     return S[1:length(x), end]
# end

# Base.merge!(o::LinRegBuilder, o2::LinRegBuilder, γ::Float64) = smooth!(o.A, o2.A, γ)
