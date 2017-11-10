#-----------------------------------------------------------------------# LinReg
"""
    LinReg(p, λ::Float64 = 0.0)  # use λ for all parameters
    LinReg(p, λfactor::Vector{Float64})

Ridge regression of `p` variables with elementwise regularization.

# Example

    x = randn(100, 10)
    y = x * linspace(-1, 1, 10) + randn(100)
    o = LinReg(10)
    Series((x,y), o)
    value(o)
"""
mutable struct LinReg <: ExactStat{(1,0)}
    β::Vector{Float64}
    A::Matrix{Float64}
    λfactor::Vector{Float64}
    nobs::Int
    function LinReg(p::Integer, λfactor::Vector{Float64} = zeros(p))
        d = p + 1
        new(zeros(p), zeros(d, d), λfactor, 0)
    end
    LinReg(p::Integer, λ::Float64) = LinReg(p, fill(λ, p))
end
Base.show(io::IO, o::LinReg) = print(io, "LinReg: β($(mean(o.λfactor))) = $(value(o)')")
nobs(o::LinReg) = o.nobs

function matviews(o::LinReg)
    p = length(o.β)
    @views o.A[1:p, 1:p], o.A[1:p, end]
end

function fit!(o::LinReg, x::VectorOb, y::Real, γ::Float64)
    xtx, xty = matviews(o)
    smooth_syr!(xtx, x, γ)
    smooth!(xty, x .* y, γ)
    o.A[end] = smooth(o.A[end], y * y, γ)
    o.nobs += 1
end

function _value(o::LinReg)
    xtx, xty = matviews(o)
    A = Symmetric(xtx + Diagonal(o.λfactor))
    if isposdef(A)
        o.β[:] = A \ xty
    end
    return o.β
end

coef(o::LinReg) = value(o)
predict(o::LinReg, x::AbstractVector) = x'coef(o)
predict(o::LinReg, x::AbstractMatrix, dim::Rows = Rows()) = x * coef(o)
predict(o::LinReg, x::AbstractMatrix, dim::Cols) = x'coef(o)

function Base.merge!(o1::LinReg, o2::LinReg, γ::Float64)
    o1.λfactor == o2.λfactor || error("Merge failed. LinReg objects have different λfactor")
    smooth!(o1.A, o2.A, γ)
    o1.nobs += o2.nobs
    coef(o1)
    o1
end

#-----------------------------------------------------------------------# LinRegBuilder
"""
    LinRegBuilder(p)

Create an object from which any variable can be regressed on any other set of variables.

# Example

    x = randn(1000, 10)
    o = LinRegBuilder(10)
    s = Series(x, o)

    # let response = x[:, 3], predictors = x[:, setdiff(1:10, 3)]
    coef(o, 3) 

    # let response = x[:, 7], predictors = x[:, [2, 5, 4]]
    coef(o, 7, [2, 5, 4]) 
"""
struct LinRegBuilder <: ExactStat{1}
    A::Matrix{Float64}  #  x'x
    LinRegBuilder(p::Integer) = new(Matrix{Float64}(p, p))
end

function Base.show(io::IO, o::LinRegBuilder) 
    print(io, "LinRegBuilder: β(y=last col) = $(coef(o))")
end

fit!(o::LinRegBuilder, y::VectorOb, γ::Float64) = smooth_syr!(o.A, y, γ)

_value(o::LinRegBuilder) = coef(o)

function coef(o::LinRegBuilder, yind::Integer = size(o.A, 2), 
        xinds::AbstractVector{<:Integer} = setdiff(1:size(o.A, 2), yind); 
        verbose::Bool = false)
    Ainds = vcat(xinds, yind)
    d = length(Ainds)
    S = Symmetric(o.A)[Ainds, Ainds]
    verbose && info("Regress var $yind on $xinds")
    SweepOperator.sweep!(S, 1:length(xinds))
    return S[1:length(xinds), end]
end

function Base.merge!(o::LinRegBuilder, o2::LinRegBuilder, γ::Float64)
    smooth!(o.A, o2.A, γ)
end

# TODO: incorporation with PenaltyFunctions
# TODO: be able to generate Convex.jl Problem
# TODO: be able to geenrate JuMP.jl Model