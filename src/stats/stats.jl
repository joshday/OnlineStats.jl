#-----------------------------------------------------------------------# AutoCov and Lag
# Lag
"""
    Lag{T}(b::Integer)

Store the last `b` values for a data stream of type `T`.  Values are stored as

``v(t), v(t-1), v(t-2), …, v(t-b+1)``

so that `value(o::Lag)[1]` is the most recent observation and `value(o::Lag)[end]` is the
`b`-th most recent observation.

# Example

    o = fit!(Lag{Int}(10), 1:12)
    o[1]
    o[end]
"""
mutable struct Lag{T} <: OnlineStat{T}
    value::Vector{T}
    b::Int
    n::Int
end
Lag(T::Type, b::Integer) = Lag(T[], b, 0)
function _fit!(o::Lag, y)
    o.n += 1
    pushfirst!(o.value, y)
    length(o.value) > o.b && pop!(o.value)
end
Base.length(o::Lag) = length(o.value)
Base.getindex(o::Lag, i) = o.value[i]
Base.lastindex(o::Lag) = length(o)


"""
    AutoCov(b, T = Float64; weight=EqualWeight())

Calculate the auto-covariance/correlation for lags 0 to `b` for a data stream of type `T`.

# Example

    y = cumsum(randn(100))
    o = AutoCov(5)
    fit!(o, y)
    autocov(o)
    autocor(o)
"""
struct AutoCov{T, W} <: OnlineStat{T}
    cross::Vector{Float64}
    m1::Vector{Float64}
    m2::Vector{Float64}
    lag::Lag{T}         # y_{t-1}, y_{t-2}, ...
    wlag::Lag{Float64}  # γ_{t-1}, γ_{t-2}, ...
    v::Variance{W}
end
function AutoCov(k::Integer, T = Float64; kw...)
    d = k + 1
    AutoCov(zeros(d), zeros(d), zeros(d), Lag(T, d), Lag(Float64, d), Variance(;kw...))
end
nobs(o::AutoCov) = nobs(o.v)

function _fit!(o::AutoCov{T}, y) where {T}
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
        γk = k ≤ length(o.wlag) ? o.wlag[k] : 0.0
        lagk = k ≤ length(o.lag) ? o.lag[k] : zero(T)
        o.cross[k] = smooth(o.cross[k], y * lagk, γk)
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

#-----------------------------------------------------------------------# Bootstrap
"""
    Bootstrap(o::OnlineStat, nreps = 100, d = [0, 2])

Calculate an online statistical bootstrap of `nreps` replicates of `o`.  For each call to `fit!`,
any given replicate will be updated `rand(d)` times (default is double or nothing).

# Example

    o = Bootstrap(Variance())
    fit!(o, randn(1000))
    confint(o, .95)
"""
struct Bootstrap{T, O <: OnlineStat{T}, D} <: OnlineStat{T}
    stat::O
    replicates::Vector{O}
    rnd::D
end
function Bootstrap(o::OnlineStat{T}, nreps::Integer = 100, d = [0, 2]) where {T}
    Bootstrap{T, typeof(o), typeof(d)}(o, [copy(o) for i in 1:nreps], d)
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

    o = CallFun(Mean(), println)
    fit!(o, [0,0,1,1])
"""
struct CallFun{T, O <: OnlineStat{T}, F <: Function} <: OnlineStat{T}
    stat::O
    f::F
end
CallFun(o::O, f::F) where {T, O<:OnlineStat{T}, F} = CallFun{T, O, F}(o, f)
nobs(o::CallFun) = nobs(o.stat)
value(o::CallFun) = value(o.stat)
Base.show(io::IO, o::CallFun) = print(io, "CallFun: $(o.stat) |> $(o.f)")
_fit!(o::CallFun, arg)  = (_fit!(o.stat, arg); o.f(o.stat))
_merge!(o::CallFun, o2::CallFun) = _merge!(o.stat, o2.stat)

#-----------------------------------------------------------------------# CovMatrix
"""
    CovMatrix(p=0; weight=EqualWeight())
    CovMatrix(::Type{T}, p=0; weight=EqualWeight())

Calculate a covariance/correlation matrix of `p` variables.  If the number of variables is
unknown, leave the default `p=0`.

# Example

    o = fit!(CovMatrix(), randn(100, 4))
    cor(o)
    cov(o)
    mean(o)
    var(o)
