module OnlineStats

using RecipesBase, Reexport, Statistics, LinearAlgebra, Dates
@reexport using OnlineStatsBase, LossFunctions, PenaltyFunctions, LearnBase

import OnlineStatsBase: OnlineStat, name, _fit!, _merge!, eachrow, smooth, smooth!, pdf,
    probs, smooth_syr!, bessel, Extrema, StatCollection, Mean, Variance, Series, FTSeries
import LearnBase: fit!, nobs, value, predict
import StatsBase: autocov, autocor, confint, skewness, kurtosis, entropy, midpoints,
    fweights, sample, coef, Histogram

using OrderedCollections: OrderedDict
using SweepOperator: sweep!

export
# Statistics
    mean, var, std, cov, cor,
# functions
    fit!, nobs, value, autocov, autocor, predict, confint, probs, skewness, kurtosis,
    classify, coef, stats, series,
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
    HeatMap, Hist, HyperLogLog,
    IndexedPartition,
    KHist, KMeans,
    Lag, LinReg, LinRegBuilder,
    Mean, ModelSchema, Moments, Mosaic, MovingTimeWindow, MovingWindow,
    NBClassifier,
    OrderStats,
    Partition, PlotNN, ProbMap, P2Quantile,
    Quantile,
    ReservoirSample,
    Series, StatLearn, StatHistory, StatLag, Sum,
    Variance,
    KahanSum, KahanMean, KahanVariance,
# other
    OnlineStat, BiasVec

input(o::OnlineStat{T}) where {T} = T

include("utils.jl")
include("algorithms.jl")
include("stats/stats.jl")
include("stats/distributions.jl")
include("stats/histograms.jl")
include("stats/ml.jl")
include("stats/nbclassifier.jl")
include("stats/fasttree.jl")
include("stats/linreg.jl")
include("stats/statlearn.jl")
include("stats/kahan.jl")
include("viz/partition.jl")
include("viz/mosaicplot.jl")
include("viz/recipes.jl")
include("viz/heatmap.jl")
include("viz/plotbivariate.jl")
end
