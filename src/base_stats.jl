#-----------------------------------------------------------------------------# CircBuff
"""
    RepeatingRange(rng)

Range that repeats forever. e.g.

    r = OnlineStats.RepeatingRange(1:2)
    r[1:5] == [1, 2, 1, 2, 1]
"""
struct RepeatingRange{T<:AbstractRange}
    rng::T
end
Base.getindex(o::RepeatingRange, i::Int) = o.rng[rem(i - 1, length(o.rng)) + 1]
Base.getindex(o::RepeatingRange, rng::AbstractRange) = map(i -> getindex(o, i), rng)
Base.reverse(o::RepeatingRange) = RepeatingRange(reverse(o.rng))

"""
    CircBuff(T, b; rev=false)

Create a fixed-length circular buffer of `b` items of type `T`.
- `rev=false`: `o[1]` is the oldest.
- `rev=true`: `o[end]` is the oldest.

# Example

    a = CircBuff(Int, 5)
    b = CircBuff(Int, 5, rev=true)

    fit!(a, 1:10)
    fit!(b, 1:10)

    a[1] == b[end] == 1
    a[end] == b[1] == 10

    value(o; ordered=false)  # Retrieve values (no copy) without ordering
"""
mutable struct CircBuff{T,rev} <: OnlineStat{T}
    value::Vector{T}
    rng::RepeatingRange{Base.OneTo{Int}}
    n::Int
end
CircBuff(T, b::Int; rev=false) = CircBuff{T,rev}(T[], RepeatingRange(Base.OneTo(b)), 0)
CircBuff(b::Int, T = Float64; rev=false) = CircBuff(T, b; rev=rev)

Base.lastindex(o::CircBuff) = length(o.value)
Base.length(o::CircBuff) = length(o.value)

function Base.getindex(o::CircBuff, i::Int)
    nobs(o) ≤ length(o.rng.rng) ? o.value[i] : o.value[o.rng[nobs(o) + i]]
end
function Base.getindex(o::CircBuff{<:Any, true}, i::Int)
    i = length(o.value) - i + 1
    nobs(o) ≤ length(o.rng.rng) ? o.value[i] : o.value[o.rng[nobs(o) + i]]
end

function _fit!(o::CircBuff, y)
    (o.n += 1) ≤ length(o.rng.rng) ? push!(o.value, y) : o.value[o.rng[nobs(o)]] = y
end

value(o::CircBuff; ordered=true) = ordered ? eltype(o.value)[o[i] for i in 1:length(o.value)] : o.value




#-----------------------------------------------------------------------# Counter
"""
    Counter(T=Number)

Count the number of items in a data stream with elements of type `T`.

# Example

    fit!(Counter(Int), 1:100)
"""
mutable struct Counter{T} <: OnlineStat{T}
    n::Int
    Counter{T}() where {T} = new{T}(0)
end
Counter(T = Number) = Counter{T}()
_fit!(o::Counter{T}, y) where {T} = (o.n += 1)
_fit!(o::Counter{T}, y, n) where {T} = (o.n += n)
_merge!(a::Counter, b::Counter) = (a.n += b.n)

#-----------------------------------------------------------------------# CountMap
"""
    CountMap(T::Type)
    CountMap(dict::AbstractDict{T, Int})

Track a dictionary that maps unique values to its number of occurrences.  Similar to
`StatsBase.countmap`.

Counts can be incremented by values other than one (and decremented) using the `fit!(::CountMap{T}, ::Pair{T,Int})` method, e.g.

```julia
o = fit!(CountMap(String), ["A", "B"])
fit!(o, "A" => 5)
fit!(o, "A" => -1)
```

# Example

    o = fit!(CountMap(Int), rand(1:10, 1000))
    value(o)
    probs(o)
    OnlineStats.pdf(o, 1)
    collect(keys(o))
    sort!(o)
    delete!(o, 1)
"""
mutable struct CountMap{T, A <: AbstractDict{T, Int}} <: OnlineStat{Union{T, Pair{<:T,<:Integer}}}
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
function _fit!(o::CountMap{T}, xy::Pair{<:T, <:Integer}) where {T}
    x, y = xy
    o.n += y
    o.value[x] = get!(o.value, x, 0) + y
