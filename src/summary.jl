#-----------------------------------------------------------------------------# Means
"""
Means of multiple series, similar to `mean(x, 1)`.

```julia
x = randn(1000, 5)
o = Means(5)
fit!(o, x)
mean(o)
```
"""
type Means{W <: Weight} <: OnlineStat{VectorInput}
    value::VecF
    weight::W
end
Means(p::Int, wgt::Weight = EqualWeight()) = Means(zeros(p), wgt)
_fit!(o::Means, y::AVec, γ::Float64) = smooth!(o.value, y, γ)
function _fitbatch!{W <: BatchWeight}(o::Means{W}, y::AMat, γ::Float64)
    smooth!(o.value, row(mean(y, 1), 1), γ)
end
Base.mean(o::Means) = value(o)
center{T<:Real}(o::Means, x::AVec{T}) = x - mean(o)
_merge!(o::Means, o2::Means, γ) = _fit!(o, mean(o2), γ)

#-------------------------------------------------------------------------# Variances
"""
Variances of a multiple series, similar to `var(x, 1)`.

```julia
o = Variances(x, EqualWeight())
o = Variances(x)
fit!(o, x2)

mean(o)
var(o)
std(o)
```
"""
type Variances{W <: Weight} <: OnlineStat{VectorInput}
    value::VecF
    μ::VecF
    μold::VecF  # avoid allocation in update
    weight::W
end
function Variances(p::Integer, wgt::Weight = EqualWeight())
    Variances(zeros(p), zeros(p), zeros(p), wgt)
end
function _fit!(o::Variances, y::AVec, γ::Float64)
    copy!(o.μold, o.μ)
    smooth!(o.μ, y, γ)
    for i in eachindex(y)
        o.value[i] = smooth(o.value[i], (y[i] - o.μ[i]) * (y[i] - o.μold[i]), γ)
    end
end
Base.var(o::Variances) = value(o)
Base.std(o::Variances) = sqrt.(value(o))
Base.mean(o::Variances) = o.μ
value(o::Variances) = nobs(o) < 2 ? zeros(o.value) : o.value * unbias(o)
center{T<:Real}(o::Variances, x::AVec{T}) = x - mean(o)
function StatsBase.zscore{T<:Real}(o::Variances, x::AVec{T})
    σs = std(o)
    for j in eachindex(σs)
        @inbounds if σs[j] == 0.0
            σs[j] = 1.0
        end
    end
    center(o, x) ./ σs
end
function StatsBase.zscore{T<:Real}(o::Variances, x::AMat{T})
    σs = std(o)
    for j in eachindex(σs)
        if σs[j] == 0.0
            σs[j] = 1.0
        end
    end
    StatsBase.zscore(x, mean(o)', σs')
end
function _merge!(o::Variances, o2::Variances, γ::Float64)
    δ = mean(o2) - mean(o)
    for i in eachindex(o.value)
        o.value[i] = smooth(o.value[i], o2.value[i], γ) + δ[i] ^ 2 * γ * (1.0 - γ)
        o.μ[i] = smooth(o.μ[i], o2.μ[i], γ)
    end
end


#-------------------------------------------------------------------------# CovMatrix
"""
Covariance matrix, similar to `cov(x)`.

```julia
o = CovMatrix(x, EqualWeight())
o = CovMatrix(x)
fit!(o, x2)

cor(o)
cov(o)
mean(o)
var(o)
```
"""
type CovMatrix{W <: Weight} <: OnlineStat{VectorInput}
    value::MatF
    cormat::MatF
    A::MatF  # X'X / n
    b::VecF  # X * 1' / n (column means)
    weight::W
end
function CovMatrix(p::Integer, wgt::Weight = EqualWeight())
    CovMatrix(zeros(p, p), zeros(p,p), zeros(p, p), zeros(p), wgt)
end
function _fit!(o::CovMatrix, x::AVec, γ::Float64)
    smooth!(o.b, x, γ)
    smooth_syr!(o.A, x, γ)
    o
end
function _fitbatch!(o::CovMatrix, x::AMat, γ::Float64)
    smooth!(o.b, mean(x, 1), γ)
    smooth_syrk!(o.A, x, γ)
