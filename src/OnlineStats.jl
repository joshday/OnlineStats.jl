module OnlineStats

import StatsBase
import StatsBase: nobs, fit, fit!, skewness, kurtosis, coef, predict
import ArrayViews
import Distributions
Ds = Distributions
import Requires

export
    OnlineStat,
    # Weight
    Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2,
    BoundedEqualWeight,
    # <: OnlineStat
    Mean, Means, Variance, Variances, Extrema, QuantileSGD, QuantileMM, Moments,
    Diff, Diffs, Sum, Sums, CovMatrix, LinReg, QuantReg, NormalMix,
    StatLearn, StatLearnSparse, HardThreshold, StatLearnCV,
    KMeans, BiasVector, BiasMatrix, TwoWayInteractionVector, TwoWayInteractionMatrix,
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal,
    FitMultinomial, FitMvNormal,
    # Penalties
    Penalty, NoPenalty, RidgePenalty, LassoPenalty, ElasticNetPenalty, SCADPenalty,
    # ModelDefinition and Algorithm
    ModelDefinition, L2Regression, L1Regression, LogisticRegression,
    PoissonRegression, QuantileRegression, SVMLike, HuberRegression,
    Algorithm, SGD, SGD2, AdaGrad, AdaGrad2, AdaDelta, RDA, MMGrad, ADAM,
    # streamstats
    BernoulliBootstrap, PoissonBootstrap, FrozenBootstrap, cached_state,
    replicates, HyperLogLog,
    # methods
    value, fit, fit!, nobs, skewness, kurtosis, sweep!, coef, predict,
    loss, cost, center, standardize, fitdistribution

#-----------------------------------------------------------------------------# types
abstract Input
abstract ScalarInput    <: Input  # observation = scalar
abstract VectorInput    <: Input  # observation = vector
abstract XYInput        <: Input  # observation = (x, y) pair

abstract OnlineStat{I <: Input}

typealias VecF      Vector{Float64}
typealias MatF      Matrix{Float64}
typealias AVec{T}   AbstractVector{T}
typealias AMat{T}   AbstractMatrix{T}
typealias AVecF     AVec{Float64}
typealias AMatF     AMat{Float64}

#---------------------------------------------------------------------# printing
name(o) = replace(string(typeof(o)), "OnlineStats.", "")
printheader(io::IO, s::AbstractString) = print_with_color(:blue, io, "■ $s \n")
function print_item(io::IO, name::AbstractString, value)
    println(io, "  >" * @sprintf("%12s", name * ": "), value)
end
function print_value_and_nobs(io::IO, o::OnlineStat)
    print_item(io, "value", value(o))
    print_item(io, "nobs", nobs(o))
end
function Base.show(io::IO, o::OnlineStat)
    printheader(io, name(o))
    print_value_and_nobs(io, o)
end

#------------------------------------------------------------------------------# fit!
"""
`fit!(o::OnlineStat, input...)`

Include more data for an OnlineStat.

There are multiple `fit!` methods for each OnlineStat.

- Adding an `Integer` after the input arguments will perform minibatch updates.

```
y = randn(100)
o = Mean()
fit!(o, y, 10)
```

- Adding a `Float64` after the input arguments will override the weight

```julia
y = randn(100)
wts = rand(100)

o = Mean()
fit!(o, y, .1)   # Use weight of .1 for each update
fit!(o, y, wts)  # Update the Mean with y[i] using wts[i]
```
"""
############ single observation
function fit!(o::OnlineStat{ScalarInput}, y::Real)
    updatecounter!(o)
    γ = weight(o)
    _fit!(o, y, γ)
    o
end
function fit!{T <: Real}(o::OnlineStat{VectorInput}, y::AVec{T})
    updatecounter!(o)
    γ = weight(o)
    _fit!(o, y, γ)
    o
end
function fit!{T <: Real}(o::OnlineStat{XYInput}, x::AVec{T}, y::Real)
    updatecounter!(o)
    γ = weight(o)
    _fit!(o, x, y, γ)
    o
end

############ single observation, override the weight
function fit!(o::OnlineStat{ScalarInput}, y::Real, γ::Float64)
    updatecounter!(o)
    _fit!(o, y, γ)
    o
end
function fit!{T <: Real}(o::OnlineStat{VectorInput}, y::AVec{T}, γ::Float64)
    updatecounter!(o)
    _fit!(o, y, γ)
    o
end
function fit!{T <: Real}(o::OnlineStat{XYInput}, x::AVec{T}, y::Real, γ::Float64)
    updatecounter!(o)
    _fit!(o, x, y, γ)
    o
end

############ multiple observations
function fit!(o::OnlineStat{ScalarInput}, y::AVec)
    for yi in y
        fit!(o, yi)
    end
    o
end
function fit!(o::OnlineStat{VectorInput}, y::AMat)
    for i in 1:size(y, 1)
        fit!(o, row(y, i))
    end
    o
end
function fit!(o::OnlineStat{XYInput}, x::AMat, y::AVec)
    @assert size(x, 1) == length(y)
    for i in eachindex(y)
        fit!(o, row(x, i), row(y, i))
    end
    o
end

############ multiple observations, override weight
function fit!(o::OnlineStat{ScalarInput}, y::AVec, w::AVec)
    @assert length(y) == length(w)
    for i in eachindex(y)
        fit!(o, y[i], w[i])
    end
    o
end
function fit!(o::OnlineStat{VectorInput}, y::AMat, w::AVec)
    n2 = nrows(y)
    @assert n2 == length(w)
    for i in 1:n2
        fit!(o, row(y, i), w[i])
    end
    o
