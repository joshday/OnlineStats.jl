__precompile__(true)
module OnlineStats 

using Compat
using Compat.LinearAlgebra
using Compat.Printf
using RecipesBase

using Reexport 
@reexport using OnlineStatsBase, LossFunctions, PenaltyFunctions, LearnBase

import OnlineStatsBase: OnlineStat, name, _fit!
import LearnBase: fit!, nobs, value, predict, transform, transform!
import StatsBase: autocov, autocor, confint, skewness, kurtosis, entropy, midpoints, 
    fweights, sample, coef, Histogram
import DataStructures: OrderedDict, CircularBuffer
import NamedTuples  # Remove in 0.7
import SweepOperator

export 
# functions 
    fit!, nobs, value, autocov, autocor, predict, confint, probs, skewness, kurtosis,
    eachcol, eachrow, classify, coef, transform, transform!, stats, series,
# weights 
    EqualWeight, ExponentialWeight, LearningRate, LearningRate2, HarmonicWeight, 
    McclainWeight, Bounded, Scaled,
# algorithms 
    ADAGRAD, ADAM, ADAMAX, ADADELTA, MSPI, OMAS, OMAP, RMSPROP, SGD,
# stats
    AutoCov,
    Bootstrap,
    CallFun, Count, CountMap, CovMatrix, CStat,
    Diff,
    Extrema,
    FitBeta, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial, FitMvNormal,
    FastNode, FastTree, FastForest, FTSeries, 
    Group, GroupBy,
    Hist, HyperLogLog,
    Ignored, IndexedPartition,
    KMeans,
    Lag, LinReg, LinRegBuilder,
    Mean, ModelSchema, Moments, Mosaic,
    NBClassifier,
    OrderStats,
    Partition, PlotNN, ProbMap, P2Quantile,
    Quantile,
    ReservoirSample,
    Series, StatLearn, StatHistory, Sum,
    Variance,
# other 
    OnlineStat, BiasVec

input(o::OnlineStat{T}) where {T} = T

include("utils.jl")
include("algorithms.jl")
include("stats/stats.jl")
include("stats/distributions.jl")
include("stats/hist.jl")
include("stats/ml.jl")
include("stats/nbclassifier.jl")
include("stats/fasttree.jl")
include("stats/linreg.jl")
include("stats/statlearn.jl")
include("viz/partition.jl")
include("viz/mosaicplot.jl")
include("viz/recipes.jl")
include("viz/plotbivariate.jl")
end
