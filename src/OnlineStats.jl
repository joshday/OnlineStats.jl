__precompile__(true)
module OnlineStats

import SweepOperator
import NamedTuples: NamedTuple
import DataStructures: SortedDict
import LearnBase: fit!, value, nobs, predict, transform!, transform
import StatsBase: Histogram, skewness, kurtosis, coef, fweights, pweights, skewness, 
    kurtosis, confint, autocor, autocov, entropy, midpoints, sample
import OnlineStatsBase: OnlineStat, ExactStat, StochasticStat, name, _value, _fit!,
    VectorOb, XyOb, default_weight,
    Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2, 
    HarmonicWeight, McclainWeight, Bounded, Scaled

using Reexport, RecipesBase
@reexport using LossFunctions, PenaltyFunctions

export
    # functions
    fit!, value, nobs, classify, loss, predict, coef, mapblocks, stats, series, mapblocks,
    confint, autocov, autocor, probs,
    # Series and related types
    Series, AugmentedSeries, OnlineStat, Cols, Rows,
    # Weight
    Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2, 
    HarmonicWeight, McclainWeight, Bounded, Scaled,
    # Distributions
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal, 
    FitMultinomial, FitMvNormal,
    # Stats
    Mean, Variance, CStat, CovMatrix, Diff, Extrema, HyperLogLog, KMeans, Moments,
    OrderStats, Quantile, PQuantile, ReservoirSample, Lag, AutoCov, Count, CountMap,
    Sum, LinReg, LinRegBuilder, Hist, AdaptiveBins, CallFun, MV, Bootstrap, 
    NBClassifier, Partition, Group, IndexedPartition, Mosaic, Unique, StumpForest,
    # StatLearn
    StatLearn, SGD, NSGD, ADAGRAD, ADADELTA, RMSPROP, ADAM, ADAMAX, NADAM, OMAP, OMAS, MSPI,
    # ML
    ML


#-----------------------------------------------------------------------# ObLoc
# For OnlineStat{1}
abstract type ObLoc end 
struct Rows <: ObLoc end # Each Row of matrix is an observation
struct Cols <: ObLoc end # Each Col ...

#-----------------------------------------------------------------------# helpers
# (1 - γ) * a + γ * b
smooth(a::Number, b::Number, γ::Number) = a + γ * (b - a)
smooth!(a::Void, b::Void, γ::Number) = a  # help with merging updaters
smooth!(a::Number, b::Number, γ::Number) = smooth(a, b, γ)  # help with merging updaters
function smooth!(a, b, γ::Number)
    length(a) == length(b) || 
        throw(DimensionMismatch("can't smooth arrays of different length"))
    for i in eachindex(a)
        @inbounds a[i] = smooth(a[i], b[i], γ)
    end
end

# Update upper triangle of (1 - γ) * A + γ * x * x'
function smooth_syr!(A::AbstractMatrix, x, γ::Number)
    for j in 1:size(A, 2), i in 1:j
        @inbounds A[i, j] = smooth(A[i,j], x[i] * x[j], γ)
    end
end

unbias(o) = nobs(o) / (nobs(o) - 1)

value(o::OnlineStat, args...; kw...) = _value(o, args...; kw...)
fit!(o::OnlineStat, ob, γ) = _fit!(o, ob, γ)

const ϵ = 1e-6

const VecF = Vector{Float64}

#-----------------------------------------------------------------------# includes
include("utilities/biasvec.jl")
include("utilities/mapblocks.jl")
include("stats/updaters.jl")
include("stats/stats.jl")
include("stats/linregbuilder.jl")
include("stats/histograms.jl")
include("stats/mv.jl")
include("stats/distributions.jl")
include("stats/statlearn.jl")
include("stats/wrappers.jl")
include("stats/naivebayes.jl")
include("stats/decisiontree.jl")
include("stats/mlschema.jl")
include("stats/stumpforest.jl")
include("stats/experimental.jl")
include("visualizations/partition.jl")
include("visualizations/mosaic.jl")
include("series.jl")
include("visualizations/recipes.jl")

end # module
