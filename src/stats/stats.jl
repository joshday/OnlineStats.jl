#-----------------------------------------------------------------------# Mean
"""
    Mean()

Univariate mean.

# Example

    s = Series(randn(100), Mean())
    value(s)
"""
mutable struct Mean <: ExactStat{0}
    μ::Float64
    Mean(μ = 0.0) = new(μ)
end
fit!(o::Mean, y::Real, γ::Float64) = (o.μ = smooth(o.μ, y, γ))
Base.merge!(o::Mean, o2::Mean, γ::Float64) = (fit!(o, value(o2), γ); o)
Base.mean(o::Mean) = value(o)


#-----------------------------------------------------------------------# Variance
"""
    Variance()

Univariate variance.

# Example

    s = Series(randn(100), Variance())
    value(s)
"""
mutable struct Variance <: ExactStat{0}
    σ2::Float64     # biased variance
    μ::Float64
    nobs::Int
    Variance() = new(0.0, 0.0, 0)
end
function fit!(o::Variance, y::Real, γ::Float64)
    μ = o.μ
    o.nobs += 1
    o.μ = smooth(o.μ, y, γ)
    o.σ2 = smooth(o.σ2, (y - o.μ) * (y - μ), γ)
end
function Base.merge!(o::Variance, o2::Variance, γ::Float64)
    o.nobs += o2.nobs
    δ = o2.μ - o.μ
    o.σ2 = smooth(o.σ2, o2.σ2, γ) + δ ^ 2 * γ * (1.0 - γ)
    o.μ = smooth(o.μ, o2.μ, γ)
    o
end
_value(o::Variance) = o.nobs < 2 ? 0.0 : o.σ2 * unbias(o)
Base.var(o::Variance) = value(o)
Base.std(o::Variance) = sqrt(var(o))
Base.mean(o::Variance) = o.μ
nobs(o::Variance) = o.nobs

#-----------------------------------------------------------------------# CStat
"""
    CStat(stat)

Track a univariate OnlineStat for complex numbers.  A copy of `stat` is made to
separately track the real and imaginary parts.

# Example

    y = randn(100) + randn(100)im
    Series(y, CStat(Mean()))
"""
struct CStat{O <: OnlineStat} <: OnlineStat{0}
    re_stat::O
    im_stat::O
end
default_weight(o::CStat) = default_weight(o.re_stat)
CStat(o::OnlineStat{0}) = CStat(o, copy(o))
Base.show(io::IO, o::CStat) = print(io, "CStat: re = $(o.re_stat), im = $(o.im_stat)")
_value(o::CStat) = value(o.re_stat), value(o.im_stat)
function fit!(o::CStat, y::Real, γ::Float64) 
    fit!(o.re_stat, real(y), γ)
    fit!(o.im_stat, complex(y, γ).im, γ)
end
function Base.merge!(o1::T, o2::T, γ::Float64) where {T<:CStat}
    merge!(o1.re_stat, o2.re_stat, γ)
    merge!(o1.im_stat, o2.im_stat, γ)
end

#-----------------------------------------------------------------------# Count 
"""
    Count()

The number of things observed.
"""
mutable struct Count <: ExactStat{0}
    n::Int
    Count() = new(0)
end
fit!(o::Count, y::Real, γ::Float64) = (o.n += 1)
Base.merge!(o::Count, o2::Count, γ::Float64) = (o.n += o2.n)


#-----------------------------------------------------------------------# CountMap
"""
    CountMap(T)

Maintain a dictionary mapping unique values to its number of occurrences.  Ignores weight 
and is equivalent to `StatsBase.countmap`.

# Example 

    s = Series(rand(1:10, 1000), CountMap(Int))
    value(s)[1]

    vals = ["small", "medium", "large"]
    o = CountMap(String)
    s = Series(rand(vals, 1000), o)
    value(o)
"""
struct CountMap{T} <: ExactStat{0}
    d::Dict{T, Int}
end
CountMap(T::Type) = CountMap(Dict{T, Int}())
fit!{T}(o::CountMap{T}, y::T, γ::Float64) = haskey(o, y) ? (o.d[y] += 1) : (o.d[y] = 1)
Base.merge!(o::CountMap, o2::CountMap, γ::Float64) = merge!(+, o.d, o2.d)
nobs(o::CountMap) = sum(values(o))

