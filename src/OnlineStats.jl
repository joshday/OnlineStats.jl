module OnlineStats

using RecipesBase, Statistics, LinearAlgebra, Dates

import OnlineStatsBase: value, name, _fit!, _merge!, bessel, pdf, probs, smooth, smooth!,
    smooth_syr!, nvars, Weight, eachrow, eachcol

import StatsBase: fit!, nobs, autocov, autocor, confint, skewness, kurtosis, entropy, midpoints,
    fweights, sample, coef, predict, Histogram, ecdf, transform

using OrderedCollections: OrderedDict
using LossFunctions: LossFunctions, Loss, L2DistLoss, AggMode
using PenaltyFunctions: PenaltyFunctions, Penalty
using LearnBase: LearnBase, deriv, prox
using OnlineStatsBase

export
# Statistics
    mean, var, std, cov, cor, 
# functions
    fit!, nobs, value, autocov, autocor, predict, confint, probs, skewness, kurtosis,
    classify, coef, ecdf, transform, eachrow, eachcol,
# weights
    EqualWeight, ExponentialWeight, LearningRate, LearningRate2, HarmonicWeight,
    McclainWeight, Bounded, Scaled,
# algorithms
    ADAGRAD, ADAM, ADAMAX, ADADELTA, MSPI, OMAS, OMAP, RMSPROP, SGD,
# stats
    AutoCov,
    Bootstrap,
    CallFun, Counter, CountMap, CountMissing, CovMatrix, CCIPCA,
    Diff,
    Extrema, ExpandingHist,
    FitBeta, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial, FitMvNormal,
    FastNode, FastTree, FastForest, FTSeries,
    GradientCore, Group, GroupBy,
    HeatMap, Hist, HyperLogLog,
    IndexedPartition,
    KHist, KHist2D, KMeans, KahanSum, KahanMean, KahanVariance, KIndexedPartition,
    Lag, LinReg, LinRegBuilder,
    Mean, Moments, ModelSchema, Mosaic, MovingTimeWindow, MovingWindow,
    NBClassifier,
    OrderStats,
    Part, Partition, PlotNN, ProbMap, P2Quantile,
    Quantile,
    ReservoirSample,
    Series, SGDStat, StatLearn, StatHistory, StatLag, Sum,
    Variance,
# other
    OnlineStat, BiasVec

include("utils.jl")
include("algorithms.jl")

include("stats/stats.jl")
include("stats/distributions.jl")
include("stats/histograms.jl")
include("stats/nbclassifier.jl")
include("stats/fasttree.jl")
include("stats/linreg.jl")
include("stats/statlearn.jl")
include("stats/kahan.jl")
include("stats/pca.jl")

include("viz/khist.jl")
include("viz/khist2d.jl")
include("viz/partition.jl")
include("viz/mosaicplot.jl")
include("viz/recipes.jl")
include("viz/heatmap.jl")
include("viz/hexlattice.jl")
end
