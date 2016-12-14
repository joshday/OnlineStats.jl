#------------------------------------------------------------------------------# Mean
"""
Mean of a single series.

```julia
y = randn(100)

o = Mean()
fit!(o, y)

o = Mean(y)
```
"""
type Mean{W <: Weight} <: OnlineStat{ScalarInput}
    value::Float64
    weight::W
end
Mean(wt::Weight = EqualWeight()) = Mean(0.0, wt)
_fit!(o::Mean, y::Real, γ::Float64) = (o.value = smooth(o.value, y, γ))
function _fitbatch!{W <: BatchWeight}(o::Mean{W}, y::AVec, γ::Float64)
    o.value = smooth(o.value, mean(y), γ)
end
Base.mean(o::Mean) = value(o)
center(o::Mean, x::Real) = x - mean(o)
_merge!(o::Mean, o2::Mean, γ) = _fit!(o, mean(o2), γ)


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


#--------------------------------------------------------------------------# Variance
"""
Univariate variance.

```julia
y = randn(100)
o = Variance(y)
mean(o)
var(o)
std(o)
```
"""
type Variance{W <: Weight} <: OnlineStat{ScalarInput}
    value::Float64
    μ::Float64
    weight::W
end
Variance(wgt::Weight = EqualWeight()) = Variance(0.0, 0.0, wgt)
function _fit!(o::Variance, y::Real, γ::Float64)
    μ = o.μ
    o.μ = smooth(o.μ, y, γ)
    o.value = smooth(o.value, (y - o.μ) * (y - μ), γ)
end
Base.var(o::Variance) = value(o)
Base.std(o::Variance) = sqrt(var(o))
Base.mean(o::Variance) = o.μ
value(o::Variance) = nobs(o) < 2 ? 0.0 : o.value * unbias(o)
center(o::Variance, x::Real) = x - mean(o)
function StatsBase.zscore(o::Variance, x::Real)
    σ = std(o)
    σ == 0.0 ? 1.0 : center(o, x) / σ
end
function _merge!(o::Variance, o2::Variance, γ)
    δ = mean(o2) - mean(o)
    o.value = smooth(o.value, o2.value, γ) + δ ^ 2 * γ * (1.0 - γ)
    o.μ = smooth(o.μ, o2.μ, γ)
end


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
Base.std(o::Variances) = sqrt(value(o))
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
Base.std(o::CovMatrix) = sqrt(var(o))
function Base.cor(o::CovMatrix)
    copy!(o.cormat, value(o))
    v = 1.0 ./ sqrt(diag(o.cormat))
    scale!(o.cormat, v)
    scale!(v, o.cormat)
    o.cormat
end
function _merge!(o::CovMatrix, o2::CovMatrix, γ::Float64)
    smooth!(o.A, o2.A, γ)
    smooth!(o.b, o2.b, γ)
end


#---------------------------------------------------------------------------# Extrema
"""
Extrema (maximum and minimum).

```julia
o = Extrema(y)
fit!(o, y2)
extrema(o)
```
"""
type Extrema <: OnlineStat{ScalarInput}
    min::Float64
    max::Float64
    weight::EqualWeight
    Extrema() = new(Inf, -Inf, EqualWeight())
    Extrema{T<:Real}(y::AVec{T}) = new(minimum(y), maximum(y), EqualWeight(length(y)))
end
function _fit!(o::Extrema, y::Real, γ::Float64)
    o.min = min(o.min, y)
    o.max = max(o.max, y)
    o
end
Base.extrema(o::Extrema) = (o.min, o.max)
value(o::Extrema) = extrema(o)
function _merge!(o::Extrema, o2::Extrema, γ::Float64)
    o.min = min(o.min, o2.min)
    o.max = max(o.max, o2.max)
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
value(o::Extremas) = extrema(o)
function _merge!(o::Extremas, o2::Extremas, γ::Float64)
    @assert length(o.min)==length(o2.min)
    for i in 1:length(o.min)
        o.min[i] = min(o.min[i], o2.min[i])
        o.max[i] = max(o.max[i], o2.max[i])
    end