end
function _fit!(o::CountMap{T}, x, n) where {T}
    o.n += n
    o.value[x] = get!(o.value, x, 0) + n
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
Base.keys(o::CountMap) = keys(value(o))
nkeys(o::CountMap) = length(value(o))
Base.values(o::CountMap) = values(value(o))
Base.getindex(o::CountMap, i) = value(o)[i]
Base.sort!(o::CountMap) = (sort!(value(o)); o)
function Base.delete!(o::CountMap, level)
    x = value(o)[level]
    delete!(value(o), level)
    o.n -= x
    o
end

#-----------------------------------------------------------------------# CovMatrix
"""
    CovMatrix(p=0; weight=EqualWeight())
    CovMatrix(::Type{T}, p=0; weight=EqualWeight())

Calculate a covariance/correlation matrix of `p` variables.  If the number of variables is
unknown, leave the default `p=0`.

# Example

    o = fit!(CovMatrix(), randn(100, 4) |> eachrow)
    cor(o)
    cov(o)
    mean(o)
    var(o)
"""
mutable struct CovMatrix{T,W} <: OnlineStat{AbstractVector{<:Number}} where T<:Number
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

#-----------------------------------------------------------------------# Extrema
"""
    Extrema(T::Type = Float64)
    Extrema(min_init::T, max_init::T)

Maximum and minimum (and number of occurrences for each) for a data stream of type `T`.

# Example

    Extrema(Float64) == Extrema(Inf, -Inf)

    o = fit!(Extrema(), rand(10^5))
    extrema(o)
    maximum(o)
    minimum(o)
"""
mutable struct Extrema{T,S} <: OnlineStat{S}
# T is type to store data, S is type of single observation.
# E.g. you may want to accept any Number even if you are storing values as Float64
    min::T
    max::T
    nmin::Int
    nmax::Int
    n::Int
end
Extrema(a::T, b::T) where {T} = Extrema{T,S}(a, b, 0, 0, 0)
function Extrema(T::Type = Float64)
    a, b, S = extrema_init(T)
    Extrema{T,S}(a, b, 0, 0, 0)
end
extrema_init(T::Type{<:Number}) = typemax(T), typemin(T), Number
extrema_init(T::Type{<:AbstractString}) = T(""), T(""), AbstractString
extrema_init(T::Type{<:TimeType}) = typemax(T), typemin(T), TimeType
extrema_init(T::Type) = rand(T), rand(T), T
function _fit!(o::Extrema, y)
    (o.n += 1) == 1 && (o.min = o.max = y)
    if y < o.min
        o.min = y
        o.nmin = 0
    elseif y > o.max
        o.max = y
        o.nmax = 0
    end
    y == o.min && (o.nmin += 1)
    y == o.max && (o.nmax += 1)
end
function _fit!(o::Extrema, y, n)
    (o.n += n) == n && (o.min = o.max = y)
    if y < o.min
        o.min = y
        o.nmin = 0
    elseif y > o.max
        o.max = y
        o.nmax = 0
    end
    y == o.min && (o.nmin += n)
    y == o.max && (o.nmax += n)
end
function _merge!(a::Extrema, b::Extrema)
    if a.min == b.min
        a.nmin += b.nmin
    elseif b.min < a.min
        a.min = b.min
        a.nmin = b.nmin
    end
    if a.max == b.max
        a.nmax += b.nmax
    elseif b.max > a.max
        a.max = b.max
        a.nmax = b.nmax
    end
    a.n += b.n
end
value(o::Extrema) = (min=o.min, max=o.max, nmin=o.nmin, nmax=o.nmax)
Base.extrema(o::Extrema) = (o.min, o.max)
Base.maximum(o::Extrema) = o.max
Base.minimum(o::Extrema) = o.min

#-----------------------------------------------------------------------------# ExtremeValues
"""
    ExtremeValues(T = Float64, b=25)

Track the `b` smallest and largest values of a data stream (as well as how many times that value occurred).

# Example

    o = ExtremeValues(Int, 3)

    fit!(o, 1:100)

    value(o).lo  # [1 => 1, 2 => 1, 3 => 1]

    value(o).hi  # [98 => 1, 99 => 1, 100 => 1]
"""
mutable struct ExtremeValues{T, S} <: OnlineStat{S}
    lo::OrderedDict{T, Int}
    hi::OrderedDict{T, Int}
    b::Int
    n::Int
end
value(o::ExtremeValues) = (; lo=sort!(o.lo), hi=sort!(o.hi))
function ExtremeValues(T::Type = Float64, b=25)
    _, _, S = extrema_init(T)
    ExtremeValues{T,S}(OrderedDict(), OrderedDict(), b, 0)
end

_fit!(o::ExtremeValues{T,S}, y::S) where {T,S} = _fit!(o, y => 1)

