module OnlineStats 

using Compat
using Compat.LinearAlgebra

using Reexport 
@reexport using OnlineStatsBase, LossFunctions, PenaltyFunctions, LearnBase

import OnlineStatsBase: OnlineStat, name, value, _fit!
import LearnBase: fit!, nobs, value, predict
import StatsBase: autocov, autocor, confint, skewness, kurtosis, entropy, midpoints, 
    fweights, sample, coef
import DataStructures: OrderedDict
import NamedTuples  # Remove in 0.7
import SpecialFunctions

export 
# functions 
    fit!, nobs, value, autocov, autocor, predict, confint, probs, skewness, kurtosis,
    eachcol, eachrow, classify, coef,
# weights 
    EqualWeight, ExponentialWeight, LearningRate, LearningRate2, HarmonicWeight, 
    McclainWeight, Bounded, Scaled,
# updaters 
    ADAGRAD, ADAM, MSPI, SGD,
# stats
    AutoCov,
    Bootstrap,
    CallFun, Count, CountMap, CovMatrix, CStat,
    Diff,
    Extrema,
    FitBeta, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial, FitMvNormal,
    FastNode, FastTree, FastForest, FTSeries, 
    Group,
    Hist, HyperLogLog,
    KMeans,
    Lag, LinReg,
    Mean, Moments,
    NBClassifier,
    OrderStats,
    ProbMap, P2Quantile,
    Quantile,
    ReservoirSample,
    Series, Sum,
    Variance,
# other 
    BiasVec

include("utils.jl")
include("algorithms.jl")
include("stats/stats.jl")
include("stats/distributions.jl")
include("stats/hist.jl")
include("stats/nbclassifier.jl")
include("stats/fasttree.jl")
include("stats/linreg.jl")
# include("stats/statlearn.jl")



#-----------------------------------------------------------------------# includes
# include("stats/algorithms.jl")
# include("stats/stats.jl")
# include("stats/wrappers.jl")
# include("stats/group.jl")
# include("stats/distributions.jl")
end

# __precompile__(true)
# module OnlineStats

# import SweepOperator
# import NamedTuples
# import DataStructures: SortedDict, OrderedDict
# import LearnBase: fit!, value, nobs, predict, transform!, transform
# import StatsBase: Histogram, skewness, kurtosis, coef, fweights, pweights, skewness, 
#     kurtosis, confint, autocor, autocov, entropy, midpoints, sample
# import OnlineStatsBase: OnlineStat, ExactStat, StochasticStat, name, _value, _fit!,
#     VectorOb, XyOb, default_weight, value, fit!,
#     Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2, 
#     HarmonicWeight, McclainWeight, Bounded, Scaled

# using Reexport, RecipesBase
# @reexport using LossFunctions, PenaltyFunctions

# export
#     # functions
#     fit!, value, nobs, classify, loss, predict, coef, mapblocks, stats, series, mapblocks,
#     confint, autocov, autocor, probs,
#     # Series and related types
#     Series, AugmentedSeries, OnlineStat, Cols, Rows,
#     # Weight
#     Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2, 
#     HarmonicWeight, McclainWeight, Bounded, Scaled,
#     # Distributions
#     FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal, 
#     FitMultinomial, FitMvNormal,
#     # Stats
#     Mean, Variance, CStat, CovMatrix, Diff, Extrema, HyperLogLog, KMeans, Moments,
#     OrderStats, Quantile, PQuantile, ReservoirSample, Lag, AutoCov, Count, CountMap,
#     Sum, LinReg, LinRegBuilder, Hist, AdaptiveBins, CallFun, MV, Bootstrap, ProbMap,
#     NBClassifier, Partition, Group, IndexedPartition, Mosaic, Unique,
#     # Tree stuff
#     FastNode, FastTree, FastForest,
#     NaiveBayesClassifier, NBC, NBNode, NBTree,
#     # StatLearn
#     StatLearn, SGD, NSGD, ADAGRAD, ADADELTA, RMSPROP, ADAM, ADAMAX, NADAM, OMAP, OMAS, MSPI,
#     # ML
#     ML


# #-----------------------------------------------------------------------# ObLoc
# # For OnlineStat{1}
# abstract type ObLoc end 
# struct Rows <: ObLoc end # Each Row of matrix is an observation
# struct Cols <: ObLoc end # Each Col ...

# #-----------------------------------------------------------------------# helpers
# # (1 - γ) * a + γ * b
# smooth(a::Number, b::Number, γ::Number) = a + γ * (b - a)
# smooth!(a::Void, b::Void, γ::Number) = a  # help with merging updaters
# smooth!(a::Number, b::Number, γ::Number) = smooth(a, b, γ)  # help with merging updaters
# function smooth!(a, b, γ::Number)
#     length(a) == length(b) || 
#         throw(DimensionMismatch("can't smooth arrays of different length"))
#     for i in eachindex(a)
#         @inbounds a[i] = smooth(a[i], b[i], γ)
#     end
# end

# # Update upper triangle of (1 - γ) * A + γ * x * x'
# function smooth_syr!(A::AbstractMatrix, x, γ::Number)
#     for j in 1:size(A, 2), i in 1:j
#         @inbounds A[i, j] = smooth(A[i,j], x[i] * x[j], γ)
#     end
# end

# unbias(o) = nobs(o) / (nobs(o) - 1)

# function Base.merge(v::AbstractVector{<:OnlineStat})
#     o = copy(v[1])
#     for (i, o2) in enumerate(v[2:end])
#         merge!(o, o2, 1 / (i + 1))
#     end
#     o
# end

# const ϵ = 1e-6

# const Tup = Union{Tuple, NamedTuples.NamedTuple}

# #-----------------------------------------------------------------------# includes
# include("utilities/biasvec.jl")
# include("utilities/mapblocks.jl")
# include("stats/updaters.jl")
# include("stats/stats.jl")
# include("stats/linregbuilder.jl")
# include("stats/histograms.jl")
# include("stats/group.jl")
# include("stats/distributions.jl")
# include("stats/statlearn.jl")
# include("stats/wrappers.jl")
# include("stats/naivebayes.jl")
# include("stats/decisiontree.jl")
# include("stats/mlschema.jl")
# include("stats/experimental.jl")
# include("visualizations/partition.jl")
# include("visualizations/mosaic.jl")
# include("series.jl")
# include("visualizations/recipes.jl")

# end # module