"""
mutable struct CovMatrix{T,W} <: OnlineStat{VectorOb} where T<:Number
    value::Matrix{T}
    A::Matrix{T}  # x'x/n
    b::Vector{T}  # 1'x/n
    weight::W
    n::Int
end
function CovMatrix(::Type{T}, p::Int=0; weight = EqualWeight()) where T<:Number
    CovMatrix(zeros(T,p,p), zeros(T,p,p), zeros(T,p), weight, 0)
end
CovMatrix(p::Int=0; weight = EqualWeight()) = CovMatrix(zeros(p,p), zeros(p,p), zeros(p), weight, 0)
function _fit!(o::CovMatrix{T}, x) where {T}
    γ = o.weight(o.n += 1)
    if isempty(o.A)
        p = length(x)
        o.b = zeros(T, p)
        o.A = zeros(T, p, p)
        o.value = zeros(T, p, p)
    end
    smooth!(o.b, x, γ)
    smooth_syr!(o.A, x, γ)
end
nvars(o::CovMatrix) = size(o.A, 1)
function value(o::CovMatrix; corrected::Bool = true)
    o.value[:] = Matrix(Hermitian((o.A - o.b * o.b')))
    corrected && rmul!(o.value, bessel(o))
    o.value
end
function _merge!(o::CovMatrix, o2::CovMatrix)
    γ = o2.n / (o.n += o2.n)
    smooth!(o.A, o2.A, γ)
    smooth!(o.b, o2.b, γ)
    o
end
Statistics.cov(o::CovMatrix; corrected::Bool = true) = value(o; corrected=corrected)
Statistics.mean(o::CovMatrix) = o.b
Statistics.var(o::CovMatrix; kw...) = diag(value(o; kw...))
function Statistics.cor(o::CovMatrix; kw...)
    value(o; kw...)
    v = 1.0 ./ sqrt.(diag(o.value))
    rmul!(o.value, Diagonal(v))
    lmul!(Diagonal(v), o.value)
    o.value
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
mutable struct Diff{T <: Number} <: OnlineStat{Number}
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

#-----------------------------------------------------------------------# StatLag
"""
    StatLag(stat, b)

Track a moving window (previous `b` copies) of `stat`.

# Example

    fit!(StatLag(Mean(), 10), 1:20)
"""
struct StatLag{T, O<:OnlineStat{T}} <: OnlineStat{T}
    lag::Lag{O}
    stat::O
end
function StatLag(stat::O, b::Integer) where {T, O<:OnlineStat{T}}
    StatLag{T,O}(Lag(O,b), stat)
end
nobs(o::StatLag) = nobs(o.stat)
function _fit!(o::StatLag, y)
    _fit!(o.stat, y)
    _fit!(o.lag, copy(o.stat))
end
function Base.show(io::IO, o::StatLag)
    print(io, name(o, false, true))
    OnlineStatsBase.print_stat_tree(io, o.lag.value)
end

Base.@deprecate_binding StatHistory StatLag

#-----------------------------------------------------------------------# HyperLogLog
# https://storage.googleapis.com/pub-tools-public-publication-data/pdf/40671.pdf

"""
    HyperLogLog(T = Number)
    HyperLogLog{P}(T = Number)

Approximate count of distinct elements of a data stream of type `T`, using `2 ^ P`
"registers".  `P` must be an integer between 4 and 16 (default).

Ref: https://storage.googleapis.com/pub-tools-public-publication-data/pdf/40671.pdf

# Example

    o = HyperLogLog()
    fit!(o, rand(1:100, 10^6))

    using Random
    o2 = HyperLogLog(String)
    fit!(o2, [randstring(20) for i in 1:1000])
