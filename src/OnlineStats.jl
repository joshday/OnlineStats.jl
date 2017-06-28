module OnlineStats


import StatsBase: nobs, fit!, skewness, kurtosis, confint, predict, coef, coeftable,
    CoefTable, stderr, vcov
importall OnlineStatsBase, LearnBase, LossFunctions, PenaltyFunctions
import SweepOperator, Distributions
Ds = Distributions

using OnlineStatsBase, LearnBase, LossFunctions, PenaltyFunctions, RecipesBase


export
    # OnlineStatMeta
    Series, Bootstrap,
    # Weight
    Weight, EqualWeight, BoundedEqualWeight, ExponentialWeight, LearningRate, LearningRate2,
    McclainWeight,
    # functions
    maprows, nups, stats, replicates, nobs, fit!, value, confint, predict, coef, coeftable,
    vcov, mse, stderr,
    # OnlineStats
    OnlineStat,
    Mean, Variance, Extrema, OrderStats, Moments, QuantileSGD, QuantileMM, QuantileISGD,
    Diff, Sum, MV, CovMatrix, KMeans, LinReg, StochasticLoss, ReservoirSample,
    # statlearn things
    StatLearn, SPGD, MAXSPGD, ADAGRAD, ADAM, ADAMAX, MMXTX, loss, objective, classify,
    statlearnpath,
    # DistributionStats
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial,
    FitMvNormal, NormalMix,
    # StreamStats
    HyperLogLog,
    # Other
    ObsDim

#-----------------------------------------------------------------------------# types
# 0 = scalar, 1 = vector, 2 = matrix, -1 = unknown, or Ds.Distribution
abstract type StochasticStat{I, O} <: OnlineStat{I, O} end

const AA        = AbstractArray
const VecF      = Vector{Float64}
const MatF      = Matrix{Float64}
const AVec{T}   = AbstractVector{T}
const AMat{T}   = AbstractMatrix{T}
const AVecF     = AVec{Float64}
const AMatF     = AMat{Float64}

include("show.jl")

#---------------------------------------------------------------------------# helpers
can_be_exact(o::OnlineStat) = default_weight(o) == EqualWeight()

value(o::OnlineStat) = getfield(o, fieldnames(o)[1])
Base.copy(o::OnlineStat) = deepcopy(o)
Base.merge{T <: OnlineStat}(o::T, o2::T, wt::Float64) = merge!(copy(o), o2, wt)
unbias(o) = o.nobs / (o.nobs - 1)

smooth(m::Float64, v::Real, γ::Float64) = m + γ * (v - m)
function smooth!(m::AbstractArray, v::AbstractArray, γ::Float64)
    length(m) == length(v) || throw(DimensionMismatch())
    for i in eachindex(v)
        @inbounds m[i] = smooth(m[i], v[i], γ)
    end
end
function smooth_syr!(A::AMat, x::AVec, γ::Float64)
    size(A, 1) == length(x) || throw(DimensionMismatch())
    for j in 1:size(A, 2), i in 1:j
        @inbounds A[i, j] = (1.0 - γ) * A[i, j] + γ * x[i] * x[j]
    end
end
function smooth_syrk!(A::MatF, x::AMat, γ::Float64)
    BLAS.syrk!('U', 'T', γ / size(x, 1), x, 1.0 - γ, A)
end

const ϵ = 1e-8  # epsilon used in special cases to avoid dividing by 0, etc.

#---------------------------------------------------------------------------# maprows
rows(x::AVec, rng) = view(x, rng)
rows(x::AMat, rng) = view(x, rng, :)

"""
```julia
maprows(f::Function, b::Integer, data...)
```

Map rows of `data` in batches of size `b`.  Most usage is done through `do` blocks.
### Example
```julia
s = Series(Mean())
maprows(10, randn(100)) do yi
    fit!(s, yi)
    info("nobs: \$(nobs(s))")
end
```
"""
function maprows(f::Function, b::Integer, data...)
    n = size(data[1], 1)
    i = 1
    while i <= n
        rng = i:min(i + b - 1, n)
        batch_data = map(x -> rows(x, rng), data)
        f(batch_data...)
        i += b
    end
end


#----------------------------------------------------------------------# source files
include("weight.jl")
include("series.jl")
include("scalarinput/summary.jl")
include("scalarinput/reservoir.jl")
include("vectorinput/mv.jl")
include("vectorinput/covmatrix.jl")
include("vectorinput/kmeans.jl")
include("distributions.jl")
include("scalarinput/normalmix.jl")
include("streamstats/hyperloglog.jl")
include("streamstats/bootstrap.jl")
include("xyinput/statlearn.jl")
include("xyinput/linreg.jl")



end # module
