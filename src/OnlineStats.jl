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
    maprows, confint, coeftable, vcov, mse, stderr,
    # Statlearn and Updaters
    StatLearn,
    SGD, ADAGRAD, ADAM, ADAMAX, NSGD, RMSPROP, ADADELTA, NADAM,
    OMASQ, OMASQF, OMAPQ, OMAPQF, MSPIC, MSPIF,
    loss, objective, classify, statlearnpath,
    # DistributionStats
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial,
    FitMvNormal

#-----------------------------------------------------------------------------# types
const AA        = AbstractArray
const VecF      = Vector{Float64}
const MatF      = Matrix{Float64}
const AVec{T}   = AbstractVector{T}
const AMat{T}   = AbstractMatrix{T}
const AVecF     = AVec{Float64}
const AMatF     = AMat{Float64}


#---------------------------------------------------------------------------# maprows
rows(x::AbstractVector, rng) = view(x, rng)
rows(x::AbstractMatrix, rng) = view(x, rng, :)

"""
    maprows(f::Function, b::Integer, data...)
Map rows of `data` in batches of size `b`.  Most usage is done through `do` blocks.
    s = Series(Mean())
    maprows(10, randn(100)) do yi
        fit!(s, yi)
        info("nobs: \$(nobs(s))")
    end
"""
function maprows(f::Function, b::Integer, data...)
    n = size(data[1], 1)
    i = 1
    while i <= n
        rng = i:min(i + b - 1, n)
        batch_data = map(x -> rows(x, rng), data)
        f(batch_data...)
        i += b
    end
end


#-----------------------------------------------------------------------# Weight Recipe
@recipe function f(wt::Weight; nobs=50)
    xlab --> "Number of Observations"
    ylab --> "Weight Value"
    label --> OnlineStatsBase.name(wt)
    ylim --> (0, 1)
    w --> 2
    W = deepcopy(wt)
    v = zeros(nobs)
    for i in eachindex(v)
        updatecounter!(W)
        v[i] = weight(W)
    end
    v
end




#-----------------------------------------------------------------------# source files
# include("quantile.jl")
include("distributions.jl")
include("statlearn.jl")
# include("xyinput/linreg.jl")

end # module