end



#-----------------------------------------------------------------------# QuantileSGD
"""
Approximate quantiles via stochastic gradient descent.

```julia
o = QuantileSGD(y, LearningRate())
o = QuantileSGD(y, tau = [.25, .5, .75])
fit!(o, y2)
```
"""
type QuantileSGD{W <: StochasticWeight} <: OnlineStat{ScalarInput}
    value::VecF
    τ::VecF
    weight::W
end
function QuantileSGD(wgt::StochasticWeight = LearningRate();
        tau::VecF = [0.25, 0.5, 0.75], value::VecF = zeros(length(tau))
    )
    for τ in tau
        @assert 0 < τ < 1
    end
    QuantileSGD(value, tau, wgt)
end
function _fit!(o::QuantileSGD, y::Float64, γ::Float64)
    @inbounds for i in 1:length(o.τ)
        v = Float64(y < o.value[i]) - o.τ[i]
        o.value[i] = subgrad(o.value[i], γ, v)
    end
end
function _fitbatch!{T <: Real}(o::QuantileSGD, y::AVec{T}, γ::Float64)
    n2 = length(y)
    γ = γ / n2
    @inbounds for yi in y
        for i in 1:length(o.τ)
            v = Float64(yi < o.value[i]) - o.τ[i]
            o.value[i] = subgrad(o.value[i], γ, v)
        end
    end
end
function Base.show(io::IO, o::QuantileSGD)
    printheader(io, "QuantileSGD, τ = $(o.τ)")
    print_value_and_nobs(io, o)
end


#------------------------------------------------------------------------# QuantileMM
"""
Approximate quantiles via an online MM algorithm.  Typically more accurate than
`QuantileSGD`.

```julia
o = QuantileMM(y, LearningRate())
o = QuantileMM(y, tau = [.25, .5, .75])
fit!(o, y2)
```
"""
type QuantileMM{W <: Weight} <: OnlineStat{ScalarInput}
    value::VecF
    τ::VecF
    # "sufficient statistics"
    s::VecF
    t::VecF
    o::Float64

    weight::W
end
function QuantileMM(wgt::Weight = LearningRate();
        tau::VecF = [0.25, 0.5, 0.75], value::VecF = zeros(length(tau))
    )
    p = length(tau)
    for τ in tau
        @assert 0 < τ < 1
    end
    QuantileMM(value, tau, zeros(p), zeros(p), 0.0, wgt)
end
function _fit!(o::QuantileMM, y::Real, γ::Float64)
    o.o = smooth(o.o, 1.0, γ)
    @inbounds for j in 1:length(o.τ)
        w::Float64 = 1.0 / (abs(y - o.value[j]) + _ϵ)
        o.s[j] = smooth(o.s[j], w * y, γ)
        o.t[j] = smooth(o.t[j], w, γ)
        o.value[j] = (o.s[j] + o.o * (2.0 * o.τ[j] - 1.0)) / o.t[j]
    end
end
function _fitbatch!{T <: Real}(o::QuantileMM, y::AVec{T}, γ::Float64)
    n2 = length(y)
    γ = γ / n2
    o.o = smooth(o.o, 1.0, γ)
    @inbounds for yi in y
        for j in 1:length(o.τ)
            w::Float64 = 1.0 / abs(yi - o.value[j])
            o.s[j] = smooth(o.s[j], w * yi, γ)
            o.t[j] = smooth(o.t[j], w, γ)
        end
    end
    @inbounds for j in 1:length(o.τ)
        o.value[j] = (o.s[j] + o.o * (2.0 * o.τ[j] - 1.0)) / o.t[j]
    end
    o
end
function Base.show(io::IO, o::QuantileMM)
    printheader(io, "QuantileMM, τ = $(o.τ)")
    print_value_and_nobs(io, o)
end