"""
mutable struct HyperLogLog{p, T} <: OnlineStat{T}
    M::Vector{Int}
    n::Int
    function HyperLogLog{p}(T::Type=Number) where {p}
        4 ≤ p ≤ 16 || throw(ArgumentError("Number of registers must be in 4:16"))
        new{p,T}(zeros(Int, 2^p), 0)
    end
end
HyperLogLog(T::Type=Number) = HyperLogLog{16}(T)

@deprecate HyperLogLog(p::Number, T::Type) HyperLogLog{p}(T::Type)

function Base.show(io::IO, o::HyperLogLog{p,T}) where {p,T}
    print(io, "HyperLogLog{$p, $T}: n=$(nobs(o)) | value=", value(o))
end

function _fit!(o::HyperLogLog, v)
    o.n += 1
    x = hash(v) % UInt32
    i = (x & mask(o)) + UInt32(1)
    w = (x & ~mask(o))
    o.M[i] = max(o.M[i], UInt32(leading_zeros(w) + 1))
end

function value(o::HyperLogLog)
    E = α(o) * _m(o) * _m(o) * inv(sum(x -> inv(2 ^ x), o.M))
    if E ≤ 5 * _m(o) / 2
        V = sum(==(0), o.M)
        return V == 0 ? E : _m(o) * log(_m(o) / V)
    elseif E ≤ 2 ^ 32 / 30
        return E
    else
        return -2 ^ 32 * log(1 - E / 2 ^ 32)
    end
end

function _merge!(o::HyperLogLog, o2::HyperLogLog)
    length(o.M) == length(o2.M) ||
        error("Merge failed. HyperLogLog objects have different number of registers.")
    o.n += o2.n
    for j in eachindex(o.M)
        @inbounds o.M[j] = max(o.M[j], o2.M[j])
    end
    o
end

@generated _m(o::HyperLogLog{p}) where {p} = 2 ^ p

@generated mask(o::HyperLogLog{p}) where {p} = UInt32(2 ^ p - 1)

@generated α(o::HyperLogLog{4}) = 0.673
@generated α(o::HyperLogLog{5}) = 0.697
@generated α(o::HyperLogLog{6}) = 0.709
@generated α(o::HyperLogLog{p}) where {p} = 0.7213 / (1 + 1.079 / 2 ^ p)

#-----------------------------------------------------------------------# KMeans
"Cluster center and the number of observations"
mutable struct Cluster
    value::Vector{Float64}
    n::Int
end
Base.show(io::IO, o::Cluster) = print(io, "Cluster: nobs=$(o.n), value=$(o.value)")
Base.isless(a::Cluster, b::Cluster) = isless(a.n, b.n)

"""
    KMeans(p, k; rate=LearningRate(.6))

Approximate K-Means clustering of `k` clusters and `p` variables.

# Example

    x = [randn() + 5i for i in rand(Bool, 10^6), j in 1:2]

    o = fit!(KMeans(2, 2), x)

    sort!(o; rev=true)  # Order clusters by number of observations
"""
mutable struct KMeans{T, W} <: OnlineStat{VectorOb}
    value::T
    buffer::Vector{Float64}
    rate::W
    n::Int
end
function KMeans(p::Integer, k::Integer; rate=LearningRate())
    KMeans(Tuple(Cluster(zeros(p), 0) for i in 1:k), zeros(k), rate, 0)
end
nobs(o::KMeans) = sum(x -> x.n, o.value)
function Base.show(io::IO, o::KMeans)
    print(io, "KMeans")
    OnlineStatsBase.print_stat_tree(io, o.value)
end
function Base.sort!(o::KMeans; kw...)
    o.value = Tuple(sort!(collect(o.value); kw...))
    o
end
function _fit!(o::KMeans, x)
    o.n += 1
    if o.n ≤ length(o.value)
        cluster = o.value[o.n]
        cluster.value[:] = collect(x)
        cluster.n += 1
    else
        fill!(o.buffer, 0.0)
        for k in eachindex(o.buffer)
            cluster = o.value[k]
            for j in eachindex(x)
                o.buffer[k] = norm(x[j] - cluster.value[j])
            end
        end
        k_star = argmin(o.buffer)
        cluster = o.value[k_star]
        smooth!(cluster.value, x, o.rate(cluster.n += 1))
    end
end

#-----------------------------------------------------------------------# MovingTimeWindow
"""
    MovingTimeWindow{T<:TimeType, S}(window::DatePeriod)
    MovingTimeWindow(window::DatePeriod; valtype=Float64, timetype=Date)

Fit a moving window of data based on time stamps.  Each observation must be a `Tuple`,
`NamedTuple`, or `Pair` where the first item is `<: Dates.TimeType`.  Only observations
with time stamps in the range

``most_recent_datetime - window <= time_stamp <= most_recent_datetime``

are kept track of.

# Example

    using Dates
    dts = Date(2010):Day(1):Date(2011)
    y = rand(length(dts))

    o = MovingTimeWindow(Day(4); timetype=Date, valtype=Float64)
    fit!(o, zip(dts, y))
