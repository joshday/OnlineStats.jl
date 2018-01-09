__precompile__(true)
module OnlineStats

import SweepOperator
import LearnBase: fit!, value, nobs, predict
import StatsBase: Histogram, skewness, kurtosis, coef, fweights, skewness, kurtosis, 
    confint, autocor, autocov, entropy
import OnlineStatsBase: OnlineStat, ExactStat, StochasticStat, name, _value, _fit!,
    ScalarOb, VectorOb, XyOb, Data, default_weight,
    Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2, 
    HarmonicWeight, McclainWeight, Bounded, Scaled

using Reexport, RecipesBase
@reexport using LossFunctions, PenaltyFunctions

export
    fit!, value, nobs, classify, loss, predict, coef, mapblocks, stats,
    Series, OnlineStat, Cols, Rows, mapblocks, confint, autocov, autocor,
    # Weight
    Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2, 
    HarmonicWeight, McclainWeight, Bounded, Scaled,
    # Distributions
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal, 
    FitMultinomial, FitMvNormal,
    # Stats
    Mean, Variance, CStat, CovMatrix, Diff, Extrema, HyperLogLog, KMeans, Moments,
    OrderStats, Quantile, PQuantile, ReservoirSample, Lag, AutoCov, Count, CountMap,
    Sum, LinReg, LinRegBuilder, IHistogram, OHistogram, Hist, CallFun, MV, Bootstrap, 
    NBClassifier, Partition, Group, PartitionX,
    # StatLearn
    StatLearn, SGD, NSGD, ADAGRAD, ADADELTA, RMSPROP, ADAM, ADAMAX, NADAM, OMAP, OMAS, MSPI


#-----------------------------------------------------------------------# ObLoc
# if an OnlineStat{1} is given a matrix, are observations in rows or cols
abstract type ObLoc end 
struct Rows <: ObLoc end 
struct Cols <: ObLoc end

#-----------------------------------------------------------------------# helpers
# (1 - γ) * a + γ * b
smooth(a::Number, b::Number, γ::Float64) = a + γ * (b - a)
smooth!(a::Void, b::Void, γ::Float64) = a  # help with merging updaters
smooth!(a::Number, b::Number, γ::Float64) = smooth(a, b, γ)  # help with merging updaters
function smooth!(a, b, γ::Float64)
    length(a) == length(b) || 
        throw(DimensionMismatch("can't smooth arrays of different length"))
    for i in eachindex(a)
        @inbounds a[i] = smooth(a[i], b[i], γ)
    end
end

# (1 - γ) * A + γ * x * x'
# TODO: make generated function for the sake of NamedTuples
function smooth_syr!(A::AbstractMatrix, x, γ::Float64)
    size(A, 1) == length(x) || 
        throw(DimensionMismatch("smooth_syr! matrix/vector mismatch: $(size(A, 1)) and $(length(x))"))
    for j in 1:size(A, 2), i in 1:j
        @inbounds A[i, j] = (1.0 - γ) * A[i, j] + γ * x[i] * x[j]
    end
end

unbias(o) = o.nobs / (o.nobs - 1)

value(o::OnlineStat) = _value(o)
fit!(o::OnlineStat, ob, γ::Float64) = _fit!(o, ob, γ)

const ϵ = 1e-6

const VecF = Vector{Float64}
const AVecF = AbstractVector{Float64}

#-----------------------------------------------------------------------# includes
include("stats/updaters.jl")
include("stats/stats.jl")
include("stats/biasvec.jl")
include("stats/linregbuilder.jl")
include("stats/histograms.jl")
include("stats/mv.jl")
include("stats/distributions.jl")
include("stats/statlearn.jl")
include("stats/experimental.jl")
include("stats/bootstrap.jl")
include("stats/naivebayes.jl")
include("stats/decisiontree.jl")
include("stats/partition.jl")
include("series.jl")
include("mapblocks.jl")
include("recipes.jl")

end # module
