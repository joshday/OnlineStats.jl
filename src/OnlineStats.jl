module OnlineStats

import StatsBase
import StatsBase: nobs, fit, fit!, skewness, kurtosis, coef, predict
import ArrayViews
import Distributions
Ds = Distributions
import Requires
Requires.@require Plots include("plots.jl")

export
    OnlineStat,
    # Weight
    Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2,
    # <: OnlineStat
    Mean, Means, Variance, Variances, Extrema, QuantileSGD, QuantileMM, Moments,
    Diff, Diffs, CovMatrix, LinReg, QuantReg, NormalMix,
    StatLearn, StatLearnSparse, HardThreshold, StatLearnCV,
    KMeans, BiasVector, BiasMatrix,
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal,
    FitMultinomial, FitMvNormal,
    # Penalties
    NoPenalty, L2Penalty, L1Penalty, ElasticNetPenalty, SCADPenalty,
    # ModelDef and Algorithm
    ModelDef, L2Regression, L1Regression, LogisticRegression,
    PoissonRegression, QuantileRegression, SVMLike, HuberRegression,
    Algorithm, SGD, AdaGrad, AdaGrad2, AdaDelta, RDA, MMGrad,
    # streamstats
    BernoulliBootstrap, PoissonBootstrap, FrozenBootstrap, cached_state,
    replicates, HyperLogLog,
    # methods
    value, fit, fit!, nobs, skewness, kurtosis, n_updates, sweep!, coef, predict,
    vcov, stderr, loss, center, standardize

#------------------------------------------------------------------------# types
abstract OnlineStat

typealias VecF Vector{Float64}
typealias MatF Matrix{Float64}
typealias AVec{T} AbstractVector{T}
typealias AMat{T} AbstractMatrix{T}
typealias AVecF AVec{Float64}
typealias AMatF AMat{Float64}

#-----------------------------------------------------------------------# weight
abstract Weight
nobs(w::Weight) = w.n
# update and return new weight
weight!(o::OnlineStat, n2::Int) = weight!(o.weight, n2)
# update weight without returning the new weight
weight_noret!(o::OnlineStat, n2::Int) = weight_noret!(o.weight, n2)



"All observations weighted equally."
type EqualWeight <: Weight
    n::Int
    EqualWeight() = new(0)
end
weight!(w::EqualWeight, n2::Int) = (w.n += n2; return n2/ w.n)
weight_noret!(w::EqualWeight, n2::Int) = (w.n += n2)


"`ExponentialWeight(minstep)`.  Once equal weights reach `minstep`, hold weights constant."
type ExponentialWeight <: Weight
    minstep::Float64
    n::Int
    ExponentialWeight(minstep::Real = 0.0) = new(Float64(minstep), 0)
end
weight!(w::ExponentialWeight, n2::Int) = (w.n += n2; return max(n2 / w.n, w.minstep))
weight_noret!(w::ExponentialWeight, n2::Int) = (w.n += n2)
``

"""
`LearningRate(r; minstep = 0.0)`.

Weight at update `t` is `1 / t ^ r`.  Compare to `LearningRate2`.
"""
type LearningRate <: Weight
    r::Float64
    minstep::Float64
    n::Int
    nup::Int
    LearningRate(r::Real = 0.6; minstep::Real = 0.0) = new(Float64(r), Float64(minstep), 0, 0)
end
function weight!(w::LearningRate, n2::Int)
    w.n += n2
    w.nup += 1
    max(w.minstep, exp(-w.r * log(w.nup)))
end
weight_noret!(w::LearningRate, n2::Int) = (w.n += n2; w.nup += 1)
nup(w::LearningRate) = o.nup


"""
LearningRate2(γ, c = 1.0; minstep = 0.0).

Weight at update `t` is `γ / (1 + γ * c * t)`.  Compare to `LearningRate`.
"""
type LearningRate2 <: Weight
    # Recommendation from http://research.microsoft.com/pubs/192769/tricks-2012.pdf
    γ::Float64
    c::Float64
    minstep::Float64
    n::Int
    nup::Int
    LearningRate2(γ::Real, c::Real = 1.0; minstep = 0.0) =
        new(Float64(γ), Float64(c), Float64(minstep), 0, 0)
end
function weight!(w::LearningRate2, n2::Int)
    w.n += n2
    w.nup += 1
    max(w.minstep, w.γ / (1.0 + w.γ * w.c * w.nup))
end
weight_noret!(w::LearningRate2, n2::Int) = (w.n += n2; w.nup += 1)
nup(w::LearningRate2) = o.nup

#---------------------------------------------------------------------# printing
printheader(io::IO, s::AbstractString) = print_with_color(:blue, io, "▌ $s \n")
function print_item(io::IO, name::AbstractString, value)
    println(io, "  ▶" * @sprintf("%12s", name * ": "), value)
end
function print_value_and_nobs(io::IO, o::OnlineStat)
    print_item(io, "value", value(o))
    print_item(io, "nobs", nobs(o))
end

# fallback show
function Base.show(io::IO, o::OnlineStat)
    printheader(io, string(typeof(o)))
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
function fit!(o::OnlineStat, y::Union{AVec, AMat})
    for i in 1:size(y, 1)
        fit!(o, row(y, i))
    end
end
function fit!(o::OnlineStat, x::AMat, y::AVec)
    for i in 1:length(y)
        fit!(o, row(x, i), row(y, i))
    end
end

# Update in batches
function fit!(o::OnlineStat, y::Union{AVec, AMat}, b::Integer)
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
end
function fit!(o::OnlineStat, x::AMat, y::AVec, b::Integer)
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
end

# fall back on fit! if there is no fitbatch! method
fitbatch!(args...) = fit!(args...)

#----------------------------------------------------------------------# helpers
"`value(o::OnlineStat)`.  The associated value of an OnlineStat."
value(o::OnlineStat) = o.value
StatsBase.nobs(o::OnlineStat) = nobs(o.weight)
unbias(o::OnlineStat) = nobs(o) / (nobs(o) - 1)

# for updating
smooth(m::Float64, v::Real, γ::Float64) = (1.0 - γ) * m + γ * v
function smooth!{T<:Real}(m::VecF, v::AVec{T}, γ::Float64)
    for i in 1:length(v)
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



row(x::AMat, i::Integer) = ArrayViews.rowvec_view(x, i)
row(x::AVec, i::Integer) = x[i]
rows(x::AVec, rs::AVec{Int}) = ArrayViews.view(x, rs)
rows(x::AMat, rs::AVec{Int}) = ArrayViews.view(x, rs, :)

col(x::AMat, i::Integer) = ArrayViews.view(x, :, i)

nrows(x::AMat) = size(x, 1)
ncols(x::AMat) = size(x, 2)


Base.copy(o::OnlineStat) = deepcopy(o)

"epsilon used in special cases to avoid dividing by 0, etc."
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

end # module

O = OnlineStats
