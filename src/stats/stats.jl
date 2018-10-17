#-----------------------------------------------------# StatCollection (Series and Group)
abstract type StatCollection{T} <: OnlineStat{T} end

function Base.show(io::IO, o::StatCollection)
    print(io, name(o, false, false))
    print_stat_tree(io, o.stats)
end

function print_stat_tree(io::IO, stats)
    for (i, stat) in enumerate(stats)
        char = i == length(stats) ? '└' : '├'
        print(io, "\n  $(char)── $stat")
    end
end

#-----------------------------------------------------------------------# Variance
"""
    Variance(; weight=EqualWeight())

Univariate variance.

# Example

    o = fit!(Variance(), randn(10^6))
    mean(o)
    var(o)
    std(o)
"""
mutable struct Variance{W} <: OnlineStat{Number}
    σ2::Float64
    μ::Float64
    weight::W
    n::Int
end
Variance(;weight = EqualWeight()) = Variance(0.0, 0.0, weight, 0)
Base.copy(o::Variance) = Variance(o.σ2, o.μ, o.weight, o.n)
function _fit!(o::Variance, x)
    μ = o.μ
    γ = o.weight(o.n += 1)
    o.μ = smooth(o.μ, x, γ)
    o.σ2 = smooth(o.σ2, (x - o.μ) * (x - μ), γ)
end
function _merge!(o::Variance, o2::Variance)
    γ = o2.n / (o.n += o2.n)
    δ = o2.μ - o.μ
    o.σ2 = smooth(o.σ2, o2.σ2, γ) + δ ^ 2 * γ * (1.0 - γ)
    o.μ = smooth(o.μ, o2.μ, γ)
    o
end
value(o::Variance) = o.n > 1 ? o.σ2 * unbias(o) : 1.0
Statistics.var(o::Variance) = value(o)
Statistics.mean(o::Variance) = o.μ

#-----------------------------------------------------------------------# AutoCov and Lag
# Lag
"""
    Lag{T}(b::Integer)

Store the last `b` values for a data stream of type `T`.  Values are stored as

``v(t), v(t-1), v(t-2), …, v(t-b+1)``

# Example

    o = fit!(Lag{Int}(10), 1:12)
    o[1]
    o[end]
"""
mutable struct Lag{T} <: OnlineStat{T}
    circbuff::CircularBuffer{T}
    n::Int
    Lag{T}(b::Integer) where {T} = new{T}(CircularBuffer{T}(b), 0)
end
Lag(b::Integer, T = Float64) = Lag{T}(b)
value(o::Lag) = reverse(o.circbuff)
_fit!(o::Lag, y) = (o.n += 1; push!(o.circbuff, y))
Base.length(o::Lag) = length(o.circbuff)
Base.getindex(o::Lag, i) = o.circbuff[end - i + 1]
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
    AutoCov(zeros(d), zeros(d), zeros(d), Lag{T}(d), Lag{Float64}(d), Variance(;kw...))
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

#-----------------------------------------------------------------------# CountMap
"""
    CountMap(T::Type)
    CountMap(dict::AbstractDict{T, Int})

Track a dictionary that maps unique values to its number of occurrences.  Similar to
`StatsBase.countmap`.

# Example

    o = fit!(CountMap(Int), rand(1:10, 1000))
    value(o)
    probs(o)
    OnlineStats.pdf(o, 1)
    collect(keys(o))
"""
mutable struct CountMap{T, A <: AbstractDict{T, Int}} <: OnlineStat{T}
    value::A  # OrderedDict by default
    n::Int
end
CountMap{T}() where {T} = CountMap{T, OrderedDict{T,Int}}(OrderedDict{T,Int}(), 0)
CountMap(T::Type = Any) = CountMap{T, OrderedDict{T,Int}}(OrderedDict{T, Int}(), 0)
CountMap(d::D) where {T,D<:AbstractDict{T, Int}} = CountMap{T, D}(d, 0)
function _fit!(o::CountMap, x)
    o.n += 1
    o.value[x] = get!(o.value, x, 0) + 1
