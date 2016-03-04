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
    BoundedExponentialWeight,
    # <: OnlineStat
    Mean, Means, Variance, Variances, Extrema, QuantileSGD, QuantileMM, Moments,
    Diff, Diffs, Sum, Sums, CovMatrix, LinReg, QuantReg, NormalMix,
    StatLearn, StatLearnSparse, HardThreshold, StatLearnCV,
    KMeans, BiasVector, BiasMatrix,
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal,
    FitMultinomial, FitMvNormal,
    # Penalties
    Penalty, NoPenalty, L2Penalty, L1Penalty, ElasticNetPenalty, SCADPenalty,
    # ModelDefinition and Algorithm
    ModelDefinition, L2Regression, L1Regression, LogisticRegression,
    PoissonRegression, QuantileRegression, SVMLike, HuberRegression,
    Algorithm, SGD, AdaGrad, AdaGrad2, AdaDelta, RDA, MMGrad,
    # streamstats
    BernoulliBootstrap, PoissonBootstrap, FrozenBootstrap, cached_state,
    replicates, HyperLogLog,
    # methods
    value, fit, fit!, nobs, skewness, kurtosis, sweep!, coef, predict,
    loss, center, standardize, show_weight, fitdistribution

#------------------------------------------------------------------------# types
abstract Input
abstract ScalarInput <: Input  # observation = scalar
abstract VectorInput <: Input  # observation = vector
abstract XYInput <: Input      # observation = (x, y) pair
abstract OnlineStat{I <: Input}

typealias VecF Vector{Float64}
typealias MatF Matrix{Float64}
typealias AVec{T} AbstractVector{T}
typealias AMat{T} AbstractMatrix{T}
typealias AVecF AVec{Float64}
typealias AMatF AMat{Float64}

#-----------------------------------------------------------------------# weight
abstract Weight
nobs(w::Weight) = w.n
weight!(o::OnlineStat, n2::Int = 1) = weight!(o.weight, n2)
weight_noret!(o::OnlineStat, n2::Int = 1) = weight_noret!(o.weight, n2)


"""
`EqualWeight()`.  All observations weighted equally.
"""
type EqualWeight <: Weight
    n::Int
    EqualWeight() = new(0)
end
weight!(w::EqualWeight, n2::Int = 1)        = (w.n += n2; return n2 / w.n)
weight_noret!(w::EqualWeight, n2::Int = 1)  = (w.n += n2)


"""
`ExponentialWeight(λ::Float64)`, `ExponentialWeight(lookback::Int)`

Weights are held constant at `λ = 2 / (1 + lookback)`.
"""
type ExponentialWeight <: Weight
    λ::Float64
    n::Int
    function ExponentialWeight(λ::Real, n::Integer)
        @assert 0 <= λ <= 1
        new(λ, n)
    end
    ExponentialWeight(λ::Real = 1.0) = ExponentialWeight(λ, 0)
    ExponentialWeight(lookback::Integer) = ExponentialWeight(2.0 / (lookback + 1))
end
weight!(w::ExponentialWeight, n2::Int = 1)  = (w.n += n2; w.λ)
weight_noret!(w::ExponentialWeight, n2::Int = 1) = (w.n += n2)


"""
`BoundedExponentialWeight(λ::Float64)`, `BoundedExponentialWeight(lookback::Int)`

Use equal weights until reaching `λ = 2 / (1 + lookback)`, then hold constant.
"""
type BoundedExponentialWeight <: Weight
    λ::Float64
    n::Int
    function BoundedExponentialWeight(λ::Real, n::Integer)
        @assert 0 <= λ <= 1
        new(λ, n)
    end
    BoundedExponentialWeight(λ::Real = 1.0) = BoundedExponentialWeight(λ, 0)
    BoundedExponentialWeight(lookback::Integer) = BoundedExponentialWeight(2.0 / (lookback + 1))
end
weight!(w::BoundedExponentialWeight, n2::Int = 1)  = (w.n += n2; return max(n2 / w.n, w.λ))
weight_noret!(w::BoundedExponentialWeight, n2::Int = 1) = (w.n += n2)


"""
`LearningRate(r = 0.6; minstep = 0.0)`.

Weight at update `t` is `1 / t ^ r`.  When weights reach `minstep`, hold weights constant.  Compare to `LearningRate2`.
"""
type LearningRate <: Weight
    r::Float64
    minstep::Float64
    n::Int
    nups::Int
    LearningRate(r::Real = 0.6; minstep::Real = 0.0) = new(r, minstep, 0, 0)
end
function weight!(w::LearningRate, n2::Int = 1)
    w.n += n2
    w.nups += 1
    max(w.minstep, exp(-w.r * log(w.nups)))
end
weight_noret!(w::LearningRate, n2::Int = 1) = (w.n += n2; w.nups += 1)
nups(w::LearningRate) = w.nups


