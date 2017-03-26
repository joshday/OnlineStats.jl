module OnlineStats

using StatsBase, LearnBase
importall StatsBase
importall LearnBase
import Distributions
Ds = Distributions
import StaticArrays

# Reexport LearnBase
for pkg in [:LearnBase]
    eval(Expr(:toplevel, Expr(:export, setdiff(names(eval(pkg)), [pkg])...)))
end

export
    Series, Stats,
    # Weight
    EqualWeight, BoundedEqualWeight, ExponentialWeight, LearningRate, LearningRate2,
    # functions
    maprows, nups,
    # <: OnlineStat
    Mean, Variance, Extrema, OrderStatistics, Moments, QuantileSGD, QuantileMM,
    MV, CovMatrix

#-----------------------------------------------------------------------------# types
abstract type OnlineIO end

abstract type Input <: OnlineIO end
abstract type NumberIn <: Input end  # observation = scalar
abstract type VectorIn <: Input end  # observation = vector

abstract type Output <: OnlineIO end
abstract type NumberOut <: Output end
abstract type VectorOut <: Output end
abstract type MatrixOut <: Output end
Base.show(io::IO, o::OnlineIO) = print(io, name(o))

abstract type OnlineStat{I <: Any, O <: Any} end

"AbstractSeries: Subtypes have fields: stats, weight, nobs, nups, id"
abstract type AbstractSeries end

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
value(o::OnlineStat, nobs::Integer) = value(o)
Base.copy(o::OnlineStat) = deepcopy(o)
unbias(nobs::Integer) = nobs / (nobs - 1)


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


#-----------------------------------------------------------------------------# merge
function Base.merge(o::OnlineStat, o2::OnlineStat, method::Symbol = :append)
    merge!(copy(o), o2, method)
end
function Base.merge(o::OnlineStat, o2::OnlineStat, wt::Float64)
    merge!(copy(o), o2, wt)
end

function Base.merge!(o::OnlineStat, o2::OnlineStat, n2::Integer, method::Symbol = :append)
    @assert typeof(o) == typeof(o2)
    if n2 == 0
        return o
    end
    updatecounter!(o, n2)
    if method == :append
        _merge!(o, o2, weight(o, n2))
    elseif method == :mean
        _merge!(o, o2, 0.5 * (weight(o) + weight(o2)))
    elseif method == :singleton
        _merge!(o, o2, weight(o))
    end
    o
end

function Base.merge!(o::OnlineStat, o2::OnlineStat, n2::Integer, wt::Float64)
    @assert typeof(o) == typeof(o2)
    updatecounter!(o, n2)
    _merge!(o, o2, wt)
    o
end




# epsilon used in special cases to avoid dividing by 0, etc.
const ϵ = 1e-8

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
include("scalarinput/summary.jl")
include("vectorinput/mv.jl")
include("vectorinput/covmatrix.jl")
# include("distributions.jl")


end # module
