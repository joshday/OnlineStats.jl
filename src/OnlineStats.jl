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
    EqualWeight, ExponentialWeight, LearningRate,
    # Summary
    Mean, Means, Variance, Variances, Extrema, QuantileSGD, QuantileMM, Moments,
    CovMatrix, LinReg, QuantReg,
    StatLearn, StatLearnSparse, HardThreshold, StatLearnCV,
    KMeans, FitDistribution, FitMvDistribution, BiasVector, BiasMatrix,
    # Penalties
    NoPenalty, L2Penalty, L1Penalty, ElasticNetPenalty, SCADPenalty,
    # ModelDef and Algorithm
    ModelDef, L2Regression, L1Regression, LogisticRegression,
    PoissonRegression, QuantileRegression, SVMLike, HuberRegression,
    SGD, AdaGrad, RDA, MMGrad, AdaMMGrad,
    # streamstats
    BernoulliBootstrap, PoissonBootstrap, FrozenBootstrap, cached_state,
    replicates,
    # methods
    value, fit, fit!, nobs, skewness, kurtosis, n_updates, sweep!, coef, predict,
    vcov, stderr, loss

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

immutable EqualWeight <: Weight end
@inline weight(w::EqualWeight, n2::Int, n1::Int, nup::Int) = n2 / (n1 + n2)

immutable ExponentialWeight <: Weight
    minstep::Float64
    ExponentialWeight(minstep::Real = 0.0) = new(Float64(minstep))
end
@inline weight(w::ExponentialWeight, n2::Int, n1::Int, nup::Int) = max(w.minstep, n2 / (n1 + n2))

immutable LearningRate <: Weight
    r::Float64
    minstep::Float64
    LearningRate(r::Real = 0.6; minstep::Real = 0.0) = new(Float64(r), Float64(minstep))
end
@inline weight(w::LearningRate, n2::Int, n1::Int, nup::Int) = max(w.minstep, exp(-w.r * log(nup)))


#----------------------------------------------------------------------# methods
value(o::OnlineStat) = o.value
StatsBase.nobs(o::OnlineStat) = o.n
n_updates(o::OnlineStat) = o.nup

@inline function n_and_nup!(o::OnlineStat, n2::Int)
    o.n += n2
    o.nup += 1
end
@inline function weight!(o::OnlineStat, n2::Int)
    n1 = o.n
    o.n += n2
    o.nup += 1
    weight(o.weight, n2, n1, o.nup)
end
_unbias(o::OnlineStat) = o.n / (o.n - 1)

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
Base.show(io::IO, o::OnlineStat) = print_value_and_nobs(io, o)

#-------------------------------------------------------------------------# fit!
function fit!(o::OnlineStat, y::Union{AVec, AMat})
    @inbounds for i in 1:size(y, 1)
        fit!(o, row(y, i))
    end
end
function fit!(o::OnlineStat, x::AMat, y::AVec)
    @inbounds for i in 1:length(y)
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
            @inbounds fitbatch!(o, rows(y, rng))
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
            @inbounds fitbatch!(o, rows(x, rng), rows(y, rng))
            i += b
        end
    end
end

# fall back on fit! if there is no fitbatch! method
fitbatch!(args...) = fit!(args...)

#----------------------------------------------------------------------# helpers
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

"""
Rank 1 update of symmetric matrix:
 (1 - γ) * A + γ * x * x'

 Only upper triangle is updated
"""
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

const _ϵ = 1e-8  # global ϵ to avoid dividing by 0, etc.



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
include("multivariate/kmeans.jl")

end # module

O = OnlineStats