#-------------------------------------------------------------------# OrderStatistics
"""
```julia
o = OrderStatistics(p)
```

Ignores Weight.  Track the online mean of order statistics (sorted data from smallest
to largest).  For every batch of `p` observations, sort the points and update the mean.
"""
type OrderStatistics <: OnlineStat{ScalarInput}
    value::VecF
    buffer::VecF
    weight::EqualWeight
end
OrderStatistics(p::Integer) = OrderStatistics(zeros(p), zeros(p), EqualWeight())
function OrderStatistics(p::Integer, y::AVec)
    o = OrderStatistics(p)
    fit!(o, y)
end
function _fit!(o::OrderStatistics, y::Real, γ::Float64)
    p = length(o.value)
    buffer = o.buffer
    i = (nobs(o) % p) + 1
    @inbounds buffer[i] = y
    if i == p
        sort!(buffer)
        nreps = div(nobs(o), p - 1)
        smooth!(o.value, buffer, 1 / nreps)
    end
    o
end


#---------------------------------------------------------------------------# Moments
"""
Univariate, first four moments.  Provides `mean`, `var`, `skewness`, `kurtosis`

```julia
o = Moments(x, EqualWeight())
o = Moments(x)
fit!(o, x2)

mean(o)
var(o)
std(o)
StatsBase.skewness(o)
StatsBase.kurtosis(o)
```
"""
type Moments{W <: Weight} <: OnlineStat{ScalarInput}
    value::VecF
    weight::W
    n::Int
    nups::Int
end
Moments(wgt::Weight = EqualWeight()) = Moments(zeros(4), wgt, 0, 0)
function _fit!(o::Moments, y::Real, γ::Float64)
    o.value[1] = smooth(o.value[1], y, γ)
    o.value[2] = smooth(o.value[2], y * y, γ)
    o.value[3] = smooth(o.value[3], y * y * y, γ)
    o.value[4] = smooth(o.value[4], y * y * y * y, γ)
end
Base.mean(o::Moments) = value(o)[1]
Base.var(o::Moments) = (value(o)[2] - value(o)[1] ^ 2) * unbias(o)
Base.std(o::Moments) = sqrt(var(o))
function StatsBase.skewness(o::Moments)
    v = value(o)
    (v[3] - 3.0 * v[1] * var(o) - v[1] ^ 3) / var(o) ^ 1.5
end
function StatsBase.kurtosis(o::Moments)
    v = value(o)
    (v[4] - 4.0 * v[1] * v[3] + 6.0 * v[1] ^ 2 * v[2] - 3.0 * v[1] ^ 4) / var(o) ^ 2 - 3.0
end
function Base.show(io::IO, o::Moments)
    printheader(io, "Moments")
    print_item(io, "mean", mean(o))
    print_item(io, "var", var(o))
    print_item(io, "skewness", skewness(o))
    print_item(io, "kurtosis", kurtosis(o))
    print_item(io, "nobs", nobs(o))
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


#----------------------------------------------------------# convenience constructors
for nm in [:Mean, :Variance, :Moments]
    @eval begin
        function $nm{T <: Real}(y::AVec{T}, wgt::Weight = EqualWeight(); kw...)
            o = $nm(wgt; kw...)
            fit!(o, y)
            o
        end
    end
end
for nm in [:QuantileSGD, :QuantileMM]
    @eval begin
        function $nm{T <: Real}(y::AVec{T}, wgt::Weight = LearningRate(); kw...)
            o = $nm(wgt; kw...)
            fit!(o, y)
            o
        end
    end
end
for nm in [:Means, :CovMatrix]
    @eval begin
        function $nm{T <: Real}(y::AMat{T}, wgt::Weight = EqualWeight())
            o = $nm(size(y, 2), wgt)
            fit!(o, y, size(y, 1))
            o
        end
    end
end
for nm in [:Variances]
    @eval begin
        function $nm{T <: Real}(y::AMat{T}, wgt::Weight = EqualWeight())
            o = $nm(size(y, 2), wgt)
            fit!(o, y)
            o
        end
    end
end