Base.keys(o::CountMap) = keys(o.d)
Base.values(o::CountMap) = values(o.d)
Base.haskey(o::CountMap, key) = haskey(o.d, key)

@deprecate FitCategorical(t::Type) CountMap(t::Type)

#-----------------------------------------------------------------------# CovMatrix
"""
    CovMatrix(d)

Covariance Matrix of `d` variables.  Principal component analysis can be performed using
eigen decomposition of the covariance or correlation matrix.

# Example

    y = randn(100, 5)
    o = CovMatrix(5)
    Series(y, o)

    # PCA
    evals, evecs = eig(cor(o))
"""
mutable struct CovMatrix <: ExactStat{1}
    value::Matrix{Float64}
    cormat::Matrix{Float64}
    A::Matrix{Float64}  # X'X / n
    b::Vector{Float64}  # X * 1' / n (column means)
    nobs::Int
    CovMatrix(p::Integer) = new(zeros(p, p), zeros(p, p), zeros(p, p), zeros(p), 0)
end
function fit!(o::CovMatrix, x::VectorOb, γ::Float64)
    smooth!(o.b, x, γ)
    smooth_syr!(o.A, x, γ)
    o.nobs += 1
    o
end
function _value(o::CovMatrix)
    o.value[:] = full(Symmetric((o.A - o.b * o.b')))
    scale!(o.value, unbias(o))
end
Base.length(o::CovMatrix) = length(o.b)
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
function Base.merge!(o::CovMatrix, o2::CovMatrix, γ::Float64)
    smooth!(o.A, o2.A, γ)
    smooth!(o.b, o2.b, γ)
    o.nobs += o2.nobs
    o
end

#-----------------------------------------------------------------------# Diff
"""
    Diff()

Track the difference and the last value.

# Example

    s = Series(randn(1000), Diff())
    value(s)
"""
mutable struct Diff{T <: Real} <: ExactStat{0}
    diff::T
    lastval::T
end
Diff() = Diff(0.0, 0.0)
Diff(::Type{T}) where {T<:Real} = Diff(zero(T), zero(T))
Base.last(o::Diff) = o.lastval
Base.diff(o::Diff) = o.diff
function fit!(o::Diff{T}, x::Real, γ::Float64) where {T<:AbstractFloat}
    v = convert(T, x)
    o.diff = v - last(o)
    o.lastval = v
end
function fit!(o::Diff{T}, x::Real, γ::Float64) where {T<:Integer}
    v = round(T, x)
    o.diff = v - last(o)
    o.lastval = v
end

#-----------------------------------------------------------------------# Extrema
"""
    Extrema()

Maximum and minimum.

# Example

    s = Series(randn(100), Extrema())
    value(s)
"""
mutable struct Extrema <: ExactStat{0}
    min::Float64
    max::Float64
    Extrema() = new(Inf, -Inf)
end
function fit!(o::Extrema, y::Real, γ::Float64)
    o.min = min(o.min, y)
    o.max = max(o.max, y)
    o
end
function Base.merge!(o::Extrema, o2::Extrema, γ::Float64)
    o.min = min(o.min, o2.min)
    o.max = max(o.max, o2.max)
    o
end
_value(o::Extrema) = (o.min, o.max)
Base.extrema(o::Extrema) = value(o)

#-----------------------------------------------------------------------# HyperLogLog
# Mostly copy/pasted from StreamStats.jl
"""
    HyperLogLog(b)  # 4 ≤ b ≤ 16

Approximate count of distinct elements.

# Example

    s = Series(rand(1:10, 1000), HyperLogLog(12))
    value(s)
"""
mutable struct HyperLogLog <: StochasticStat{0}
    m::UInt32
    M::Vector{UInt32}
    mask::UInt32
    altmask::UInt32
    function HyperLogLog(b::Integer)
        !(4 ≤ b ≤ 16) && throw(ArgumentError("b must be an Integer between 4 and 16"))
        m = 0x00000001 << b
        M = zeros(UInt32, m)
        mask = 0x00000000
        for i in 1:(b - 1)
            mask |= 0x00000001
            mask <<= 1
        end
        mask |= 0x00000001
        altmask = ~mask
        new(m, M, mask, altmask)
    end
end
function Base.show(io::IO, counter::HyperLogLog)
    print(io, "HyperLogLog($(counter.m) registers, estimate = $(value(counter)))")
end

hash32(d::Any) = hash(d) % UInt32
maskadd32(x::UInt32, mask::UInt32, add::UInt32) = (x & mask) + add
ρ(s::UInt32) = UInt32(leading_zeros(s)) + 0x00000001

function α(m::UInt32)
    if m == 0x00000010          # m = 16
        return 0.673
    elseif m == 0x00000020      # 
        return 0.697
    elseif m == 0x00000040
        return 0.709
    else                        # if m >= UInt32(128)
        return 0.7213 / (1 + 1.079 / m)
    end
end


function fit!(o::HyperLogLog, v::Any, γ::Float64)
    x = hash32(v)
    j = maskadd32(x, o.mask, 0x00000001)
    w = x & o.altmask
    o.M[j] = max(o.M[j], ρ(w))
    o
end

function _value(o::HyperLogLog)
    S = 0.0
    for j in eachindex(o.M)
        S += 1 / (2 ^ o.M[j])
    end
    Z = 1 / S
    E = α(o.m) * UInt(o.m) ^ 2 * Z
    if E <= 5//2 * o.m
        V = 0
        for j in 1:o.m
            V += Int(o.M[j] == 0x00000000)
        end
        if V != 0
            E_star = o.m * log(o.m / V)
        else
            E_star = E
        end
    elseif E <= 1//30 * 2 ^ 32
        E_star = E
    else
        E_star = -2 ^ 32 * log(1 - E / (2 ^ 32))
    end
    return E_star
end

function Base.merge!(o::HyperLogLog, o2::HyperLogLog, γ::Float64)
    length(o.M) == length(o2.M) || 
        error("Merge failed. HyperLogLog objects have different number of registers.")
    for j in eachindex(o.M)
        o.M[j] = max(o.M[j], o2.M[j])
    end
end

#-----------------------------------------------------------------------# KMeans
"""
    KMeans(p, k)

Approximate K-Means clustering of `k` clusters and `p` variables.

# Example

    using OnlineStats, Distributions
    d = MixtureModel([Normal(0), Normal(5)])
    y = rand(d, 100_000, 1)
    s = Series(y, LearningRate(.6), KMeans(1, 2))
"""
mutable struct KMeans{U <: Updater} <: StochasticStat{1}
    value::Matrix{Float64}  # p × k
    v::Vector{Float64}
    n::Int
    updater::U
end
KMeans(p::Integer, k::Integer, u::Updater = SGD()) = KMeans(zeros(p, k), zeros(k), 0, u)
function fit!(o::KMeans{<:SGD}, x::VectorOb, γ::Float64)
    o.n += 1
    p, k = size(o.value)
    if o.n <= k 
        o.value[:, o.n] = x
    else
        for j in 1:k
            o.v[j] = sum(abs2, x - view(o.value, :, j))
        end
        kstar = indmin(o.v)
        for i in eachindex(x)
            o.value[i, kstar] = smooth(o.value[i, kstar], x[i], γ)
        end
    end
end

#-----------------------------------------------------------------------# Lag 
"""
    Lag(b, T = Float64)

Store the last `b` values for a data stream of type `T`.
"""
struct Lag{T} <: ExactStat{0}
    value::Vector{T}
end
Lag(b::Integer, T::Type = Float64) = Lag(zeros(T, b))
function fit!(o::Lag{T}, y::T, γ::Float64) where {T} 
    for i in reverse(2:length(o.value))
        @inbounds o.value[i] = o.value[i - 1]
    end
    o.value[1] = y
end

#-----------------------------------------------------------------------# AutoCov 
"""
    AutoCov(b, T = Float64)

Calculate the auto-covariance/correlation for lags 0 to `b` for a data stream of type `T`.

# Example 

    y = cumsum(randn(100))
    o = AutoCov(5)
    Series(y, o)
    autocov(o)
    autocor(o)
"""
struct AutoCov{T} <: ExactStat{0}
    cross::Vector{Float64}
    m1::Vector{Float64}
    m2::Vector{Float64}
    lag::Lag{T}         # y_{t-1}, y_{t-2}, ...
    wlag::Lag{Float64}  # γ_{t-1}, γ_{t-2}, ...
    v::Variance
end
function AutoCov(k::Integer, T = Float64)
    AutoCov(
        zeros(k + 1), zeros(k + 1), zeros(k + 1),
        Lag(k + 1, T), Lag(k + 1, Float64), Variance()
    )
end
Base.show(io::IO, o::AutoCov) = println(io, "AutoCov: $(value(o))")
nobs(o::AutoCov) = nobs(o.v)

function fit!(o::AutoCov, y::Real, γ::Float64)
    fit!(o.v, y, γ)
    fit!(o.lag, y, 1.0)     # y_t, y_{t-1}, ...
    fit!(o.wlag, γ, 1.0)    # γ_t, γ_{t-1}, ...
    # M1 ✓
    for k in reverse(2:length(o.m2))
        @inbounds o.m1[k] = o.m1[k - 1]
    end
    @inbounds o.m1[1] = smooth(o.m1[1], y, γ)
    # Cross ✓ and M2 ✓
    @inbounds for k in 1:length(o.m1)
        γk = value(o.wlag)[k]
        o.cross[k] = smooth(o.cross[k], y * value(o.lag)[k], γk)
        o.m2[k] = smooth(o.m2[k], y, γk)
    end
end

function value(o::AutoCov)
    μ = mean(o.v)
    n = nobs(o)
    cr = o.cross
    m1 = o.m1
    m2 = o.m2
    [(n - k + 1) / n * (cr[k] + μ * (μ - m1[k] - m2[k])) for k in 1:length(m1)]
end
autocov(o::AutoCov) = value(o)
autocor(o::AutoCov) = value(o) ./ value(o)[1]


#-----------------------------------------------------------------------# Moments
"""
    Moments()

First four non-central moments.

# Example

    s = Series(randn(1000), Moments(10))
    value(s)
"""
mutable struct Moments <: ExactStat{0}
    m::Vector{Float64}
    nobs::Int
    Moments() = new(zeros(4), 0)
end
function fit!(o::Moments, y::Real, γ::Float64)
    o.nobs += 1
    @inbounds o.m[1] = smooth(o.m[1], y, γ)
    @inbounds o.m[2] = smooth(o.m[2], y * y, γ)
    @inbounds o.m[3] = smooth(o.m[3], y * y * y, γ)
    @inbounds o.m[4] = smooth(o.m[4], y * y * y * y, γ)
end
Base.mean(o::Moments) = o.m[1]
Base.var(o::Moments) = (o.m[2] - o.m[1] ^ 2) * unbias(o)
Base.std(o::Moments) = sqrt.(var(o))
function skewness(o::Moments)
    v = value(o)
    (v[3] - 3.0 * v[1] * var(o) - v[1] ^ 3) / var(o) ^ 1.5
end
function kurtosis(o::Moments)
    v = value(o)
    (v[4] - 4.0 * v[1] * v[3] + 6.0 * v[1] ^ 2 * v[2] - 3.0 * v[1] ^ 4) / var(o) ^ 2 - 3.0
end
function Base.merge!(o1::Moments, o2::Moments, γ::Float64)
    smooth!(o1.m, o2.m, γ)
    o1.nobs += o2.nobs
    o1
end

#-----------------------------------------------------------------------# OrderStats
"""
    OrderStats(b)

Average order statistics with batches of size `b`.  Ignores weight.

# Example
    s = Series(randn(1000), OrderStats(10))
    value(s)
"""
mutable struct OrderStats <: ExactStat{0}
    value::Vector{Float64}
    buffer::Vector{Float64}
    i::Int
    nreps::Int
    OrderStats(p::Integer) = new(zeros(p), zeros(p), 0, 0)
end
function fit!(o::OrderStats, y::Real, γ::Float64)
    p = length(o.value)
    buffer = o.buffer
    o.i += 1
    @inbounds buffer[o.i] = y
    if o.i == p
        sort!(buffer)
        o.nreps += 1
        o.i = 0
        smooth!(o.value, buffer, 1 / o.nreps)
    end
    o
end
function Base.merge!(o::OrderStats, o2::OrderStats, γ::Float64)
    length(o.value) == length(o2.value) || 
        error("Merge failed.  OrderStats track different batch sizes")
    for i in 1:o2.i 
        o2.value[i] = smooth(o2.value[i], o2.buffer[i], 1 / o.nreps)
    end
    smooth!(o.value, o2.value, γ)
end
Base.quantile(o::OrderStats, arg...) = quantile(value(o), arg...)

#-----------------------------------------------------------------------# PQuantile 
"""
    PQuantile(τ = 0.5)

Calculate the approximate quantile via the P^2 algorithm.  It is more computationally
expensive than the algorithms used by [`Quantile`](@ref), but also more exact.

Ref: [https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf](https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf)

# Example

    y = randn(10^6)
    o1, o2, o3 = PQuantile(.25), PQuantile(.5), PQuantile(.75)
    s = Series(y, o1, o2, o3)
    value(s)
    quantile(y, [.25, .5, .75])
"""
mutable struct PQuantile <: StochasticStat{0}
    q::Vector{Float64}  # marker heights
    n::Vector{Int}  # marker position
    nprime::Vector{Float64}
    τ::Float64
    nobs::Int
end
function PQuantile(τ::Real = 0.5)
    @assert 0 < τ < 1
    nprime = [1, 1 + 2τ, 1 + 4τ, 3 + 2τ, 5]
    PQuantile(zeros(5), collect(1:5), nprime, τ, 0)
end
Base.show(io::IO, o::PQuantile) = print(io, "PQuantile($(o.τ), $(value(o)))")
value(o::PQuantile) = o.q[3]
function fit!(o::PQuantile, y::Real, γ::Float64)
    o.nobs += 1
    q = o.q
    n = o.n
    nprime = o.nprime
    @inbounds if o.nobs > 5
        # B1
        k = searchsortedfirst(q, y) - 1
        k = min(k, 4)
        k = max(k, 1)
        q[1] = min(q[1], y)
        q[5] = max(q[5], y)
        # B2
        for i in (k+1):5
            n[i] += 1
        end
        nprime[2] += o.τ / 2
        nprime[3] += o.τ
        nprime[4] += (1 + o.τ) / 2
        nprime[5] += 1
        # B3
        for i in 2:4
            _interpolate!(o.q, o.n, nprime[i] - n[i], i)
        end
    # A
    elseif o.nobs < 5
        @inbounds o.q[o.nobs] = y
    else 
        @inbounds o.q[o.nobs] = y
        sort!(o.q)
    end
end

function _interpolate!(q, n, di, i)
    @inbounds q1, q2, q3 = q[i-1], q[i], q[i+1]
    @inbounds n1, n2, n3 = n[i-1], n[i], n[i+1]
    @inbounds if (di ≥ 1 && n3 - n2 > 1) || (di ≤ -1 && n1 - n2 < -1)
        d = Int(sign(di))
        df = sign(di)
        v1 = (n2 - n1 + d) * (q3 - q2) / (n3 - n2) 
        v2 = (n3 - n2 - d) * (q2 - q1) / (n2 - n1) 
        qi = q2 + df / (n3 - n1) * (v1 + v2) 
        if q1 < qi < q3 
            q[i] = qi
        else
            q[i] += df * (q[i + d] - q2) / (n[i + d] - n2)
        end
        n[i] += d
    end
end

function parabolic_interpolate(q1, q2, q3, n1, n2, n3, d)
    qi = q2 + d / (n3 - n1) * 
        ((n2 - n1 + d) * (q3 - q2) / (n3 - n2) + (n3 - n2 - d) * (q2 - q1) / (n2 - n1))
end



#-----------------------------------------------------------------------# Quantile
"""
    Quantile(q = [.25, .5, .75], alg = OMAS())

Approximate the quantiles `q` via the stochastic approximation algorithm `alg`.  Options
are `SGD`, `MSPI`, and `OMAS`.  In practice, `SGD` and `MSPI` only work well when the
variance of the data is small.

# Example

    y = randn(10_000)
    τ = collect(.1:.1:.0)
    Series(y, Quantile(τ, SGD()), Quantile(τ, MSPI()), Quantile(τ, OMAS()))
"""
mutable struct Quantile{T <: Updater} <: StochasticStat{0}
    value::Vector{Float64}
    τ::Vector{Float64}
    updater::T 
    n::Int
end
function Quantile(τ::AbstractVector = [.25, .5, .75], u::Updater = OMAS()) 
    Quantile(zeros(τ), collect(τ), q_init(u, length(τ)), 0)
end

function Base.show(io::IO, o::Quantile) 
    print(io, "Quantile\{$(name(o.updater, false, false))\}($(value(o)))")
end

function Base.merge!(o::Quantile, o2::Quantile, γ::Float64)
    o.τ == o2.τ || error("Merge failed. Quantile objects track different quantiles.")
    merge!(o.updater, o2.updater, γ)
    smooth!(o.value, o2.value, γ)
end

q_init(u::Updater, p) = error("$u can't be used with Quantile")

function fit!(o::Quantile, y::Real, γ::Float64)
    o.n += 1
    if o.n > length(o.value)
        q_fit!(o, y, γ)
    elseif o.n < length(o.value)
        o.value[o.n] = y  # initialize values with first observations
    else
        o.value[o.n] = y 
        sort!(o.value)
    end
end

# SGD
q_init(u::SGD, p) = u
function q_fit!(o::Quantile{SGD}, y, γ)
    for j in eachindex(o.value)
        @inbounds o.value[j] -= γ * ((o.value[j] > y) - o.τ[j])
    end
end

# ADAGRAD
q_init(u::ADAGRAD, p) = init(u, p)
function q_fit!(o::Quantile{ADAGRAD}, y, γ)
    U = o.updater
    U.nobs += 1
    w = 1 / U.nobs
    for j in eachindex(o.value)
        g = ((o.value[j] > y) - o.τ[j])
        U.h[j] = smooth(U.h[j], g ^ 2, w)
        @inbounds o.value[j] -= γ * g / U.h[j]
    end
end

# MSPI
q_init(u::MSPI, p) = u
function q_fit!(o::Quantile{<:MSPI}, y, γ)
    @inbounds for i in eachindex(o.τ)
        w = inv(abs(y - o.value[i]) + ϵ)
        halfyw = .5 * y * w
        b = o.τ[i] - .5 + halfyw
        o.value[i] = (o.value[i] + γ * b) / (1 + .5 * γ * w)
    end
end

# OMAS
q_init(u::OMAS, p) = OMAS((zeros(p), zeros(p)))
function q_fit!(o::Quantile{<:OMAS}, y, γ)
    s, t = o.updater.buffer
    @inbounds for j in eachindex(o.τ)
        w = inv(abs(y - o.value[j]) + ϵ)
        s[j] = smooth(s[j], w * y, γ)
        t[j] = smooth(t[j], w, γ)
        o.value[j] = (s[j] + (2.0 * o.τ[j] - 1.0)) / t[j]
    end
end

# OMAP...why is this so bad?
q_init(u::OMAP, p) = u
function q_fit!(o::Quantile{<:OMAP}, y, γ)
    for j in eachindex(o.τ)
        w = abs(y - o.value[j]) + ϵ
        θ = y + w * (2o.τ[j] - 1) 
        o.value[j] = smooth(o.value[j], θ, γ)
    end
end

#-----------------------------------------------------------------------# ReservoirSample
"""
    ReservoirSample(k, t = Float64)

Reservoir sample of `k` items.

# Example

    o = ReservoirSample(k, Int)
    s = Series(o)
    fit!(s, 1:10000)
"""
mutable struct ReservoirSample{T<:Number} <: ExactStat{0}
    value::Vector{T}
    nobs::Int
end
function ReservoirSample(k::Integer, ::Type{T} = Float64) where {T<:Number}
    ReservoirSample(zeros(T, k), 0)
end

function fit!(o::ReservoirSample, y::ScalarOb, γ::Float64)
    o.nobs += 1
    if o.nobs <= length(o.value)
        o.value[o.nobs] = y
    else
        j = rand(1:o.nobs)
        if j < length(o.value)
            o.value[j] = y
        end
    end
end

#-----------------------------------------------------------------------# Sum
"""
    Sum()

Track the overall sum.

# Example

    s = Series(randn(1000), Sum())
    value(s)
"""
mutable struct Sum{T <: Real} <: ExactStat{0}
    sum::T
end
Sum() = Sum(0.0)
Sum(::Type{T}) where {T<:Real} = Sum(zero(T))
Base.sum(o::Sum) = o.sum
fit!(o::Sum{T}, x::Real, γ::Float64) where {T<:AbstractFloat} = (v = convert(T, x); o.sum += v)
fit!(o::Sum{T}, x::Real, γ::Float64) where {T<:Integer} =       (v = round(T, x);   o.sum += v)
Base.merge!(o::T, o2::T, γ::Float64) where {T <: Sum} = (o.sum += o2.sum)