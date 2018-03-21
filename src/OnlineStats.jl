module OnlineStats 

using Compat
using Compat.LinearAlgebra
using Compat.Printf

using Reexport 
@reexport using OnlineStatsBase, LossFunctions, PenaltyFunctions, LearnBase

import OnlineStatsBase: OnlineStat, name, value, _fit!
import LearnBase: fit!, nobs, value, predict
import StatsBase: autocov, autocor, confint, skewness, kurtosis, entropy, midpoints, 
    fweights, sample, coef
import DataStructures: OrderedDict
import NamedTuples  # Remove in 0.7
import SpecialFunctions
import SweepOperator

export 
# functions 
    fit!, nobs, value, autocov, autocor, predict, confint, probs, skewness, kurtosis,
    eachcol, eachrow, classify, coef,
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
    Group,
    Hist, HyperLogLog,
    KMeans,
    Lag, LinReg, LinRegBuilder,
    Mean, Moments,
    NBClassifier,
    OrderStats,
    ProbMap, P2Quantile,
    Quantile,
    ReservoirSample,
    Series, StatLearn, Sum,
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
include("stats/statlearn.jl")
include("stats/ml.jl")
include("viz/partition.jl")
end