end
function fit!(o::OnlineStat{XYInput}, x::AMat, y::AVec, w::AVec)
    @assert size(x, 1) == length(y) == length(w)
    for i in eachindex(y)
        fit!(o, row(x, i), row(y, i), w[i])
    end
    o
end

############ multiple observations, override weight, each update gets the same weight
function fit!(o::OnlineStat{ScalarInput}, y::AVec, w::Real)
    for i in eachindex(y)
        fit!(o, y[i], w)
    end
    o
end
function fit!(o::OnlineStat{VectorInput}, y::AMat, w::Real)
    n2 = nrows(y)
    for i in 1:n2
        fit!(o, row(y, i), w)
    end
    o
end
function fit!(o::OnlineStat{XYInput}, x::AMat, y::AVec, w::Real)
    @assert size(x, 1) == length(y)
    for i in eachindex(y)
        fit!(o, row(x, i), row(y, i), w)
    end
    o
end

############ fit with observations in the columns (experimental)
function fit_col!(o::OnlineStat{VectorInput}, y::AMat)
    for i in 1:size(y, 2)
        fit!(o, col(y, i))
    end
    o
end
function fit_col!(o::OnlineStat{XYInput}, x::AMat, y::AVec)
    @assert size(x, 2) == length(y)
    for i in eachindex(y)
        fit!(o, col(x, i), row(y, i))
    end
    o
end

############ multiple observations, update in batches
function fit!(o::OnlineStat{ScalarInput}, y::AVec, b::Integer)
    b = Int(b)
    n = length(y)
    0 < b <= n || warn("batch size larger than data size")
    if b == 1
        fit!(o, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            updatecounter!(o, b)
            γ = weight(o, b)
            _fitbatch!(o, rows(y, rng), γ)
            i += b
        end
    end
    o
end
function fit!(o::OnlineStat{VectorInput}, y::AMat, b::Integer)
    b = Int(b)
    n = size(y, 1)
    0 < b <= n || warn("batch size larger than data size")
    if b == 1
        fit!(o, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            updatecounter!(o, b)
            γ = weight(o, b)
            _fitbatch!(o, rows(y, rng), γ)
            i += b
        end
    end
    o
end
function fit!(o::OnlineStat{XYInput}, x::AMat, y::AVec, b::Integer)
    b = Int(b)
    n = length(y)
    0 < b <= n || warn("batch size larger than data size")
    if b == 1
        fit!(o, x, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            updatecounter!(o, b)
            γ = weight(o, b)
            _fitbatch!(o, rows(x, rng), rows(y, rng), γ)
            i += b
        end
    end
    o
end

# error if no fitbatch! method
_fitbatch!(o, args...) = (warn("no fitbatch! method for $(typeof(o))"); _fit!(o, args...))

#---------------------------------------------------------------------------# helpers
"""
The associated value of an OnlineStat.

```
o1 = Mean()
o2 = Variance()
value(o1)
value(o2)
```
"""
value(o::OnlineStat) = o.value
StatsBase.nobs(o::OnlineStat) = nobs(o.weight)
unbias(o::OnlineStat) = nobs(o) / (nobs(o) - 1)

# for updating
smooth(m::Float64, v::Real, γ::Float64) = (1.0 - γ) * m + γ * v
function smooth!{T<:Real}(m::VecF, v::AVec{T}, γ::Float64)
    for i in eachindex(v)
        @inbounds m[i] = smooth(m[i], v[i], γ)
    end
end
subgrad(m::Float64, γ::Float64, g::Real) = m - γ * g
function smooth!(avg::AbstractMatrix, v::AbstractMatrix, λ::Float64)
    n, p = size(avg)
    @assert size(avg) == size(v)
    for j in 1:p, i in 1:n
        @inbounds avg[i,j] = smooth(avg[i, j], v[i, j], λ)
    end
end
# Rank 1 update of symmetric matrix: (1 - γ) * A + γ * x * x'
# Only upper triangle is updated...I was having trouble with BLAS.syr!
function rank1_smooth!(A::AMat, x::AVec, γ::Real)
    @assert size(A, 1) == size(A, 2)
    for j in 1:size(A, 2), i in 1:j
        @inbounds A[i, j] = (1.0 - γ) * A[i, j] + γ * x[i] * x[j]
    end
end


row(x::AMat, i::Integer) = slice(x, i, :)
row(x::AVec, i::Integer) = x[i]
rows(x::AMat, rs::AVec{Int}) = sub(x, rs, :)
rows(x::AVec, rs::AVec{Int}) = sub(x, rs)
col(x::AMat, i::Integer) = slice(x, :, i)
cols(x::AMat, rs::AVec{Int}) = sub(x, :, rs)

nrows(x::AMat) = size(x, 1)
ncols(x::AMat) = size(x, 2)


Base.copy(o::OnlineStat) = deepcopy(o)

# epsilon used in special cases to avoid dividing by 0, etc.
const _ϵ = 1e-8



#----------------------------------------------------------------------# source files
include("weight.jl")
include("summary.jl")
include("distributions.jl")
include("normalmix.jl")
include("modeling/sweep.jl")
include("modeling/penalty.jl")
include("modeling/statlearn.jl")
include("modeling/statlearnextensions.jl")
include("modeling/linreg.jl")
include("modeling/quantreg.jl")
include("modeling/bias.jl")
include("streamstats/bootstrap.jl")
include("streamstats/hyperloglog.jl")
include("multivariate/kmeans.jl")
Requires.@require Plots include("plots.jl")

end # module
