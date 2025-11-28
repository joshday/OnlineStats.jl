#-----------------------------------------------------------------------# AutoCov and Lag
# Lag
"""
    Lag(T, b::Int)

Store the last `b` values for a data stream of type `T`.  Values are stored as

``v(t), v(t-1), v(t-2), …, v(t-b+1)``

so that `value(o::Lag)[1]` is the most recent observation and `value(o::Lag)[end]` is the
`b`-th most recent observation.

# Example

    o = fit!(Lag(Int, 10), 1:12)
    o[1]
    o[end]
"""
mutable struct Lag{T} <: OnlineStat{T}
    value::Vector{T}
    b::Int
    n::Int
end
function Lag(T::Type, b::Int)
    Base.depwarn("`Lag(T, b)` is deprecated.  Use `CircBuff(T,b,rev=true)` instead.", :Lag, force=true)
    Lag(T[], b, 0)
end
Lag{T}(b::Int) where {T} = Lag(T, b)
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
struct AutoCov{T, W} <: OnlineStat{Number}
    cross::Vector{Float64}
    m1::Vector{Float64}
    m2::Vector{Float64}
    lag::CircBuff{T, true}         # y_{t-1}, y_{t-2}, ...
    wlag::CircBuff{Float64, true}  # γ_{t-1}, γ_{t-2}, ...
    v::Variance{T, T, W}
end
function AutoCov(k::Integer, T = Float64; kw...)
    d = k + 1
    AutoCov(zeros(d), zeros(d), zeros(d), CircBuff(T,d;rev=true), CircBuff(Float64,d;rev=true), Variance(T, ;kw...))
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

#-----------------------------------------------------------------------------# GeometricMean
"""
    GeometricMean(T = Float64)

Calculate the geometric mean of a data stream, stored as type `T`.

# Example

    o = fit!(GeometricMean(), 1:100)
"""
struct GeometricMean{T<:Mean} <: OnlineStat{Number}
    m::T
end
GeometricMean(T::Type{<:Number} = Float64) = GeometricMean(Mean(T))
nobs(o::GeometricMean) = nobs(o.m)
value(o::GeometricMean) = nobs(o) > 0 ? exp(value(o.m)) : zero(typeof(value(o.m)))
_fit!(o::GeometricMean, y) = fit!(o.m, log(y))
_merge!(a::GeometricMean, b::GeometricMean) = merge!(a.m, b.m)

#-----------------------------------------------------------------------# StatLag
"""
    StatLag(stat, b)

Track a moving window (previous `b` copies) of `stat`.

# Example

    fit!(StatLag(Mean(), 10), 1:20)
"""
struct StatLag{T, O<:OnlineStat{T}} <: OnlineStatsBase.StatWrapper{T}
    lag::CircBuff{O}
    stat::O
end
function StatLag(stat::O, b::Integer) where {T, O<:OnlineStat{T}}
    StatLag{T,O}(CircBuff(O,b), stat)
end
function _fit!(o::StatLag, y)
    _fit!(o.stat, y)
    _fit!(o.lag, copy(o.stat))
end
function Base.show(io::IO, o::StatLag)
    print(io, name(o, false, false), ": ")
    print(io, "n=", nobs(o))
    print(io, " | stat_values_old_to_new= ")
    show(IOContext(io, :compact => true), value.(value(o.lag)))
end

#-----------------------------------------------------------------------# KMeans
"Cluster center and the number of observations"
mutable struct Cluster{T<:Number}
    value::Vector{T}
    n::Int
    Cluster(T, p::Integer = 0) = new{T}(zeros(T, p), 0)
end
Base.show(io::IO, o::Cluster) = print(io, "Cluster: nobs=$(o.n), value=$(o.value)")
Base.isless(a::Cluster, b::Cluster) = isless(a.n, b.n)
nobs(o::Cluster) = o.n
value(o::Cluster) = o.value

"""
    KMeans(k; rate=LearningRate(.6))

Approximate K-Means clustering of `k` clusters.

# Example

    x = [randn() + 5i for i in rand(Bool, 10^6), j in 1:2]

    o = fit!(KMeans(2, 2), eachrow(x))

    sort!(o; rev=true)  # Order clusters by number of observations

    classify(o, x[1])  # returns index of cluster closest to x[1]
"""
mutable struct KMeans{T, C <: NTuple{N, Cluster{T}} where N, W} <: OnlineStat{VectorOb{Number}}
    value::C
    buffer::Vector{T}
    rate::W
    n::Int