end
_merge!(o::CountMap, o2::CountMap) = (merge!(+, o.value, o2.value); o.n += o2.n)
function probs(o::CountMap, kys = keys(o.value))
    out = zeros(Int, length(kys))
    valkeys = keys(o.value)
    for (i, k) in enumerate(kys)
        out[i] = k in valkeys ? o.value[k] : 0
    end
    sum(out) == 0 ? Float64.(out) : out ./ sum(out)
end
pdf(o::CountMap, y) = y in keys(o.value) ? o.value[y] / nobs(o) : 0.0
Base.keys(o::CountMap) = keys(o.value)
nkeys(o::CountMap) = length(o.value)
Base.values(o::CountMap) = values(o.value)
Base.getindex(o::CountMap, i) = o.value[i]

#-----------------------------------------------------------------------# Counter
mutable struct Counter <: OnlineStat{Any}
    n::Int
end
_fit!(o::Counter) = (o.n += 1)

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
        o.b = Vector{T}(undef, p)
        o.A = Matrix{T}(undef, p, p)
        o.value = Matrix{T}(undef, p, p)
    end
    smooth!(o.b, x, γ)
    smooth_syr!(o.A, x, γ)
end
nvars(o::CovMatrix) = size(o.A, 1)
function value(o::CovMatrix; corrected::Bool = true)
    o.value[:] = Matrix(Hermitian((o.A - o.b * o.b')))
    corrected && rmul!(o.value, unbias(o))
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

#-----------------------------------------------------------------------# CStat
"""
    CStat(stat)

Track a univariate OnlineStat for complex numbers.  A copy of `stat` is made to
separately track the real and imaginary parts.

# Example

    y = randn(100) + randn(100)im
    fit!(CStat(Mean()), y)
"""
struct CStat{O <: OnlineStat{Number}} <: OnlineStat{Number}
    re_stat::O
    im_stat::O
end
CStat(o::OnlineStat{<:Number}) = CStat(o, copy(o))
nobs(o::CStat) = nobs(o.re_stat)
value(o::CStat) = value(o.re_stat), value(o.im_stat)
_fit!(o::CStat, y::T) where {T<:Real} = (_fit!(o.re_stat, y); _fit!(o.im_stat, T(0)))
_fit!(o::CStat, y::Complex) = (_fit!(o.re_stat, y.re); _fit!(o.im_stat, y.im))
function _merge!(o::T, o2::T) where {T<:CStat}
    _merge!(o.re_stat, o2.re_stat)
    _merge!(o.im_stat, o2.im_stat)
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


#-----------------------------------------------------------------------# Extrema
"""
    Extrema(T::Type = Float64)

Maximum and minimum.

# Example

    o = fit!(Extrema(), rand(10^5))
    extrema(o)
    maximum(o)
    minimum(o)
"""
mutable struct Extrema{T} <: OnlineStat{Number}
    min::T
    max::T
    n::Int
end
Extrema(T::Type{<:Number} = Float64) = Extrema{T}(typemax.(T), typemin.(T), 0)
Extrema(initmin::T, initmax::T) where {T} = Extrema{T}(initmin, initmax, 0)
function _fit!(o::Extrema, y)
    o.min = min(o.min, y)
    o.max = max(o.max, y)
    o.n += 1
end
function _merge!(o::Extrema, o2::Extrema)
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
    FTSeries(stats...; filter=x->true, transform=identity)

Track multiple stats for one data stream that is filtered and transformed before being
fitted.

    FTSeries(T, stats...; filter, transform)

Create an FTSeries and specify the type `T` of the transformed values.

# Example

    o = FTSeries(Mean(), Variance(); transform=abs)
    fit!(o, -rand(1000))

    # Remove missing values represented as DataValues
    using DataValues
    y = DataValueArray(randn(100), rand(Bool, 100))
    o = FTSeries(DataValue, Mean(); transform=get, filter=!isna)
    fit!(o, y)
"""
mutable struct FTSeries{N, OS<:Tup, F, T} <: StatCollection{N}
    stats::OS
    filter::F
    transform::T
    nfiltered::Int
end
function FTSeries(stats::OnlineStat...; filter=x->true, transform=identity)
    Ts = input.(stats)
    FTSeries{promote_type(Ts...), typeof(stats), typeof(filter), typeof(transform)}(
        stats, filter, transform, 0
    )
end
function FTSeries(T::Type, stats::OnlineStat...; filter=x->true, transform=identity)
    FTSeries{T, typeof(stats), typeof(filter), typeof(transform)}(stats, filter, transform, 0)
end
value(o::FTSeries) = value.(o.stats)
nobs(o::FTSeries) = nobs(o.stats[1])
@generated function _fit!(o::FTSeries{N, OS}, y) where {N, OS}
    n = length(fieldnames(OS))
    quote
        if o.filter(y)
            yt = o.transform(y)
            Base.Cartesian.@nexprs $n i -> @inbounds begin
                _fit!(o.stats[i], yt)
            end
        else
            o.nfiltered += 1
        end
    end
end
function _merge!(o::FTSeries, o2::FTSeries)
    o.nfiltered += o2.nfiltered
    _merge!.(o.stats, o2.stats)
    o
end

#-----------------------------------------------------------------------# Group
"""
    Group(stats::OnlineStat...)
    Group(; stats...)
    Group(collection)

Create a vector-input stat from several scalar-input stats.  For a new
observation `y`, `y[i]` is sent to `stats[i]`.

# Examples

    x = randn(100, 2)
    
    fit!(Group(Mean(), Mean()), x)
    fit!(Group(Mean(), Variance()), x)

    o = fit!(Group(m1 = Mean(), m2 = Mean()), x)
    o.stats.m1
    o.stats.m2
"""
struct Group{T} <: StatCollection{VectorOb}
    stats::T
end
Group(o::OnlineStat...) = Group(o)
Group(;o...) = Group(o.data)
nobs(o::Group) = nobs(first(o.stats))
Base.:(==)(a::Group, b::Group) = all(a.stats .== b.stats)

Base.getindex(o::Group, i) = o.stats[i]
Base.first(o::Group) = first(o.stats)
Base.last(o::Group) = last(o.stats)
Base.length(o::Group) = length(o.stats)
Base.values(o::Group) = map(value, o.stats)

Base.iterate(o::Group) = (o.stats[1], 2)
Base.iterate(o::Group, i) = i > length(o) ? nothing : (o.stats[i], i + 1)

@generated function _fit!(o::Group{T}, y) where {T}
    N = fieldcount(T)
    :(Base.Cartesian.@nexprs $N i -> @inbounds(_fit!(o.stats[i], y[i])))
end
function _fit!(o::Group{T}, y) where {T<:AbstractVector}
    for (i,yi) in enumerate(y)
        _fit!(o.stats[i], yi)
    end
end

_merge!(o::Group, o2::Group) = map(merge!, o.stats, o2.stats)

Base.:*(n::Integer, o::OnlineStat) = Group([copy(o) for i in 1:n]...)

#-----------------------------------------------------------------------# GroupBy
"""
    GroupBy{T}(stat)

Update `stat` for each group (of type `T`).

# Example

    x = rand(1:10, 10^5)
    y = x .+ randn(10^5)
    fit!(GroupBy{Int}(Extrema()), zip(x,y))
"""
mutable struct GroupBy{T, O <: OnlineStat} <: OnlineStat{VectorOb}
    value::OrderedDict{T, O}
    init::O
    n::Int
end
GroupBy{T}(stat::O) where {T, O} = GroupBy{T,O}(OrderedDict{T, O}(), stat, 0)
function _fit!(o::GroupBy, xy)
    o.n += 1
    x, y = xy
    x in keys(o.value) ? fit!(o.value[x], y) : (o.value[x] = fit!(copy(o.init), y))
end
Base.getindex(o::GroupBy{T}, i::T) where {T} = o.value[i]
function Base.show(io::IO, o::GroupBy)
    print(io, name(o, false, true))
    for (i, (k,v)) in enumerate(o.value)
        char = i == length(o.value) ?  '└' : '├'
        print(io, "\n  $(char)── $k: $v")
    end
end

#-----------------------------------------------------------------------# StatHistory
"""
    StatHistory(stat, b)

Track a moving window (previous `b` copies) of `stat`.

# Example

    fit!(StatHistory(Mean(), 10), 1:20)
"""
struct StatHistory{T, O<:OnlineStat{T}} <: OnlineStat{T}
    stat::O
    circbuff::CircularBuffer{O}
end
function StatHistory(stat::O, b::Integer) where {T,O<:OnlineStat{T}}
    StatHistory{T,O}(stat, CircularBuffer{O}(b))
end
nobs(o::StatHistory) = nobs(o.stat)
function _fit!(o::StatHistory, y)
    _fit!(o.stat, y)
    pushfirst!(o.circbuff, copy(o.stat))
end
function Base.show(io::IO, o::StatHistory)
    print(io, name(o, false, true))
    print_stat_tree(io, o.circbuff)
end

#-----------------------------------------------------------------------# HyperLogLog
# Mostly copy/pasted from StreamStats.jl
"""
    HyperLogLog(b, T::Type = Number)  # 4 ≤ b ≤ 16

Approximate count of distinct elements.

# Example

    fit!(HyperLogLog(12), rand(1:10,10^5))
"""
mutable struct HyperLogLog{T} <: OnlineStat{T}
    m::UInt32
    M::Vector{UInt32}
    mask::UInt32
    altmask::UInt32
    n::Int
end
function HyperLogLog(b::Integer, S::Type = Number)
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
        HyperLogLog{S}(m, M, mask, altmask, 0)
    end
function Base.show(io::IO, o::HyperLogLog{T}) where {T}
    print(io, "HyperLogLog($(o.m) registers, input = $T, estimate = $(value(o)))")
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

function _merge!(o::HyperLogLog, o2::HyperLogLog)
    length(o.M) == length(o2.M) ||
        error("Merge failed. HyperLogLog objects have different number of registers.")
    o.n += o2.n
    for j in eachindex(o.M)
        o.M[j] = max(o.M[j], o2.M[j])
    end
    o
end

#-----------------------------------------------------------------------# KMeans
"""
    KMeans(p, k; rate=LearningRate(.6))

Approximate K-Means clustering of `k` clusters and `p` variables.

# Example

    clusters = rand(Bool, 10^5)

    x = [clusters[i] > .5 ? randn() : 5 + randn() for i in 1:10^5, j in 1:2]

    o = fit!(KMeans(2, 2), x)
"""
mutable struct KMeans{W} <: OnlineStat{VectorOb}
    value::Matrix{Float64}  # p × k
    v::Vector{Float64}
    rate::W
    n::Int
end
KMeans(p::Integer, k::Integer; rate=LearningRate(.6)) = KMeans(zeros(p, k), zeros(k), rate, 0)
function _fit!(o::KMeans, x)
    γ = o.rate(o.n += 1)
    p, k = size(o.value)
    if o.n <= k
        o.value[:, o.n] = collect(x)
    else
        for j in 1:k
            o.v[j] = 0.0
            for i in 1:p
                o.v[j] += abs2(x[i] - o.value[i, j])
            end
        end
        kstar = argmin(o.v)
        for i in 1:p
            o.value[i, kstar] = smooth(o.value[i, kstar], x[i], γ)
        end
    end
end

#-----------------------------------------------------------------------# Mean
"""
    Mean(; weight=EqualWeight())

Track a univariate mean.

# Update

``μ = (1 - γ) * μ + γ * x``

# Example

    @time fit!(Mean(), randn(10^6))
"""
mutable struct Mean{W} <: OnlineStat{Number}
    μ::Float64
    weight::W
    n::Int
end
Mean(;weight = EqualWeight()) = Mean(0.0, weight, 0)
_fit!(o::Mean, x) = (o.μ = smooth(o.μ, x, o.weight(o.n += 1)))
function _merge!(o::Mean, o2::Mean)
    o.n += o2.n
    o.μ = smooth(o.μ, o2.μ, o2.n / o.n)
end
Statistics.mean(o::Mean) = o.μ
Base.copy(o::Mean) = Mean(o.μ, o.weight, o.n)

#-----------------------------------------------------------------------# Moments
"""
    Moments(; weight=EqualWeight())

First four non-central moments.

# Example

    o = fit!(Moments(), randn(1000))
    mean(o)
    var(o)
    std(o)
    skewness(o)
    kurtosis(o)
"""
mutable struct Moments{W} <: OnlineStat{Number}
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
Statistics.mean(o::Moments) = o.m[1]
Statistics.var(o::Moments) = (o.m[2] - o.m[1] ^ 2) * unbias(o)
function skewness(o::Moments)
    v = value(o)
    vr = o.m[2] - o.m[1]^2
    (v[3] - 3.0 * v[1] * vr - v[1] ^ 3) / vr ^ 1.5
end
function kurtosis(o::Moments)
    v = value(o)
    (v[4] - 4.0 * v[1] * v[3] + 6.0 * v[1] ^ 2 * v[2] - 3.0 * v[1] ^ 4) / var(o) ^ 2 - 3.0
end
function _merge!(o::Moments, o2::Moments)
    γ = o2.n / (o.n += o2.n)
    smooth!(o.m, o2.m, γ)
    o
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
    @assert 0 < τ < 1
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
    p = o.n / (o.n + o2.n)
    for j in eachindex(o.value)
        if rand() > p
            o.value[j] = o2.value[j]
        end
    end
end

#-----------------------------------------------------------------------# Series
"""
    Series(stats)
    Series(stats...)
    Series(; stats...)

Track a collection stats for one data stream.

# Example

    s = Series(Mean(), Variance())
    fit!(s, randn(1000))
"""
struct Series{IN, T} <: StatCollection{IN}
    stats::T
    function Series(stats::T) where T
        IN = promote_type(map(input, values(stats))...)
        new{IN, T}(stats)
    end
end
Series(t::OnlineStat...) = Series(t)
Series(; t...) = Series(t.data)

value(o::Series) = map(value, o.stats)
nobs(o::Series) = nobs(o.stats[1])
@generated function _fit!(o::Series{IN, T}, y) where {IN, T}
    n = length(fieldnames(T))
    :(Base.Cartesian.@nexprs $n i -> _fit!(o.stats[i], y))
end
_merge!(o::Series, o2::Series) = map(_merge!, o.stats, o2.stats)

#-----------------------------------------------------------------------# Sum
"""
    Sum(T::Type = Float64)

Track the overall sum.

# Example

    fit!(Sum(Int), fill(1, 100))
"""
mutable struct Sum{T} <: OnlineStat{Number}
    sum::T
    n::Int
end
Sum(T::Type = Float64) = Sum(T(0), 0)
Base.sum(o::Sum) = o.sum
_fit!(o::Sum{T}, x::Real) where {T<:AbstractFloat} = (o.sum += convert(T, x); o.n += 1)
_fit!(o::Sum{T}, x::Real) where {T<:Integer} =       (o.sum += round(T, x); o.n += 1)
_merge!(o::T, o2::T) where {T <: Sum} = (o.sum += o2.sum; o.n += o2.n; o)

# #-----------------------------------------------------------------------# Summarizer
# mutable struct Summarizer{T} <: OnlineStat{T}
#     group::Group
# end
# nobs(o::Summarizer) = nobs(o.group)