"""
mutable struct MovingTimeWindow{T<:TimeType, S, D<:DatePeriod} <: OnlineStat{TwoThings{T,S}}
    values::Vector{Pair{T,S}}
    window::D
    n::Int
end
function MovingTimeWindow{T,S}(window::DatePeriod) where {T<:TimeType, S}
    MovingTimeWindow(Pair{T,S}[], window, 0)
end
function MovingTimeWindow(window::DatePeriod; valtype=Float64, timetype=Date)
    MovingTimeWindow{timetype, valtype}(window)
end
value(o::MovingTimeWindow) = sort!(o.values)
function _fit!(o::MovingTimeWindow, y)
    o.n += 1
    push!(o.values, Pair(y...))
    cutoff = maximum(first, o.values) - o.window
    filter!(x -> x[1] >= cutoff, o.values)
end
function _merge!(a::MovingTimeWindow, b::MovingTimeWindow)
    a.n += (nobs(b) - length(value(b)))
    for y in value(b)
        fit!(a, y)
    end
end



#-----------------------------------------------------------------------# MovingWindow
"""
    MovingWindow(b, T)
    MovingWindow(T, b)

Track a moving window of `b` items of type `T`.

# Example

    o = MovingWindow(10, Int)
    fit!(o, 1:14)
"""
mutable struct MovingWindow{T} <: OnlineStat{T}
    value::Vector{T}
    b::Int
    first::Int
    n::Int
end
MovingWindow(b::Int, T::Type) = MovingWindow(T[], b, 1, 0)
MovingWindow(T::Type, b::Int) = MovingWindow(b, T)
function value(o::MovingWindow)
    perm = vcat(collect(o.first:o.b), collect(1:(o.first-1)))
    o.first = 1
    permute!(o.value, perm)
end
function _fit!(o::MovingWindow, y)
    o.n += 1
    if length(o.value) < o.b
        push!(o.value, y)
    else
        o.value[o.first] = y
        o.first = (o.first == o.b) ? 1 : o.first + 1
    end
end
function Base.getindex(o::MovingWindow, i::Int)
    i2 = i + o.first - 1
    i2 = i2 > o.b ? i2 - o.b : i2
    o.value[i2]
end
Base.lastindex(o::MovingWindow) = o.b

#-----------------------------------------------------------------------# OrderStats
"""
    OrderStats(b::Int, T::Type = Float64; weight=EqualWeight())

Average order statistics with batches of size `b`.

# Example

    o = fit!(OrderStats(100), randn(10^5))
    quantile(o, [.25, .5, .75])
"""
mutable struct OrderStats{T, W} <: OnlineStat{Number}
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
function _merge!(o::OrderStats, o2::OrderStats)
    length(o.value) == length(o2.value) ||
        error("Merge failed.  OrderStats track different batch sizes")
    o.n += o2.n
    smooth!(o.value, o2.value, o2.n / o.n)
end
Statistics.quantile(o::OrderStats, arg...) = quantile(value(o), arg...)

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
    ProbMap(T::Type; weight=EqualWeight())
    ProbMap(A::AbstractDict{T, Float64}; weight=EqualWeight())

Track a dictionary that maps unique values to its probability.  Similar to
[`CountMap`](@ref), but uses a weighting mechanism.

# Example

    o = ProbMap(Int)
    fit!(o, rand(1:10, 1000))
    probs(o)
"""
mutable struct ProbMap{T, A<:AbstractDict{T,Float64}, W} <: OnlineStat{T}
    value::A
    weight::W
    n::Int
end
function ProbMap(T::Type; weight = EqualWeight())
    ProbMap{T,OrderedDict{T,Float64}, typeof(weight)}(OrderedDict{T, Float64}(), weight, 0)
end
function ProbMap(d::AbstractDict{T, Float64}; weight=EqualWeight()) where {T}
    ProbMap{T,OrderedDict{T,Float64},typeof(weight)}(d, weight, 0)
end
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
function _merge!(o::ProbMap, o2::ProbMap)
    o.n += o2.n
    merge!((a, b)->smooth(a, b, o2.n / o.n), o.value, o2.value)
    o
end
function probs(o::ProbMap, levels = keys(o.value))
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

# Example

    fit!(P2Quantile(.5), rand(10^5))
