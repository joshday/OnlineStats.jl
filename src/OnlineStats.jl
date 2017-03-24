module OnlineStats

import StatsBase
importall StatsBase
using LearnBase
importall LearnBase

# Reexport LearnBase
for pkg in [:LearnBase]
    eval(Expr(:toplevel, Expr(:export, setdiff(names(eval(pkg)), [pkg])...)))
end

export
    OnlineStat,
    # Input
    Input, ScalarInput, VectorInput,
    Series, Stats,
    # Weight
    EqualWeight, BoundedEqualWeight, ExponentialWeight, LearningRate, LearningRate2,
    # functions
    maprows,
    # <: OnlineStat
    Mean, Variance, Extrema, OrderStatistics, Moments
    # Weight, EqualWeight, ExponentialWeight, LearningRate, LearningRate2,
    # BoundedEqualWeight,
    # # <: OnlineStat
    # Mean, Means, Variance, Variances, Extrema, Extremas, QuantileSGD, QuantileMM, Moments,
    # Diff, Diffs, Sum, Sums, CovMatrix, KMeans, OrderStatistics,
    # # add an intercept term or two way interactions
    # BiasVector, BiasMatrix, TwoWayInteractionVector, TwoWayInteractionMatrix,
    # # distributions
    # FitBeta, FitCategorical, FitCauchy, FitGamma, FitLogNormal, FitNormal,
    # FitMultinomial, FitMvNormal, FitDirichletMultinomial, NormalMix,
    # # streamstats
    # BernoulliBootstrap, PoissonBootstrap, FrozenBootstrap, cached_state,
    # replicates, HyperLogLog,
    # # methods
    # value, fit, fit!, nobs, skewness, kurtosis, fitdistribution, center, maprows

#-----------------------------------------------------------------------------# types
abstract type Input end
abstract type ScalarInput    <: Input end  # observation = scalar
abstract type VectorInput    <: Input end  # observation = vector

abstract type OnlineStat{I <: Input} end
abstract type AbstractStats end

const VecF      = Vector{Float64}
const MatF      = Matrix{Float64}
const AVec{T}   = AbstractVector{T}
const AMat{T}   = AbstractMatrix{T}
const AVecF     = AVec{Float64}
const AMatF     = AMat{Float64}

#---------------------------------------------------------------------# printing
name(o) = replace(string(typeof(o)), "OnlineStats.", "")

printheader(io::IO, s::AbstractString) = print_with_color(:light_cyan, io, "■ $s")

function print_item(io::IO, name::AbstractString, value)
    println(io, "  >" * @sprintf("%12s", name * ": "), value)
end

showfields(o::OnlineStat) = fieldnames(o)

function Base.show(io::IO, o::OnlineStat)
    nms = showfields(o)
    print(io, name(o))
    print(io, "(")
    for nm in nms
        print(io, "$nm = $(getfield(o, nm))")
        nm != nms[end] && print(io, ", ")
    end
    print(io, ")")
end



#---------------------------------------------------------------------------# helpers
value(o::OnlineStat) = getfield(o, fieldnames(o)[1])


StatsBase.nobs(o::OnlineStat) = nobs(o.weight)
unbias(o::OnlineStat) = nobs(o) / (nobs(o) - 1)

# for updating
smooth(m::Float64, v::Real, γ::Float64) = m + γ * (v - m)

function smooth!(m::AbstractArray, v::AbstractArray, γ::Float64)
    # assumes both arrays have linear indexing
    @assert length(m) == length(v)
    for i in eachindex(v)
        @inbounds m[i] = smooth(m[i], v[i], γ)
    end
end

subgrad(m::Float64, γ::Float64, g::Real) = m - γ * g

# Rank 1 update of symmetric matrix: (1 - γ) * A + γ * x * x'
function smooth_syr!(A::AMat, x::AVec, γ::Float64)
    @assert size(A, 1) == length(x)
    for j in 1:size(A, 2), i in 1:j
        @inbounds A[i, j] = (1.0 - γ) * A[i, j] + γ * x[i] * x[j]
    end
end
function smooth_syrk!(A::MatF, x::AMat, γ::Float64)
    BLAS.syrk!('U', 'T', γ / size(x, 1), x, 1.0 - γ, A)
end



Base.copy(o::OnlineStat) = deepcopy(o)

#-----------------------------------------------------------------------------# merge
function Base.merge(o::OnlineStat, o2::OnlineStat, method::Symbol = :append)
    merge!(copy(o), o2, method)
end
function Base.merge(o::OnlineStat, o2::OnlineStat, wt::Float64)
    merge!(copy(o), o2, wt)
end

function Base.merge!(o::OnlineStat, o2::OnlineStat, method::Symbol = :append)
    @assert typeof(o) == typeof(o2)
    if nobs(o2) == 0
        return o
    end
    updatecounter!(o, nobs(o2))
    if method == :append
        _merge!(o, o2, weight(o, nobs(o2)))
    elseif method == :mean
        _merge!(o, o2, 0.5 * (weight(o) + weight(o2)))
    elseif method == :singleton
        _merge!(o, o2, weight(o))
    end
    o
end

function Base.merge!(o::OnlineStat, o2::OnlineStat, wt::Float64)
    @assert typeof(o) == typeof(o2)
    updatecounter!(o, nobs(o2))
    _merge!(o, o2, wt)
    o
end




# epsilon used in special cases to avoid dividing by 0, etc.
const _ϵ = 1e-8

#---------------------------------------------------------------------------# maprows
"""
Perform operations on data in blocks.

`maprows(f::Function, b::Integer, data...)`

This function iteratively feeds `data` in blocks of `b` observations to the
function `f`.  The most common usage is with `do` blocks:

```julia
# Example 1
y = randn(50)
o = Variance()
maprows(10, y) do yi
    fit!(o, yi)
    println("Updated with another batch!")
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

# include("fit.jl")
# include("summary.jl")
# include("distributions.jl")
# include("normalmix.jl")
# include("streamstats/bootstrap.jl")
# include("streamstats/hyperloglog.jl")
# include("multivariate/kmeans.jl")
# include("multivariate/bias.jl")

end # module