end
function value(o::CovMatrix)
    o.value = unbias(o) * full(Symmetric((o.A - o.b * o.b')))
end
Base.mean(o::CovMatrix) = o.b
Base.cov(o::CovMatrix) = value(o)
Base.var(o::CovMatrix) = diag(value(o))
Base.std(o::CovMatrix) = sqrt.(var(o))
function Base.cor(o::CovMatrix)
    copy!(o.cormat, value(o))
    v = 1.0 ./ sqrt.(diag(o.cormat))
    scale!(o.cormat, v)
    scale!(v, o.cormat)
    o.cormat
end
function _merge!(o::CovMatrix, o2::CovMatrix, γ::Float64)
    smooth!(o.A, o2.A, γ)
    smooth!(o.b, o2.b, γ)
end


#---------------------------------------------------------------------------# Extremas
"""
Extremas (maximum and minimum) of multiple series.

```julia
x = rand(1000,5)
o = Extremas(5)
fit!(o, x)
extrema(o)
```
"""
type Extremas <: OnlineStat{VectorInput}
    min::VecF
    max::VecF
    weight::EqualWeight
    Extremas(p::Int) = new(zeros(p)+Inf, zeros(p)-Inf, EqualWeight())
    Extremas{T<:Real}(y::AMat{T}) = new(squeeze(minimum(y,1),1), squeeze(maximum(y,1),1),
                                        EqualWeight(size(y,1)))
end
function _fit!(o::Extremas, y::AVec, γ::Float64)
    for i in 1:length(y)
        o.min[i] = min(o.min[i], y[i])
        o.max[i] = max(o.max[i], y[i])
    end
    o
end
Base.extrema(o::Extremas) = [(min,max) for (min,max) in zip(o.min,o.max)]
Base.minimum(o::Extremas) = o.min
Base.maximum(o::Extremas) = o.max
value(o::Extremas) = extrema(o)
function _merge!(o::Extremas, o2::Extremas, γ::Float64)
    @assert length(o.min)==length(o2.min)
    for i in 1:length(o.min)
        o.min[i] = min(o.min[i], o2.min[i])
        o.max[i] = max(o.max[i], o2.max[i])
    end
end





#------------------------------------------------------------------------# Diff/Diffs
"""
Track the last value and the last difference.

```julia
o = Diff()
o = Diff(y)
```
"""
type Diff{T <: Real} <: OnlineStat{ScalarInput}
    diff::T
    lastval::T
    weight::EqualWeight
end
Diff() = Diff(0.0, 0.0, EqualWeight())
Diff{T<:Real}(::Type{T}) = Diff(zero(T), zero(T), EqualWeight())
Diff{T<:Real}(x::AVec{T}) = (o = Diff(T); fit!(o, x); o)
value(o::Diff) = o.diff
Base.last(o::Diff) = o.lastval
Base.diff(o::Diff) = o.diff
function _fit!{T<:AbstractFloat}(o::Diff{T}, x::Real, γ::Float64)
    v = convert(T, x)
    o.diff = (nobs(o) == 0 ? zero(T) : v - last(o))
    o.lastval = v
end
function _fit!{T<:Integer}(o::Diff{T}, x::Real, γ::Float64)
    v = round(T, x)
    o.diff = (nobs(o) == 0 ? zero(T) : v - last(o))
    o.lastval = v
end


"""
Track the last value and the last difference for multiple series.  Ignores `Weight`.

```julia
o = Diffs()
o = Diffs(y)
```
"""
type Diffs{T <: Real} <: OnlineStat{VectorInput}
    diffs::Vector{T}
    lastvals::Vector{T}
    weight::EqualWeight
end
Diffs(p::Integer) = Diffs(zeros(p), zeros(p), EqualWeight())
Diffs{T<:Real}(::Type{T}, p::Integer) = Diffs(zeros(T,p), zeros(T,p), EqualWeight())
Diffs{T<:Real}(x::AMat{T}) = (o = Diffs(T,ncols(x)); fit!(o, x); o)

value(o::Diffs) = o.diffs
Base.last(o::Diffs) = o.lastvals
Base.diff(o::Diffs) = o.diffs
function _fit!{T<:Real}(o::Diffs{T}, x::AVec{T}, γ::Float64)
    o.diffs = (nobs(o) == 0 ? zeros(T,length(o.diffs)) : x - last(o))
    o.lastvals = collect(x)
    o
end

#-------------------------------------------------------------------# Sum/Sums
"""
Track the running sum.  Ignores `Weight`.

```julia
o = Sum()
o = Sum(y)
```
"""
type Sum{T <: Real} <: OnlineStat{ScalarInput}
    sum::T
    weight::EqualWeight
end
Sum() = Sum(0.0, EqualWeight())
Sum{T<:Real}(::Type{T}) = Sum(zero(T), EqualWeight())
Sum{T<:Real}(x::AVec{T}) = (o = Sum(T); fit!(o, x); o)
value(o::Sum) = o.sum
Base.sum(o::Sum) = o.sum
function _fit!{T<:AbstractFloat}(o::Sum{T}, x::Real, γ::Float64)
    v = convert(T, x)
    o.sum += v
end
function _fit!{T<:Integer}(o::Sum{T}, x::Real, γ::Float64)
    v = round(T, x)
    o.sum += v
end

"""
Track the running sum for multiple series.  Ignores `Weight`.

```julia
o = Sums()
o = Sums(y)
```
"""
type Sums{T <: Real} <: OnlineStat{VectorInput}
    sums::Vector{T}
    weight::EqualWeight
end
Sums(p::Integer) = Sums(zeros(p), EqualWeight())
Sums{T<:Real}(::Type{T}, p::Integer) = Sums(zeros(T,p), EqualWeight())
Sums{T<:Real}(x::AMat{T}) = (o = Sums(T, ncols(x)); fit!(o, x); o)

value(o::Sums) = o.sums
Base.sum(o::Sums) = o.sums
function _fit!{T<:Real}(o::Sums{T}, x::AVec{T}, γ::Float64)
    for i in eachindex(x)
        o.sums[i] += x[i]
    end
end