"""
mutable struct P2Quantile <: OnlineStat{Number}
    q::Vector{Float64}  # marker heights
    n::Vector{Int}      # marker position
    nprime::Vector{Float64}
    τ::Float64
    nobs::Int
end
function P2Quantile(τ::Real = 0.5)
    0 < τ < 1 || error("specified quantile must be in (0, 1)")
    nprime = [1, 1 + 2τ, 1 + 4τ, 3 + 2τ, 5]
    P2Quantile(zeros(5), collect(1:5), nprime, τ, 0)
end
Base.show(io::IO, o::P2Quantile) = print(io, "P2Quantile ($(o.τ)): n=$(nobs(o)) | value=$(value(o))")
value(o::P2Quantile) = o.q[3]
nobs(o::P2Quantile) = o.nobs
# function _merge!(a::P2Quantile, b::P2Quantile)
#     a.τ == b.τ || error("Quantiles are not the same: $(a.τ) != $(b.τ)")
#     a.nobs += b.nobs
#     # q
#     a.q[1] = min(a.q[1], b.q[1])
#     a.q[5] = max(a.q[5], b.q[5])
# end
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
    Quantile(q = [.25, .5, .75]; alg=OMAS(), rate=LearningRate(.6))

Calculate quantiles via a stochastic approximation algorithm `OMAS`, `SGD`, `ADAGRAD`, or
`MSPI`.  For better (although slower) approximations, see [`P2Quantile`](@ref) and
[`Hist`](@ref).

# Example

    fit!(Quantile(), randn(10^5))
"""
mutable struct Quantile{T <: Algorithm, W} <: OnlineStat{Number}
    value::Vector{Float64}
    τ::Vector{Float64}
    rate::W
    n::Int
    alg::T
end
function Quantile(τ::AbstractVector = [.25, .5, .75]; alg=OMAS(), rate=LearningRate(.6))
    init!(alg, length(τ))
    Quantile(zeros(length(τ)), sort!(collect(τ)), rate, 0, alg)
end
function _fit!(o::Quantile, y)
    γ = o.rate(o.n += 1)
    len = length(o.value)
    if o.n > len
        qfit!(o, y, γ)
    else
        o.value[o.n] = y
        o.n == len && sort!(o.value)
    end
end
function _merge!(o::Quantile, o2::Quantile)
    o.τ == o2.τ || error("Merge failed. Quantile objects track different quantiles.")
    o.n += o2.n
    γ = nobs(o2) / nobs(o)
    merge!(o.alg, o2.alg, γ)
    smooth!(o.value, o2.value, γ)
end

function qfit!(o::Quantile{SGD}, y, γ)
    for j in eachindex(o.value)
        o.value[j] -= γ * Float64((o.value[j] > y) - o.τ[j])
    end
end
function qfit!(o::Quantile{ADAGRAD}, y, γ)
    for j in eachindex(o.value)
        g = Float64((o.value[j] > y) - o.τ[j])
        o.alg.h[j] = smooth(o.alg.h[j], g * g, 1 / nobs(o))
        o.value[j] -= γ * g / sqrt(o.alg.h[j] + ϵ)
    end
end
function qfit!(o::Quantile{MSPI}, y, γ)
    for i in eachindex(o.τ)
        w = inv(abs(y - o.value[i]) + ϵ)
        halfyw = .5 * y * w
        b = o.τ[i] - .5 + halfyw
        o.value[i] = (o.value[i] + γ * b) / (1 + .5 * γ * w)
    end
end
function qfit!(o::Quantile{OMAS}, y, γ)
    s, t = o.alg.a, o.alg.b
    @inbounds for j in eachindex(o.τ)
        w = inv(abs(y - o.value[j]) + ϵ)
        s[j] = smooth(s[j], w * y, γ)
        t[j] = smooth(t[j], w, γ)
        o.value[j] = (s[j] + (2.0 * o.τ[j] - 1.0)) / t[j]
    end
end

# # OMAP...why is this bad?
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

Create a sample without replacement of size `k`.  After running through `n` observations,
the probability of an observation being in the sample is `1 / n`.

# Example

    fit!(ReservoirSample(100, Int), 1:1000)
"""
mutable struct ReservoirSample{T<:Number} <: OnlineStat{Number}
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
function _merge!(o::T, o2::T) where {T<:ReservoirSample}
    length(o.value) == length(o2.value) || error("Can't merge different-sized samples.")
    p = o.n / (o.n += o2.n)
    for j in eachindex(o.value)
        if rand() > p
            o.value[j] = o2.value[j]
        end
    end
end

# #-----------------------------------------------------------------------# Summarizer
# mutable struct Summarizer{T} <: OnlineStat{T}
#     group::Group
# end
# nobs(o::Summarizer) = nobs(o.group)