function _fit!(o::ExtremeValues{T,S}, pr::Pair{<:S, Int}) where {T,S}
    y, n = pr
    o.n += n
    lo, hi, b = o.lo, o.hi, o.b
    isempty(lo) && return (lo[y] = hi[y] = n)  # Case 1: First observation
    if y in keys(lo) || y in keys(hi)  # Case 2: y already in lo and/or hi
        y in keys(lo) && (lo[y] += n)
        y in keys(hi) && (hi[y] += n)
        return
    end
    length(lo) < b && return (lo[y] = n; hi[y] = n)
    y < maximum(keys(lo)) && (lo[y] = n)
    y > minimum(keys(hi)) && (hi[y] = n)
    length(lo) > b && delete!(lo, maximum(keys(lo)))
    length(hi) > b && delete!(hi, minimum(keys(hi)))
end

function _merge!(a::ExtremeValues, b::ExtremeValues)
    old_n = a.n
    for pair in b.lo
        _fit!(a, pair)
    end
    for pair in b.hi
        _fit!(a, pair)
    end
    a.n = old_n + b.n
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

    fit!(Group(Mean(), Mean()), eachrow(x))
    fit!(Group(Mean(), Variance()), eachrow(x))

    o = fit!(Group(m1 = Mean(), m2 = Mean()), eachrow(x))
    o.stats.m1
    o.stats.m2

    o = Group(fill(Mean(), 10))
    fit!(o, eachrow(randn(100, 10)))
"""
struct Group{T, S} <: StatCollection{S}
    stats::T
    function Group(stats::T) where {T}
        inputs = map(input, values(stats))
        tup = Tuple{inputs...}
        promoted_type = reduce(promote_type, inputs)
        S = Union{tup, NamedTuple{names, R} where R<:tup, AbstractVector{<: promoted_type}} where names
        new{T,S}(stats)
    end
end
Group(o::OnlineStat...) = Group(o)
Group(;o...) = Group(NamedTuple(o))
nobs(o::Group) = nobs(first(o.stats))
Base.:(==)(a::Group, b::Group) = all(x -> ==(x...), zip(a.stats, b.stats))

Base.getindex(o::Group, i) = o.stats[i]
Base.first(o::Group) = first(o.stats)
Base.last(o::Group) = last(o.stats)
Base.lastindex(o::Group) = length(o)
Base.length(o::Group) = length(o.stats)
Base.values(o::Group) = map(value, o.stats)

Base.iterate(o::Group) = (o.stats[1], 2)
Base.iterate(o::Group, i) = i > length(o) ? nothing : (o.stats[i], i + 1)

function _fit!(o::Group{<:OrderedDict}, y)
    for (yi, stat) in zip(y, values(o.stats))
        _fit!(stat, yi)
    end
end

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
    GroupBy(T, stat)

Update `stat` for each group (of type `T`).  A single observation is either a (named)
tuple with two elements or a Pair.

# Example

    x = rand(Bool, 10^5)
    y = x .+ randn(10^5)
    fit!(GroupBy(Bool, Series(Mean(), Extrema())), zip(x,y))
"""
mutable struct GroupBy{T, S, O <: OnlineStat{S}} <: StatCollection{TwoThings{T,S}}
    value::OrderedDict{T, O}
    init::O
    n::Int
    function GroupBy(value::OrderedDict{T,O}, init::O, n::Int) where {T,S,O<:OnlineStat{S}}
        new{T,S,O}(value, init, n)
    end
end
GroupBy(T::Type, stat::O) where {O<:OnlineStat} = GroupBy(OrderedDict{T, O}(), stat, 0)
function _fit!(o::GroupBy, xy)
    o.n += 1
    x, y = xy
    x in keys(o.value) ? fit!(o.value[x], y) : (o.value[x] = fit!(copy(o.init), y))
end
Base.getindex(o::GroupBy{T}, i::T) where {T} = o.value[i]
AbstractTrees.children(o::GroupBy) = collect(o.value)
AbstractTrees.printnode(io::IO, o::GroupBy{T,S,O}) where {T,S,O} = print(io, "GroupBy: $T => $(name(O,false,false))")
Base.sort!(o::GroupBy) = (sort!(o.value); o)
function _merge!(a::GroupBy{T,O}, b::GroupBy{T,O}) where {T,O}
    a.init == b.init || error("Cannot merge GroupBy objects with different inits")
    a.n += b.n
    merge!((o1, o2) -> merge!(o1, o2), a.value, b.value)
