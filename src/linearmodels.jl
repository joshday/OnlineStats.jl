"""
    LinearModels(p)

Create an object from which any variable can be regressed on any other set of variables.

# Example

    x = randn(1000, 10)
    o = LinearModels(10)
    s = Series(x, o)
    # let response = x[:, 3], predictors = x[:, setdiff(1:10, 3)]
    coef(o, 3)
"""
struct LinearModels <: OnlineStat{1, EqualWeight}
    A::Matrix{Float64}
    S::Matrix{Float64}
    LinearModels(p::Integer) = new(Matrix{Float64}(p, p), Matrix{Float64}(p, p))
end

function Base.show(io::IO, o::LinearModels) 
    print(io, "LinearModels: β(y=last col) = $(coef(o))")
end

fit!(o::LinearModels, y::VectorOb, γ::Float64) = smooth_syr!(o.A, y, γ)

value(o::LinearModels) = coef(o)

function coef(o::LinearModels, yind::Integer = size(o.A, 2); verbose::Bool = true)
    inds = setdiff(1:size(o.A, 1), yind)
    Ainds = vcat(inds, yind)
    copy!(o.S, Symmetric(o.A)[Ainds, Ainds])
    verbose && info("Regress var $yind on ", inds)
    SweepOperator.sweep!(o.S, 1:length(inds))
    return o.S[1:length(inds), end]
end

# TODO: coef methods where x is also specified
# TODO: incorporation with PenaltyFunctions
# TODO: be able to generate Convex.jl Problem
# TODO: be able to geenrate JuMP.jl Model