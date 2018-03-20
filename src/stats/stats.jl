#-----------------------------------------------------------------------# Bootstrap
"""
    Bootstrap(o::OnlineStat, nreps = 100, d = [0, 2])

Online statistical bootstrap.  Create `nreps` replicates of `o`.  For each call to `fit!`,
a replicate will be updated `rand(d)` times.

# Example

    o = Bootstrap(Variance())
    Series(randn(1000), o)
    confint(o)
"""
struct Bootstrap{N, O <: OnlineStat{N}, D} <: OnlineStat{N}
    stat::O 
    replicates::Vector{O}
    rnd::D
end
function Bootstrap(o::OnlineStat{N}, nreps::Integer = 100, d = [0, 2]) where {N}
    Bootstrap{N, typeof(o), typeof(d)}(o, [copy(o) for i in 1:nreps], d)
end
Base.show(io::IO, b::Bootstrap) = print(io, "Bootstrap($(length(b.replicates))): $(b.stat)")
"""
    confint(b::Bootstrap, coverageprob = .95)

Return a confidence interval for a Bootstrap `b`.
"""
function confint(b::Bootstrap, coverageprob = 0.95)
    states = value.(b.replicates)
    α = 1 - coverageprob
    return (quantile(states, α / 2), quantile(states, 1 - α / 2))
end
function fit_replicates!(b::Bootstrap, yi)
    for r in b.replicates
        for _ in 1:rand(b.rnd)
            _fit!(r, yi)
        end
    end
end
function _fit!(b::Bootstrap, y)
    _fit!(b.stat, y)
    fit_replicates!(b, y)
    b
end

#-----------------------------------------------------------------------# CallFun
"""
    CallFun(o::OnlineStat, f::Function)

Call `f(o)` every time the OnlineStat `o` gets updated.

# Example

    o = CallFun(Mean(), info)
    fit!(o, [0,0,1,1])
"""
struct CallFun{N, O <: OnlineStat{N}, F <: Function} <: OnlineStat{N}
    stat::O
    f::F
end 
CallFun(o::O, f::F) where {N, O<:OnlineStat{N}, F} = CallFun{N, O, F}(o, f)
nobs(o::CallFun) = nobs(o.stat)
value(o::CallFun) = value(o.stat)
Base.show(io::IO, o::CallFun) = print(io, "CallFun: $(o.stat) |> $(o.f)")
_fit!(o::CallFun, arg)  = (_fit!(o.stat, arg); o.f(o.stat))
Base.merge!(o::CallFun, o2::CallFun) = merge!(o.stat, o2.stat)

#-----------------------------------------------------------------------# Count 
"""
    Count()

The number of things observed.

# Example 

    fit!(Count(), 1:1000)
"""
mutable struct Count <: OnlineStat{0}
    n::Int
    Count() = new(0)
end
_fit!(o::Count, x) = (o.n += 1)
Base.merge!(o::Count, o2::Count) = (o.n += o2.n; o)

#-----------------------------------------------------------------------# CountMap 
"""
    CountMap(T::Type)
    CountMap(dict::AbstractDict{T, Int})

Track a dictionary that maps unique values to its number of occurrences.  Similar to 
`StatsBase.countmap`.  

# Example 
    
    fit!(CountMap(Int), rand(1:10, 1000))
"""
struct CountMap{A <: AbstractDict} <: OnlineStat{0}
    value::A  # OrderedDict by default
end
CountMap(T::Type) = CountMap(OrderedDict{T, Int}())
_fit!(o::CountMap, x) = haskey(o.value, x) ? o.value[x] += 1 : o.value[x] = 1
Base.merge!(o::CountMap, o2::CountMap) = (merge!(+, o.value, o2.value); o)
nobs(o::CountMap) = sum(values(o.value))
function probs(o::CountMap, kys = keys(o.value))
    out = zeros(Int, length(kys))
    valkeys = keys(o.value)
    for (i, k) in enumerate(kys)
        out[i] = k in valkeys ? o.value[k] : 0
    end
    sum(out) == 0 ? Float64.(out) : out ./ sum(out)
end
pdf(o::CountMap, y) = y in keys(o.value) ? o.value[y] / nobs(o) : 0.0

