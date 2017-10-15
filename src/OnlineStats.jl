__precompile__(true)

module OnlineStats

import StatsBase: coef, stderr, vcov, skewness, kurtosis, confint, Histogram, fit!
import OnlineStatsBase: VectorOb, smooth, smooth!, smooth_syr!, ϵ, default_weight, name
import LearnBase: ObsDimension, value
import SweepOperator

using Reexport, RecipesBase
@reexport using OnlineStatsBase, LearnBase, LossFunctions, PenaltyFunctions

export
    # functions
    mapblocks, maprows, confint, coeftable, vcov, mse, stderr,
    # Statlearn and Updaters
    StatLearn,
    SGD, ADAGRAD, ADAM, ADAMAX, NSGD, RMSPROP, ADADELTA, NADAM, OMASQ, OMAPQ, MSPIQ,
    loss, objective, classify, statlearnpath,
    # DistributionStats
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial,
    FitMvNormal


const VecF = Vector{Float64}

#-----------------------------------------------------------------------# mapblocks
@deprecate maprows(f::Function, b::Int, data) mapblocks(f::Function, b::Int, data, Rows())


"""
    mapblocks(f::Function, b::Int, data, dim::ObsDimension = Rows())

Map `data` in batches of size `b` to the function `f`.  If data includes an AbstractMatrix, the batches will be based on rows or columns, depending on `dim`.  Most usage is through Julia's `do` block syntax

# Example

    s = Series(Mean())
    mapblocks(10, randn(100)) do yi
        fit!(s, yi)
        info("nobs: \$(nobs(s))")
    end
"""
function mapblocks(f::Function, b::Integer, y, dim::ObsDimension = Rows())
    n = _nobs(y, dim)
    i = 1
    while i <= n
        rng = i:min(i + b - 1, n)
        yi = getblock(y, rng, dim)
        f(yi)
        i += b
    end
end

_nobs(y::VectorOb, ::ObsDimension) = length(y)
_nobs(y::AbstractMatrix, ::Rows) = size(y, 1)
_nobs(y::AbstractMatrix, ::Cols) = size(y, 2)
function _nobs(y::Tuple{AbstractMatrix, VectorOb}, dim::ObsDimension)
    n = _nobs(first(y), dim)
    if all(_nobs.(y, dim) .== n)
        return n
    else
        error("Data objects have different nobs")
    end
end


getblock(y::VectorOb, rng, ::ObsDimension) = @view y[rng]
getblock(y::AbstractMatrix, rng, ::Rows) = @view y[rng, :]
getblock(y::AbstractMatrix, rng, ::Cols) = @view y[:, rng]
function getblock(y::Tuple{AbstractMatrix, VectorOb}, rng, dim::ObsDimension)
    map(x -> getblock(x, rng, dim), y)
end


#-----------------------------------------------------------------------# source files
include("recipes.jl")
include("distributions.jl")
include("statlearn.jl")
end # module