end
KMeans(T::Type{<:Number}, k::Integer; kw...) = KMeans(k, T; kw...)
function KMeans(k::Integer, T::Type{<:Number} = Float64; rate=LearningRate())
    KMeans(Tuple(Cluster(T) for i in 1:k), zeros(T, k), rate, 0)
end
Base.show(io::IO, o::KMeans) = AbstractTrees.print_tree(io, o)
AbstractTrees.printnode(io::IO, o::KMeans) = print(io, "KMeans($(length(o.value))) | n=$(nobs(o))")
AbstractTrees.children(o::KMeans) = value(o)
function Base.sort!(o::KMeans; kw...)
    o.value = Tuple(sort!(collect(o.value); kw...))
    o
end
function _fit!(o::KMeans{T}, x) where {T}
    o.n += 1
    if o.n == 1
        p = length(x)
        o.value = Tuple(Cluster(T, p) for _ in o.value)
    end
    if o.n ≤ length(o.value)
        cluster = o.value[o.n]
        cluster.value[:] = collect(x)
        cluster.n += 1
    else
        # fill!(o.buffer, 0.0)
        for k in eachindex(o.buffer)
            cluster = o.value[k]
            o.buffer[k] = norm(x .- cluster.value)
        end
        k_star = argmin(o.buffer)
        cluster = o.value[k_star]
        smooth!(cluster.value, x, o.rate(cluster.n += 1))
    end
end

classify(o::KMeans, x) = findmin(c -> norm(x .- c.value), o.value)[2]

#-----------------------------------------------------------------------# MovingTimeWindow
"""
    MovingTimeWindow{T<:TimeType, S}(window::Dates.Period)
    MovingTimeWindow(window::Dates.Period; valtype=Float64, timetype=Date)

Fit a moving window of data based on time stamps.  Each observation must be a `Tuple`,
`NamedTuple`, or `Pair` where the first item is `<: Dates.TimeType`.  Observations
with a `timestamp` NOT in the range

```
now() - window ≤ timestamp ≤ now()
```

are discarded on every `fit!`.

# Example

    using Dates
    dts = Date(2010):Day(1):Date(2011)
    y = rand(length(dts))

    o = MovingTimeWindow(Day(4); timetype=Date, valtype=Float64)
    fit!(o, zip(dts, y))
"""
mutable struct MovingTimeWindow{T<:TimeType, S, D<:Period} <: OnlineStat{TwoThings{T,S}}
    values::Vector{Pair{T,S}}
    window::D
    n::Int
end
function MovingTimeWindow{T,S}(window::Period) where {T<:TimeType, S}
    MovingTimeWindow(Pair{T,S}[], window, 0)
end
function MovingTimeWindow(window::Period; valtype=Float64, timetype=Date)
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

Track a moving window of `b` items of type `T`.  Also known as a circular buffer.

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
    o.n < o.b && return o.value
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

    f = ecdf(o)
    f(0)
"""
mutable struct OrderStats{T, W, E<:Extrema} <: OnlineStat{Number}
    value::Vector{T}
    buffer::Vector{T}
    weight::W
    ex::E
end
function OrderStats(p::Integer, T::Type = Float64; weight=EqualWeight())
    OrderStats(zeros(T, p), zeros(T, p), weight, Extrema(T))
end
nobs(o::OrderStats) = nobs(o.ex)
function _fit!(o::OrderStats, y)
    n = nobs(o)
    p = length(o.value)
    buffer = o.buffer
    i = (nobs(o) % p) + 1
    _fit!(o.ex, y)
    buffer[i] = y
    if i == p
        sort!(buffer)
        smooth!(o.value, buffer, o.weight(nobs(o) / p))
    end
end
function _merge!(a::OrderStats, b::OrderStats)
    length(a.value) == length(b.value) ||
        @warn "OrderStats track different batch sizes.  No merging occurred."
    merge!(a.ex, b.ex)
    smooth!(a.value, b.value, nobs(b) / nobs(a))
end
Statistics.quantile(o::OrderStats, arg...) = quantile(value(o), arg...)

function ecdf(o::OrderStats)
    a, b = extrema(o.ex)
    ecdf(vcat(a, value(o), b))
end

Extrema(o::OrderStats) = copy(o.ex)
Base.minimum(o::OrderStats) = Base.minimum(o.ex)
Base.extrema(o::OrderStats) = Base.extrema(o.ex)
Base.maximum(o::OrderStats) = Base.maximum(o.ex)
Base.convert(::Type{Extrema}, o::OrderStats) = Extrema(o)

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
    merge!((a, b) -> smooth(a, b, o2.n / o.n), o.value, o2.value)
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

Ref: <https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf>

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
    Quantile(q::Vector{Float64} = [0, .25, .5, .75, 1]; b=500)

Calculate (approximate) quantiles from a data stream.  Internally uses [`ExpandingHist`](@ref) to
estimate the distribution, for which `b` is the number of histogram bins.  Setting `b` to a larger
number will increase accuracy at the cost of speed.

# Example

    q = [.25, .5, .75]
    x = randn(10^6)

    o = fit!(Quantile(q, b=1000), randn(10^6))
    value(o)

    quantile(x, q)
"""
struct Quantile{T<:ExpandingHist} <: OnlineStat{Number}
    q::Vector{Float64}
    eh::T
