__precompile__(true)

module OnlineStats

import StatsBase: coef, stderr, vcov, skewness, kurtosis, confint, Histogram, fit!
import OnlineStatsBase: ScalarOb, VectorOb, smooth, smooth!, smooth_syr!, ϵ,
    default_weight, name, mapblocks
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
    FitMvNormal,
    # Other
    LinRegBuilder

const VecF = Vector{Float64}


#-----------------------------------------------------------------------# source files
include("recipes.jl")
include("distributions.jl")
include("statlearn.jl")
include("linregbuilder.jl")
end # module