"""
`LearningRate2(γ, c = 1.0; minstep = 0.0)`.

Weight at update `t` is `γ / (1 + γ * c * t)`.  When weights reach `minstep`, hold weights constant.  Compare to `LearningRate`.
"""
type LearningRate2 <: Weight
    # Recommendation from http://research.microsoft.com/pubs/192769/tricks-2012.pdf
    γ::Float64
    c::Float64
    minstep::Float64
    n::Int
    nups::Int
    LearningRate2(γ::Real, c::Real = 1.0; minstep = 0.0) = new(γ, c, minstep, 0, 0)
end
function weight!(w::LearningRate2, n2::Int = 1)
    w.n += n2
    w.nups += 1
    max(w.minstep, w.γ / (1.0 + w.γ * w.c * w.nups))
end
weight_noret!(w::LearningRate2, n2::Int = 1) = (w.n += n2; w.nups += 1)
nups(w::LearningRate2) = w.nups

nups(o::OnlineStat) = nups(o.w)


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

# fallback show
function Base.show(io::IO, o::OnlineStat)
    printheader(io, name(o))
    print_value_and_nobs(io, o)
end

#-------------------------------------------------------------------------# fit!
"""
`fit!(o::OnlineStat, y, b = 1)`

`fit!(o::OnlineStat, x, y, b = 1)`

Include more data for an OnlineStat using batch updates of size `b`.  Batch updates
make more sense for OnlineStats that use stochastic approximation, such as
`StatLearn`, `QuantileMM`, and `NormalMix`.
"""
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
function fit_col!(o::OnlineStat{VectorInput}, y::AMat)
    for i in 1:size(y, 2)
        fit!(o, col(y, i))
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
function fit_col!(o::OnlineStat{XYInput}, x::AMat, y::AVec)
    @assert size(x, 2) == length(y)
    for i in eachindex(y)
        fit!(o, col(x, i), row(y, i))
    end
    o
end



# Update in batches
function fit!(o::OnlineStat{ScalarInput}, y::AVec, b::Integer)
    b = Int(b)
    n = length(y)
    @assert 0 < b <= n "batch size must be positive and smaller than data size"
    if b == 1
        fit!(o, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            fitbatch!(o, rows(y, rng))
            i += b
        end
    end
    o
end

function fit!(o::OnlineStat{VectorInput}, y::AMat, b::Integer)
    b = Int(b)
    n = size(y, 1)
    @assert 0 < b <= n "batch size must be positive and smaller than data size"
    if b == 1
        fit!(o, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            fitbatch!(o, rows(y, rng))
            i += b
        end
    end
    o
end
function fit_col!(o::OnlineStat{VectorInput}, y::AMat, b::Integer)
    b = Int(b)
    n = size(y, 2)
    @assert 0 < b <= n "batch size must be positive and smaller than data size"
    if b == 1
        fit!(o, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            fitbatch!(o, cols(y, rng))
            i += b
        end
    end
    o
end

function fit!(o::OnlineStat{XYInput}, x::AMat, y::AVec, b::Integer)
    b = Int(b)
    n = length(y)
    @assert 0 < b <= n "batch size must be positive and smaller than data size"
    if b == 1
        fit!(o, x, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            fitbatch!(o, rows(x, rng), rows(y, rng))
            i += b
        end
    end
    o
end
function fit_col!(o::OnlineStat{XYInput}, x::AMat, y::AVec, b::Integer)
    b = Int(b)
    n = length(y)
    @assert size(x, 2) == n "number of observations don't match.  Did you mean `fit!(...)`?"
    @assert 0 < b <= n "batch size must be positive and smaller than data size"
    if b == 1
        fit!(o, x, y)
    else
        i = 1
        while i <= n
            rng = i:min(i + b - 1, n)
            fitbatch!(o, cols(x, rng), rows(y, rng))
            i += b
        end
    end
    o
end

# fall back on fit! if there is no fitbatch! method
fitbatch!(args...) = fit!(args...)

#----------------------------------------------------------------------# helpers
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

# row(x::AMat, i::Integer) = ArrayViews.rowvec_view(x, i)
# row(x::AVec, i::Integer) = x[i]
# rows(x::AMat, rs::AVec{Int}) = ArrayViews.view(x, rs, :)
# rows(x::AVec, rs::AVec{Int}) = ArrayViews.view(x, rs)
# col(x::AMat, i::Integer) = ArrayViews.view(x, :, i)
# cols(x::AMat, rs::AVec{Int}) = ArrayViews.view(x, :, rs)

nrows(x::AMat) = size(x, 1)
ncols(x::AMat) = size(x, 2)


Base.copy(o::OnlineStat) = deepcopy(o)

# epsilon used in special cases to avoid dividing by 0, etc.
const _ϵ = 1e-8



#-----------------------------------------------------------------# source files
include("summary.jl")
include("distributions.jl")
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
include("normalmix.jl")
Requires.@require Plots include("plots.jl")

end # module

O = OnlineStats
