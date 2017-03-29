module OnlineStats

using StatsBase, LearnBase
importall StatsBase
importall LearnBase
import Distributions
Ds = Distributions

# Reexport LearnBase and StatsBase
for pkg in [:LearnBase, :StatsBase]
    eval(Expr(:toplevel, Expr(:export, setdiff(names(eval(pkg)), [pkg])...)))
end

export
    # AbstractSeries
    Series, Bootstrap,
    # Weight
    Weight, EqualWeight, BoundedEqualWeight, ExponentialWeight, LearningRate, LearningRate2,
    # functions
    maprows, nups, stats, cached_state, replicates,
    OnlineStat,
    Mean, Variance, Extrema, OrderStats, Moments, QuantileSGD, QuantileMM, Diff, Sum,
    MV, CovMatrix, KMeans,
    FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial,
    FitMvNormal, NormalMix,
    # StreamStats
    HyperLogLog

#-----------------------------------------------------------------------------# types
# 0 = scalar, 1 = vector, 2 = matrix, -1 = unkown, or Ds.Distribution
abstract type OnlineStat{INDIM, OUTDIM} end

const AA        = AbstractArray
const VecF      = Vector{Float64}
const MatF      = Matrix{Float64}
const AVec{T}   = AbstractVector{T}
const AMat{T}   = AbstractMatrix{T}
const AVecF     = AVec{Float64}
const AMatF     = AMat{Float64}

include("show.jl")

#---------------------------------------------------------------------------# helpers
_io{I, O}(o::OnlineStat{I, O}) = I, O
_io{I, O}(o::OnlineStat{I, O}, i::Integer) = _io(o)[i]

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
subgrad(m::Float64, γ::Float64, g::Real) = m - γ * g
function smooth_syr!(A::AMat, x::AVec, γ::Float64)
    @assert size(A, 1) == length(x)
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
include("vectorinput/mv.jl")
include("vectorinput/covmatrix.jl")
include("vectorinput/kmeans.jl")
include("distributions.jl")
include("scalarinput/normalmix.jl")
include("streamstats/hyperloglog.jl")
include("streamstats/bootstrap.jl")



end # module
