module OnlineStats

using Statistics, LinearAlgebra, Dates

import OnlineStatsBase: value, name, _fit!, _merge!, bessel, pdf, probs, smooth, smooth!,
    smooth_syr!, nvars, Weight, eachrow, eachcol
import StatsBase: fit!, nobs, autocov, autocor, confint, skewness, kurtosis, entropy, midpoints,
    fweights, sample, coef, predict, Histogram, ecdf, transform, log1p

using OrderedCollections: OrderedDict

using OnlineStatsBase, RecipesBase

@static if VERSION < v"1.1.0"
    isnothing(x) = x === nothing
end

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
    Series, SGDStat, StatHistory, StatLag, StatLearn, Sum,
    Variance,
# other
    OnlineStat, BiasVec

#-----------------------------------------------------------------------------# utils 
const Tup = Union{Tuple, NamedTuple}
const VectorOb = Union{AbstractVector, Tup}
const TwoThings{T,S} = Union{Tuple{T,S}, Pair{T,S}, NamedTuple{names, Tuple{T,S}}} where names
const XY{T,S} = Union{Tuple{T,S}, Pair{T,S}, NamedTuple{names,Tuple{T,S}}} where {names,T<:AbstractVector{<:Number},S<:Number}

const ϵ = 1e-7  # avoid dividing by 0 in some cases

neighbors(x) = ((x[i], x[i+1]) for i in eachindex(x)[1:end-1])

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

include("stats/histograms.jl")
include("stats/stats.jl")
include("stats/distributions.jl")
include("stats/nbclassifier.jl")
include("stats/fasttree.jl")
include("stats/linreg.jl")
include("stats/kahan.jl")
include("stats/pca.jl")
include("stats/statlearn.jl")
#-----------------------------------------------------------------------------# viz
include("viz/khist.jl")
include("viz/khist2d.jl")
include("viz/partition.jl")
include("viz/mosaicplot.jl")
include("viz/recipes.jl")
include("viz/heatmap.jl")
include("viz/hexlattice.jl")
end