#-----------------------------------------------------------------------# CovMatrix 
"""
    CovMatrix(p=0; weight)

Calculate a covariance/correlation matrix of `p` variables.  If the number of variables is 
unknown, leave the default `p=0`.

# Example 

    fit!(CovMatrix(), randn(100, 4))
"""
mutable struct CovMatrix{W} <: OnlineStat{1}
    value::Matrix{Float64}
    A::Matrix{Float64}  # x'x/n
    b::Vector{Float64}  # 1'x/n
    weight::W
    n::Int
end
CovMatrix(p::Int=0;weight = EqualWeight()) = CovMatrix(zeros(p,p), zeros(p,p), zeros(p), weight, 0)
function _fit!(o::CovMatrix, x)
    γ = o.weight(o.n += 1)
    if isempty(o.A)
        p = length(x)
        o.b = Vector{Float64}(undef, p) 
        o.A = Matrix{Float64}(undef, p, p)
        o.value = Matrix{Float64}(undef, p, p)
    end
    smooth!(o.b, x, γ)
    smooth_syr!(o.A, x, γ)
end
function value(o::CovMatrix; corrected::Bool = true)
    o.value[:] = Matrix(Symmetric((o.A - o.b * o.b')))
    corrected && scale!(o.value, unbias(o))
    o.value
end
function Base.merge!(o::CovMatrix, o2::CovMatrix)
    γ = o2.n / (o.n += o2.n)
    smooth!(o.A, o2.A, γ)
    smooth!(o.b, o2.b, γ)
    o
end
Base.cov(o::CovMatrix; corrected::Bool = true) = value(o; corrected=corrected)
Base.mean(o::CovMatrix) = o.b
Base.var(o::CovMatrix; kw...) = diag(value(o; kw...))
function Base.cor(o::CovMatrix; kw...)
    value(o; kw...)
    v = 1.0 ./ sqrt.(diag(o.value))
    scale!(o.value, v)
    scale!(v, o.value)
    o.value
end

#-----------------------------------------------------------------------# CStat
"""
    CStat(stat)

Track a univariate OnlineStat for complex numbers.  A copy of `stat` is made to
separately track the real and imaginary parts.

# Example
    
    y = randn(100) + randn(100)im
    fit!(y, CStat(Mean()))
"""
struct CStat{O <: OnlineStat{0}} <: OnlineStat{0}
    re_stat::O
    im_stat::O
end
CStat(o::OnlineStat{0}) = CStat(o, copy(o))
nobs(o::CStat) = nobs(o.re_stat)
value(o::CStat) = value(o.re_stat), value(o.im_stat)
_fit!(o::CStat, y::T) where {T<:Real} = (_fit!(o.re_stat, y); _fit!(o.im_stat, T(0)))
_fit!(o::CStat, y::Complex) = (_fit!(o.re_stat, y.re); _fit!(o.im_stat, y.im))
function Base.merge!(o::T, o2::T) where {T<:CStat}
    merge!(o.re_stat, o2.re_stat)
    merge!(o.im_stat, o2.im_stat)
end

#-----------------------------------------------------------------------# Diff
"""
    Diff(T::Type = Float64)

Track the difference and the last value.

# Example

    o = Diff()
    fit!(o, [1.0, 2.0])
    last(o)
    diff(o)
"""
mutable struct Diff{T <: Real} <: OnlineStat{0}
    diff::T
    lastval::T
    n::Int
end
Diff(T::Type = Float64) = Diff(zero(T), zero(T), 0)
function _fit!(o::Diff{T}, x) where {T<:AbstractFloat}
    v = convert(T, x)
    o.diff = v - last(o)
    o.lastval = v
    o.n += 1
end
function _fit!(o::Diff{T}, x) where {T<:Integer}
    v = round(T, x)
    o.diff = v - last(o)
    o.lastval = v
    o.n += 1
end
Base.last(o::Diff) = o.lastval
Base.diff(o::Diff) = o.diff


#-----------------------------------------------------------------------# Extrema
"""
    Extrema(T::Type = Float64)

Maximum and minimum.

# Example

    fit!(Extrema(), rand(10^5))
"""
mutable struct Extrema{T} <: OnlineStat{0}
    min::T
    max::T
    n::Int
end
Extrema(T::Type = Float64) = Extrema{T}(typemax(T), typemin(T), 0)
function _fit!(o::Extrema, y::Real)
    o.min = min(o.min, y)
    o.max = max(o.max, y)
    o.n += 1
end
function Base.merge!(o::Extrema, o2::Extrema)
    o.min = min(o.min, o2.min)
    o.max = max(o.max, o2.max)
    o.n += o2.n
    o
end
value(o::Extrema) = (o.min, o.max)
Base.extrema(o::Extrema) = value(o)
Base.maximum(o::Extrema) = o.max 
Base.minimum(o::Extrema) = o.min

#-----------------------------------------------------------------------# FTSeries 
"""
    FTSeries(stats...; filter=always, transform=identity)

A series that filters and transforms the data before being fit.

# Example 

    fit!(FTSeries(Mean(), Variance(); transform=abs), -rand(1000))
"""
mutable struct FTSeries{N, OS<:Tup, F, T} <: OnlineStat{N}
    stats::OS
    filter::F 
    transform::T 
    nfiltered::Int
end
function FTSeries(stats::OnlineStat{N}...; filter=always, transform=identity) where {N}
    FTSeries{N, typeof(stats), typeof(filter), typeof(transform)}(stats, filter, transform, 0)
end
@generated function _fit!(o::FTSeries{N, OS}, y) where {N, OS}
    n = length(fieldnames(OS))
    quote
        Base.Cartesian.@nexprs $n i -> @inbounds begin
            yi = y[i]; o.filter(yi) ? _fit!(o.stats[i], o.transform(yi)) : o.nfiltered += 1
        end
    end
end
function Base.merge!(o::T, o2::T) where {T<:FTSeries}
    o.nfiltered += o2.nfiltered 
    merge!.(o.stats, o2.stats)
    o
end
always(x) = true

#-----------------------------------------------------------------------# Group
"""
    Group(stats::OnlineStat{0}...)
    Group(tuple)

Create a vector-input stat (`OnlineStat{1}`) from several scalar-input stats.  For a new 
observation `y`, `y[i]` is sent to `stats[i]`.

# Examples

    fit!(Group(Mean(), Mean()), randn(100, 2))
    fit!(Group(Mean(), Variance()), randn(100, 2))
"""
struct Group{T} <: OnlineStat{1}
    stats::T
end
Group(o::OnlineStat{0}...) = Group(o)
Base.hcat(o::OnlineStat{0}...) = Group(o)
nobs(o::Group) = nobs(first(o.stats))

Base.getindex(o::Group, i) = o.stats[i]
Base.first(o::Group) = first(o.stats)
Base.last(o::Group) = last(o.stats)
Base.length(o::Group) = length(o.stats)
Base.values(o::Group) = value.(o.stats)

Base.start(o::Group) = 1 
Base.next(o::Group, i) = o.stats[i], i + 1 
Base.done(o::Group, i) = i > length(o.stats)

@generated function _fit!(o::Group{T}, y) where {T}
    N = length(fieldnames(T))
    :(Base.Cartesian.@nexprs $N i -> @inbounds(_fit!(o.stats[i], y[i])))
end

Base.merge!(o::Group, o2::Group) = (merge!.(o.stats, o2.stats); o)

Base.:*(n::Integer, o::OnlineStat{0}) = Group([copy(o) for i in 1:n]...)

#-----------------------------------------------------------------------# HyperLogLog
# Mostly copy/pasted from StreamStats.jl
"""
    HyperLogLog(b)  # 4 ≤ b ≤ 16

Approximate count of distinct elements.

# Example

    fit!(HyperLogLog(12), rand(1:10,10^5))
"""
mutable struct HyperLogLog <: OnlineStat{0}
    m::UInt32
    M::Vector{UInt32}
    mask::UInt32
    altmask::UInt32
    n::Int
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
        new(m, M, mask, altmask, 0)
    end
end
function Base.show(io::IO, o::HyperLogLog)
    print(io, "HyperLogLog($(o.m) registers, estimate = $(value(o)))")
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

function _fit!(o::HyperLogLog, v)
    o.n += 1
    x = hash32(v)
    j = maskadd32(x, o.mask, 0x00000001)
    w = x & o.altmask
    o.M[j] = max(o.M[j], ρ(w))
    o
end

function value(o::HyperLogLog)
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

function Base.merge!(o::HyperLogLog, o2::HyperLogLog)
    length(o.M) == length(o2.M) || 
        error("Merge failed. HyperLogLog objects have different number of registers.")
    o.n += o2.n
    for j in eachindex(o.M)
        o.M[j] = max(o.M[j], o2.M[j])
    end
    o
end

# #-----------------------------------------------------------------------# KMeans
# """
#     KMeans(p, k)

# Approximate K-Means clustering of `k` clusters and `p` variables.
# """
# mutable struct KMeans{U <: Updater} <: OnlineStat{1}
#     value::Matrix{Float64}  # p × k
#     v::Vector{Float64}
#     updater::U
# end
# KMeans(p::Integer, k::Integer; alg=SGD()) = KMeans(zeros(p, k), zeros(k), 0, u)
# function fit!(o::KMeans{<:SGD}, x::VectorOb, γ::Float64)
#     o.n += 1
#     p, k = size(o.value)
#     if o.n <= k 
#         o.value[:, o.n] = x
#     else
#         for j in 1:k
#             o.v[j] = sum(abs2, x - view(o.value, :, j))
#         end
#         kstar = indmin(o.v)
#         for i in eachindex(x)
#             o.value[i, kstar] = smooth(o.value[i, kstar], x[i], γ)
#         end
#     end
# end

#-----------------------------------------------------------------------# Mean
"""
    Mean(; weight)

Track a univariate mean.

# Update 

``μ = (1 - w) * μ + w * x``

# Example

    @time fit!(Mean(), randn(10^6))

    # exponentially-weighted mean
    @time fit!(Mean(;weight = x -> 0.1), randn(10^6))
"""
mutable struct Mean{W} <: OnlineStat{0}
    μ::Float64
    weight::W
    n::Int
end
Mean(;weight = EqualWeight()) = Mean(0.0, weight, 0)
_fit!(o::Mean, x) = (o.μ = smooth(o.μ, x, o.weight(o.n += 1)))
function Base.merge!(o::Mean, o2::Mean) 
    o.n += o2.n
    o.μ = smooth(o.μ, o2.μ, o2.n / o.n)
    o
end
Base.mean(o::Mean) = o.μ

#-----------------------------------------------------------------------# Moments
"""
    Moments(; weight)

First four non-central moments.

# Example

    s = Series(randn(1000), Moments(10))
    value(s)
"""
mutable struct Moments{W} <: OnlineStat{0}
    m::Vector{Float64}
    weight::W
    n::Int
end
Moments(;weight = EqualWeight()) = Moments(zeros(4), weight, 0)
function _fit!(o::Moments, y::Real)
    γ = o.weight(o.n += 1)
    y2 = y * y
    @inbounds o.m[1] = smooth(o.m[1], y, γ)
    @inbounds o.m[2] = smooth(o.m[2], y2, γ)
    @inbounds o.m[3] = smooth(o.m[3], y * y2, γ)
    @inbounds o.m[4] = smooth(o.m[4], y2 * y2, γ)
end
Base.mean(o::Moments) = o.m[1]
Base.var(o::Moments) = (o.m[2] - o.m[1] ^ 2) * unbias(o)
function skewness(o::Moments)
    v = value(o)
    (v[3] - 3.0 * v[1] * var(o) - v[1] ^ 3) / var(o) ^ 1.5
end
function kurtosis(o::Moments)
    v = value(o)
    (v[4] - 4.0 * v[1] * v[3] + 6.0 * v[1] ^ 2 * v[2] - 3.0 * v[1] ^ 4) / var(o) ^ 2 - 3.0
end
function Base.merge!(o::Moments, o2::Moments)
    γ = o2.n / (o.n += o2.n)
    smooth!(o.m, o2.m, γ)
    o
end

#-----------------------------------------------------------------------# OrderStats
"""
    OrderStats(b::Int, T::Type = Float64)

Average order statistics with batches of size `b`.
"""
mutable struct OrderStats{T, W} <: OnlineStat{0}
    value::Vector{T}
    buffer::Vector{T}
    weight::W
    n::Int
end
function OrderStats(p::Integer, T::Type = Float64; weight=EqualWeight()) 
    OrderStats(zeros(T, p), zeros(T, p), weight, 0)
end
function _fit!(o::OrderStats, y)
    p = length(o.value)
    buffer = o.buffer
    i = (o.n % p) + 1
    o.n += 1 
    buffer[i] = y 
    if i == p
        sort!(buffer)
        smooth!(o.value, buffer, o.weight(o.n / p))
    end
end
function Base.merge!(o::OrderStats, o2::OrderStats)
    length(o.value) == length(o2.value) || 
        error("Merge failed.  OrderStats track different batch sizes")
    o.n += o2.n
    smooth!(o.value, o2.value, o2.n / o.n)
end
Base.quantile(o::OrderStats, arg...) = quantile(value(o), arg...)

# # tree/nbc help:
# function pdf(o::OrderStats, x)
#     if x ≤ first(o.value) 
#         return 0.0
#     elseif x > last(o.value) 
#         return 0.0 
#     else
#         i = searchsortedfirst(o.value, x)
#         b = nobs(o) / (length(o.value) + 1)
#         return b / (o.value[i] - o.value[i-1])
#     end
# end
# split_candidates(o::OrderStats) = midpoints(value(o))


#-----------------------------------------------------------------------# ProbMap
"""
    ProbMap(T::Type; weight)
    ProbMap(A::AbstractDict; weight)

Track a dictionary that maps unique values to its probability.  Similar to 
[`CountMap`](@ref), but uses a weighting mechanism.

# Example 
    
    fit!(ProbMap(Int), rand(1:10, 1000))
"""
mutable struct ProbMap{A<:AbstractDict, W} <: OnlineStat{0}
    value::A 
    weight::W 
    n::Int
end
ProbMap(T::Type; weight = EqualWeight()) = ProbMap(OrderedDict{T, Float64}(), weight, 0)
function _fit!(o::ProbMap, y)
    γ = o.weight(o.n += 1)
    get!(o.value, y, 0.0)   # initialize class probability at 0 if it isn't present
    for ky in keys(o.value)
        if ky == y 
            o.value[ky] = smooth(o.value[ky], 1.0, γ)
        else 
            o.value[ky] *= (1 - γ)
        end
    end
end
function Base.merge!(o::ProbMap, o2::ProbMap) 
    o.n += o2.n
    merge!((a, b)->smooth(a, b, o.n2 / o.n), o.value, o2.value)
    o
end
function probs(o::ProbMap, levels = keys(o))
    out = zeros(length(levels))
    for (i, ky) in enumerate(levels)
        out[i] = get(o.value, ky, 0.0)
    end
    sum(out) == 0.0 ? out : out ./ sum(out)
end

#-----------------------------------------------------------------------# P2Quantile 
"""
    P2Quantile(τ = 0.5)

Calculate the approximate quantile via the P^2 algorithm.  It is more computationally
expensive than the algorithms used by [`Quantile`](@ref), but also more exact.

Ref: [https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf](https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf)
"""
mutable struct P2Quantile <: OnlineStat{0}
    q::Vector{Float64}  # marker heights
    n::Vector{Int}      # marker position
    nprime::Vector{Float64}
    τ::Float64
    nobs::Int
end
function P2Quantile(τ::Real = 0.5)
    @assert 0 < τ < 1
    nprime = [1, 1 + 2τ, 1 + 4τ, 3 + 2τ, 5]
    P2Quantile(zeros(5), collect(1:5), nprime, τ, 0)
end
Base.show(io::IO, o::P2Quantile) = print(io, "P2Quantile($(o.τ), $(value(o)))")
value(o::P2Quantile) = o.q[3]
nobs(o::P2Quantile) = o.nobs
function _fit!(o::P2Quantile, y::Real)
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

# function parabolic_interpolate(q1, q2, q3, n1, n2, n3, d)
#     qi = q2 + d / (n3 - n1) * 
#         ((n2 - n1 + d) * (q3 - q2) / (n3 - n2) + (n3 - n2 - d) * (q2 - q1) / (n2 - n1))
# end

#-----------------------------------------------------------------------# Quantile
"""
    Quantile(q = [.25, .5, .75]; alg)
"""
mutable struct Quantile{T <: Algorithm} <: OnlineStat{0}
    value::Vector{Float64}
    τ::Vector{Float64}
    alg::T 
end
function Quantile(τ::AbstractVector = [.25, .5, .75]; alg = SGD()) 
    init!(alg, length(τ))
    Quantile(zeros(length(τ)), sort!(collect(τ)), alg)
end
function _fit!(o::Quantile, y)
    o.n += 1
    len = length(o.value)
    if n > len 
        qfit!(o, y)
    else
        o.value[o.n] = y 
        n == len && sort!(o.value)
    end
end

function qfit!(o::Quantile{SG}, y) where {SG<:SGAlgorithm}
    γ = o.weight
    for j in eachindex(o.value)
        o.value[j] -= 
        o.alg.δ[j] = Float64((o.value[j] > y) - o.τ[j])
    end
    direction!(o.alg)
    for j in eachindex(o.value)
        o.value[j] -= o.alg.δ[j]
    end
end
function Base.merge!(o::Quantile, o2::Quantile)
    o.τ == o2.τ || error("Merge failed. Quantile objects track different quantiles.")
    merge!(o.alg, o2.alg)
    smooth!(o.value, o2.value, nobs(o2) / nobs(o))
end


# # MSPI
# q_init(u::MSPI, p) = u
# function qfit!(o::Quantile{<:MSPI}, y, γ)
#     @inbounds for i in eachindex(o.τ)
#         w = inv(abs(y - o.value[i]) + ϵ)
#         halfyw = .5 * y * w
#         b = o.τ[i] - .5 + halfyw
#         o.value[i] = (o.value[i] + γ * b) / (1 + .5 * γ * w)
#     end
# end

# # OMAS
# q_init(u::OMAS, p) = OMAS((zeros(p), zeros(p)))
# function qfit!(o::Quantile{<:OMAS}, y, γ)
#     s, t = o.updater.buffer
#     @inbounds for j in eachindex(o.τ)
#         w = inv(abs(y - o.value[j]) + ϵ)
#         s[j] = smooth(s[j], w * y, γ)
#         t[j] = smooth(t[j], w, γ)
#         o.value[j] = (s[j] + (2.0 * o.τ[j] - 1.0)) / t[j]
#     end
# end

# # OMAP...why is this so bad?
# q_init(u::OMAP, p) = u
# function qfit!(o::Quantile{<:OMAP}, y, γ)
#     for j in eachindex(o.τ)
#         w = abs(y - o.value[j]) + ϵ
#         θ = y + w * (2o.τ[j] - 1) 
#         o.value[j] = smooth(o.value[j], θ, γ)
#     end
# end

#-----------------------------------------------------------------------# ReservoirSample
"""
    ReservoirSample(k::Int, T::Type = Float64)

Reservoir sample of `k` items.

# Example

    fit!(ReservoirSample(100, Int), 1:1000)
"""
mutable struct ReservoirSample{T<:Number} <: OnlineStat{0}
    value::Vector{T}
    n::Int
end
function ReservoirSample(k::Int, T::Type = Float64)
    ReservoirSample(zeros(T, k), 0)
end
function _fit!(o::ReservoirSample, y)
    o.n += 1
    if o.n <= length(o.value)
        o.value[o.n] = y
    else
        j = rand(1:o.n)
        if j < length(o.value)
            o.value[j] = y
        end
    end
end
function Base.merge!(o::T, o2::T) where {T<:ReservoirSample}
    length(o.value) == length(o2.value) || error("Can't merge different-sized samples.")
    p = o.n / (o.n + o2.n)
    for j in eachindex(o.value)
        if rand() > p 
            o.value[j] = o2.value[j]
        end
    end
end

#-----------------------------------------------------------------------# Series
"""
    Series(stats...)

Track multiple stats for one data stream.

# Example 

    s = Series(Mean(), Variance())
    fit!(s, randn(1000))
"""
struct Series{N, T<:Tup} <: OnlineStat{N}
    stats::T
end
Series(stats::OnlineStat{N}...) where {N} = Series{N, typeof(stats)}(stats)
@generated function _fit!(o::Series{N, T}, y) where {N, T}
    n = length(fieldnames(T))
    :(Base.Cartesian.@nexprs $n i -> @inbounds(_fit!(o.stats[i], y[i])))
end
Base.merge!(o::Series, o2::Series) = (merge!.(o.stats, o2.stats); o)
function Base.show(io::IO, o::Series)
    print(io, "Series")
    for (i, stat) in enumerate(o.stats)
        char = i == length(o.stats) ? '└' : '├'
        print(io, "\n  $(char)── $stat")
    end
end

#-----------------------------------------------------------------------# Sum
"""
    Sum(T::Type = Float64)

Track the overall sum.

# Example

    fit!(Sum(Int), fill(1, 100))
"""
mutable struct Sum{T} <: OnlineStat{0}
    sum::T
    n::Int
end
Sum(T::Type = Float64) = Sum(T(0), 0)
Base.sum(o::Sum) = o.sum
_fit!(o::Sum{T}, x::Real) where {T<:AbstractFloat} = (o.sum += convert(T, x); o.n += 1)
_fit!(o::Sum{T}, x::Real) where {T<:Integer} =       (o.sum += round(T, x); o.n += 1)
Base.merge!(o::T, o2::T) where {T <: Sum} = (o.sum += o2.sum; o.n += o2.n; o)

#-----------------------------------------------------------------------# Variance 
"""
    Variance(; weight)

Univariate variance.

# Example 

    @time fit!(Variance(), randn(10^6))
"""
mutable struct Variance{W} <: OnlineStat{0}
    σ2::Float64 
    μ::Float64 
    weight::W
    n::Int
end
Variance(;weight = EqualWeight()) = Variance(0.0, 0.0, weight, 0)
function _fit!(o::Variance, x)
    μ = o.μ
    γ = o.weight(o.n += 1)
    o.μ = smooth(o.μ, x, γ)
    o.σ2 = smooth(o.σ2, (x - o.μ) * (x - μ), γ)
end
function Base.merge!(o::Variance, o2::Variance)
    γ = o2.n / (o.n += o2.n)
    δ = o2.μ - o.μ
    o.σ2 = smooth(o.σ2, o2.σ2, γ) + δ ^ 2 * γ * (1.0 - γ)
    o.μ = smooth(o.μ, o2.μ, γ)
    o
end
value(o::Variance) = o.n > 0 ? o.σ2 * unbias(o) : 0.0
Base.var(o::Variance) = value(o)
Base.mean(o::Variance) = o.μ

#-----------------------------------------------------------------------# AutoCov and Lag
"""
    Lag(b, T = Float64)

Store the last `b` values for a data stream of type `T`.
"""
struct Lag{T} <: OnlineStat{0}
    value::Vector{T}
end
Lag(b::Integer, T::Type = Float64) = Lag(zeros(T, b))
function _fit!(o::Lag{T}, y::T) where {T} 
    for i in reverse(2:length(o.value))
        @inbounds o.value[i] = o.value[i - 1]
    end
    o.value[1] = y
end

"""
    AutoCov(b, T = Float64)

Calculate the auto-covariance/correlation for lags 0 to `b` for a data stream of type `T`.

# Example 

    y = cumsum(randn(100))
    o = AutoCov(5)
    fit!(o, y)
    autocov(o)
    autocor(o)
"""
struct AutoCov{T, W} <: OnlineStat{0}
    cross::Vector{Float64}
    m1::Vector{Float64}
    m2::Vector{Float64}
    lag::Lag{T}         # y_{t-1}, y_{t-2}, ...
    wlag::Lag{Float64}  # γ_{t-1}, γ_{t-2}, ...
    v::Variance{W}
end
function AutoCov(k::Integer, T = Float64; kw...)
    d = k + 1
    AutoCov(zeros(d), zeros(d), zeros(d), Lag(d, T), Lag(d, Float64), Variance(;kw...))
end
nobs(o::AutoCov) = nobs(o.v)

function _fit!(o::AutoCov, y::Real)
    γ = o.v.weight(o.v.n + 1)
    _fit!(o.v, y)
    _fit!(o.lag, y)     # y_t, y_{t-1}, ...
    _fit!(o.wlag, γ)    # γ_t, γ_{t-1}, ...
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