end

#-----------------------------------------------------------------------# Mean
"""
    Mean(T = Float64; weight=EqualWeight())

Track a univariate mean, stored as type `T`.

# Example

    @time fit!(Mean(), randn(10^6))
"""
mutable struct Mean{T,W} <: OnlineStat{Number}
    μ::T
    weight::W
    n::Int
end
Mean(T::Type{<:Number} = Float64; weight = EqualWeight()) = Mean(zero(T), weight, 0)
function _fit!(o::Mean{T}, x) where {T}
    o.μ = smooth(o.μ, x, o.weight(o.n += 1))
end
function _fit!(o::Mean{T, W}, y, n) where {T, W<:EqualWeight}
    o.n += n
    o.μ = smooth(o.μ, y, o.weight(o.n / n))
end
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
function Statistics.var(o::Moments; corrected=true)
    out = (o.m[2] - o.m[1] ^ 2)
    corrected ? bessel(o) * out : out
end
function StatsBase.skewness(o::Moments)
    v = value(o)
    vr = o.m[2] - o.m[1]^2
    (v[3] - 3.0 * v[1] * vr - v[1] ^ 3) / vr ^ 1.5
end
function StatsBase.kurtosis(o::Moments)
    m1, m2, m3, m4 = value(o)
    (m4 - 4.0 * m1 * m3 + 6.0 * m1^2 * m2 - 3.0 * m1 ^ 4) / var(o; corrected=false) ^ 2 - 3.0
end
function _merge!(o::Moments, o2::Moments)
    γ = o2.n / (o.n += o2.n)
    smooth!(o.m, o2.m, γ)
end

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
_fit!(o::Sum{T}, x::Number) where {T} = (o.sum += convert(T, x); o.n += 1)
_fit!(o::Sum{T}, x::Number, n) where {T} = (o.sum += convert(T, x * n); o.n += n)
_merge!(o::T, o2::T) where {T <: Sum} = (o.sum += o2.sum; o.n += o2.n; o)

#-----------------------------------------------------------------------# Variance
"""
    Variance(T = Float64; weight=EqualWeight())

Univariate variance, tracked as type `T`.

# Example

    o = fit!(Variance(), randn(10^6))
    mean(o)
    var(o)
    std(o)
"""
mutable struct Variance{T, S, W} <: OnlineStat{Number}
    σ2::S
    μ::T
    weight::W
    n::Int
end
function Variance(T::Type{<:Number} = Float64; weight = EqualWeight())
    Variance(zero(T) ^ 2 / one(T), zero(T) / one(T), weight, 0)
end
Base.copy(o::Variance) = Variance(o.σ2, o.μ, o.weight, o.n)
function _fit!(o::Variance{T}, x) where {T}
    μ = o.μ
    γ = o.weight(o.n += 1)
    o.μ = smooth(o.μ, T(x), γ)
    o.σ2 = smooth(o.σ2, (T(x) - o.μ) * (T(x) - μ), γ)
end
function _merge!(o::Variance, o2::Variance)
    γ = o2.n / (o.n += o2.n)
    δ = o2.μ - o.μ
    o.σ2 = smooth(o.σ2, o2.σ2, γ) + δ ^ 2 * γ * (1.0 - γ)
    o.μ = smooth(o.μ, o2.μ, γ)
end
function value(o::Variance{T}) where {T}
    if nobs(o) > 1
        o.σ2 * T(bessel(o))
    else
        isfinite(mean(o)) ? T(1) ^ 2 : NaN * T(1) ^ 2
    end
end
Statistics.var(o::Variance) = value(o)
Statistics.mean(o::Variance) = o.μ


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
    Series(stats::T) where {T} = new{Union{map(input, values(stats))...}, T}(stats)
end
Series(t::OnlineStat...) = Series(t)
Series(; t...) = Series(NamedTuple(t))

value(o::Series) = map(value, o.stats)
nobs(o::Series) = nobs(o.stats[1])

function _fit!(o::Series{IN, T}, y) where {IN, T <: OrderedDict}
    for stat in values(o.stats)
        _fit!(stat, y)
    end
end
@generated function _fit!(o::Series{IN, T}, y) where {IN, T}
    n = length(fieldnames(T))
    :(Base.Cartesian.@nexprs $n i -> _fit!(o.stats[i], y))
end
_merge!(o::Series, o2::Series) = map(_merge!, o.stats, o2.stats)

Base.getindex(o::Series, i) = o.stats[i]
