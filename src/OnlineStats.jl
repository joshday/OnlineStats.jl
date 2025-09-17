module OnlineStats

using Statistics, LinearAlgebra, Dates

import OnlineStatsBase: value, name, _fit!, _merge!, bessel, pdf, probs, smooth, smooth!,
    smooth_syr!, nvars, Weight, eachrow, eachcol, TwoThings, Extrema
import StatsBase: fit!, nobs, autocov, autocor, confint, skewness, kurtosis, entropy, midpoints,
    fweights, sample, coef, predict, Histogram, ecdf, transform, log1p
import StatsFuns: logsumexp
import SpecialFunctions: loggamma
import Distributions: MixtureModel, TDist

import AbstractTrees: AbstractTrees

using OrderedCollections: OrderedDict

using OnlineStatsBase, RecipesBase
using OnlineStatsBase: neighbors
import OnlineStatsBase: name

export
# Statistics
    mean, var, std, cov, cor,
# functions
    fit!, nobs, value, autocov, autocor, predict, confint, probs, skewness, kurtosis,
    classify, coef, ecdf, eachrow, eachcol,
# weights
    EqualWeight, ExponentialWeight, LearningRate, LearningRate2, HarmonicWeight,
    McclainWeight, Bounded, Scaled,
# algorithms
    ADAGRAD, ADAM, ADAMAX, ADADELTA, MSPI, OMAS, OMAP, RMSPROP, SGD,
# stats
    Ash,
    AutoCov,
    Bootstrap,
    CallFun, Counter, CountMap, CountMinSketch, CountMissing, CovMatrix, CCIPCA,
    Diff,
    Extrema, ExpandingHist,
    FitBeta, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial, FitMvNormal,
    FastNode, FastTree, FastForest,
    GeometricMean,
    Group, GroupBy,
    HeatMap, Hist, HyperLogLog,
    IndexedPartition,
    KHist, KHist2D, KMeans, KahanSum, KahanMean, KahanVariance, KIndexedPartition,
    Lag, LinReg, LinRegBuilder, LogSumExp,
    Mean, Moments, ModelSchema, Mosaic, MovingTimeWindow, MovingWindow,
    NBClassifier,
    OrderStats,
    Part, Partition, PlotNN, ProbMap, P2Quantile,
    Quantile,
    ReservoirSample,
    Series, SGDStat, StatLag, StatLearn, Sum,
    Trace,
    Variance,
    DPMM,
# other
    OnlineStat, BiasVec

#-----------------------------------------------------------------------------# utils
const Tup{T} = Union{NTuple{N,T} where {N}, NamedTuple{names, Tuple{N,<:T} where {N}} where {names}}
const VectorOb{T} = Union{AbstractVector{<:T}, Tup{T}}
const XY{T,S} = Union{Tuple{T,S}, Pair{T,S}, NamedTuple{names,Tuple{T,S}}} where {names,T<:VectorOb{Number},S<:Number}

const ϵ = 1e-7  # avoid dividing by 0 in some cases

function searchsortednearest(a, x)
    idx = searchsortedfirst(a, x)
    idx == 1 && return idx
    idx > length(a) && return length(a)
    a[idx] == x && return idx
    return abs(a[idx] - x) < abs(a[idx - 1] - x) ? idx : idx - 1
end

#-----------------------------------------------------------------------# BiasVec
"""
    BiasVec(x)

Lightweight wrapper of a vector which adds a bias/intercept term at the end.

# Example

    BiasVec(rand(5))
"""
struct BiasVec{T, A <: VectorOb} <: AbstractVector{T}
    x::A
    bias::T
end
BiasVec(x::AbstractVector{T}) where {T} = BiasVec(x, one(T))
BiasVec(x::Tup) = BiasVec(x, one(typeof(first(x))))

Base.length(v::BiasVec) = length(v.x) + 1
Base.size(v::BiasVec) = (length(v), )
Base.getindex(v::BiasVec, i::Int) = i > length(v.x) ? v.bias : v.x[i]
Base.IndexStyle(::Type{<:BiasVec}) = IndexLinear()

#-----------------------------------------------------------------------------# stats
include("algorithms.jl")

include("stats/probabilistic.jl")
include("stats/histograms.jl")
include("stats/stats.jl")
include("stats/distributions.jl")
include("stats/nbclassifier.jl")
include("stats/fasttree.jl")
include("stats/linreg.jl")
include("stats/kahan.jl")
include("stats/pca.jl")
include("stats/statlearn.jl")
include("stats/trace.jl")
include("stats/dpmm.jl")
#-----------------------------------------------------------------------------# viz
include("viz/khist.jl")
include("viz/khist2d.jl")
include("viz/partition.jl")
include("viz/mosaicplot.jl")
include("viz/heatmap.jl")
include("viz/recipes.jl")
include("viz/hexlattice.jl")
include("viz/ash.jl")
end
