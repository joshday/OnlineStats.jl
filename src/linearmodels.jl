"""
    LinearModels(p)

Create an object from which any variable can be regressed on any other set of variables.

# Example

    x = randn(1000, 10)
    o = LinearModels(10)
    s = Series(x, o)

    # let response = x[:, 3], predictors = x[:, setdiff(1:10, 3)]
    coef(o, 3) 

    # let response = x[:, 7], predictors = x[:, [2, 5, 4]]
    coef(o, 7, [2, 5, 4]) 
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

function coef(o::LinearModels, yind::Integer = size(o.A, 2), 
        xinds::AbstractVector{<:Integer} = setdiff(1:size(o.A, 2), yind); 
        verbose::Bool = true)
    Ainds = vcat(xinds, yind)
    d = length(Ainds)
    # make top left square of S the matrix to sweep on: [x y]' * [x y]
    @views copy!(o.S[1:d, 1:d], Symmetric(o.A)[Ainds, Ainds])
    verbose && info("Regress var $yind on $xinds")
    SweepOperator.sweep!(o.S, 1:(d-1))
    return o.S[1:(d-1), end]
end

# TODO: incorporation with PenaltyFunctions
# TODO: be able to generate Convex.jl Problem
# TODO: be able to geenrate JuMP.jl Model