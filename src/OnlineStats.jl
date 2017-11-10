__precompile__(true)
module OnlineStats

import SweepOperator
import LearnBase: fit!, value, nobs, predict
import StatsBase: Histogram, skewness, kurtosis, coef, fweights, skewness, kurtosis, confint
import OnlineStatsBase: OnlineStat, ExactStat, StochasticStat, name, _value,
    ScalarOb, VectorOb, XyOb, Data, default_weight,
    Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2, 
    HarmonicWeight, McclainWeight, Bounded, Scaled

using Reexport, RecipesBase
@reexport using LossFunctions, PenaltyFunctions

export
    fit!, value, nobs, classify, loss, predict, coef, mapblocks, stats,
    Series, OnlineStat, Cols, Rows, mapblocks, confint,
    # Weight
    Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2, 
    HarmonicWeight, McclainWeight, Bounded, Scaled,
    # Distributions
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal, 
    FitMultinomial, FitMvNormal,
    # Stats
    Mean, Variance, CStat, CovMatrix, Diff, Extrema, HyperLogLog, KMeans, Moments,
    OrderStats, QuantileMM, QuantileMSPI, QuantileSGD, ReservoirSample, Sum,
    LinReg, LinRegBuilder, IHistogram, OHistogram, CallFun, MV, Bootstrap,
    # StatLearn
    StatLearn, SGD, NSGD, ADAGRAD, ADADELTA, RMSPROP, ADAM, ADAMAX, NADAM, OMAPQ,
    OMASQ, MSPIQ


#-----------------------------------------------------------------------# ObLoc
abstract type ObLoc end 
struct Rows <: ObLoc end 
struct Cols <: ObLoc end

#-----------------------------------------------------------------------# helpers
smooth(x, y, γ) = x + γ * (y - x)

function smooth!(x, y, γ)
    length(x) == length(y) || 
        throw(DimensionMismatch("can't smooth arrays of different length"))
    for i in eachindex(x)
        @inbounds x[i] = smooth(x[i], y[i], γ)
    end
end

function smooth_syr!(A::AbstractMatrix, x, γ::Float64)
    size(A, 1) == length(x) || throw(DimensionMismatch())
    for j in 1:size(A, 2), i in 1:j
        @inbounds A[i, j] = (1.0 - γ) * A[i, j] + γ * x[i] * x[j]
    end
end

unbias(o) = o.nobs / (o.nobs - 1)

value(o::OnlineStat) = _value(o)

const ϵ = 1e-6

const VecF = Vector{Float64}
const AVecF = AbstractVector{Float64}

#-----------------------------------------------------------------------# includes
include("stats/stats.jl")
include("stats/linregbuilder.jl")
include("stats/histograms.jl")
include("stats/mv.jl")
include("stats/distributions.jl")
include("stats/statlearn.jl")
include("stats/experimental.jl")
include("stats/bootstrap.jl")
include("series.jl")
include("mapblocks.jl")
include("recipes.jl")

end # module
