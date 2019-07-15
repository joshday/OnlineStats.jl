module OnlineStats

using RecipesBase, Reexport, Statistics, LinearAlgebra, Dates
@reexport using OnlineStatsBase

import OnlineStatsBase: name, _fit!, _merge!, bessel, pdf, probs, smooth, smooth!,
    smooth_syr!, eachcol, eachrow

import LearnBase: fit!, nobs, value, predict
import StatsBase: autocov, autocor, confint, skewness, kurtosis, entropy, midpoints,
    fweights, sample, coef, Histogram

using OrderedCollections: OrderedDict
using SweepOperator: sweep!
using LossFunctions: LossFunctions, Loss, L2DistLoss, AggMode
using PenaltyFunctions: PenaltyFunctions, Penalty
using LearnBase: LearnBase, deriv, prox

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
    CallFun, CovMatrix,
    Diff,
    FitBeta, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial, FitMvNormal,
    FastNode, FastTree, FastForest,
    HeatMap, Hist, HyperLogLog,
    IndexedPartition,
    KHist, KMeans,
    Lag, LinReg, LinRegBuilder,
    ModelSchema, Mosaic, MovingTimeWindow, MovingWindow,
    NBClassifier,
    OrderStats,
    Partition, PlotNN, ProbMap, P2Quantile,
    Quantile,
    ReservoirSample,
    StatLearn, StatHistory, StatLag,
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