end
function Quantile(q=[0,.25,.5,.75,1]; b::Int=500, alg=nothing, rate=nothing)
    !isnothing(alg) && @warn("`alg` keyword is deprecated and ignored by the new quantile algorithm")
    !isnothing(rate) && @warn("`rate` keyword is deprecated and ignored by the new quantile algorithm")
    Quantile(Vector{Float64}(q), ExpandingHist(b))
end
_fit!(o::Quantile, x) = fit!(o.eh, x)
value(o::Quantile, q=o.q) = nobs(o) > 0 ? quantile(o.eh, q) : zeros(length(q))
nobs(o::Quantile) = nobs(o.eh)

#-----------------------------------------------------------------------# ReservoirSample
"""
    ReservoirSample(k::Int, T::Type = Float64)

Create a sample without replacement of size `k`.  After running through `n` observations,
the probability of an observation being in the sample is `1 / n`.

If you need more advanced reservoir sampling methods consider using `StreamSampling.jl`.

# Example

    fit!(ReservoirSample(100, Int), 1:1000)
"""
mutable struct ReservoirSample{T} <: OnlineStat{T}
    value::Vector{T}
    k::Int
    n::Int
end
ReservoirSample(k::Int, T::Type = Float64) = ReservoirSample(sizehint!(T[], k), k, 0)
function _fit!(o::ReservoirSample, y)
    if (o.n += 1) ≤ o.k
        push!(o.value, y)
    else
        j = rand(1:o.n)
        if j ≤ length(o.value)
            o.value[j] = y
        end
    end
end
function _merge!(o::T, o2::T) where {T<:ReservoirSample}
    length(o.value) == length(o2.value) || error("Can't merge different-sized ReservoirSamples.")
    p = o.n / (o.n += o2.n)
    for j in eachindex(o.value)
        if rand() > p
            o.value[j] = o2.value[j]
        end
    end
end

#-----------------------------------------------------------------------# LogSumExp

"""
    LogSumExp(T::Type = Float64)

For positive numbers that can be very small (or very large), it's common to
store each `log(x)` instead of each `x` itself, to avoid underflow (or
overflow). `LogSumExp` takes values in this representation and adds them,
returning the result in the same representation.

Ref: <https://www.nowozin.net/sebastian/blog/streaming-log-sum-exp-computation.html>

# Example

    x = randn(1000)

    fit!(LogSumExp(), x)

    log(sum(exp.(x))) # should be very close
"""
mutable struct LogSumExp{T<:Number} <: OnlineStat{Number}
    r::T
    α::T
    n::Int
end

function LogSumExp(T::Type = Float64)
    LogSumExp{T}(zero(T), T(-Inf), 0)
end

function _fit!(o::LogSumExp{T}, x) where {T}
    o.n += 1
    if x <= o.α
        o.r += exp(x - o.α)
    else
        o.r *= exp(o.α - x)
        o.r += one(T)
        o.α = x
    end
end

function _merge!(o1::LogSumExp, o2::LogSumExp)
    o1.n += o2.n - 1
    fit!(o1, value(o2))
end

value(o::LogSumExp) = log(o.r) + o.α
nobs(o::LogSumExp) = o.n
