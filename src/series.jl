#-----------------------------------------------------------------------# AbstractSeries
# Required methods: stats(s), nobs(s), getweight(s)
abstract type AbstractSeries{N} end

stats(s::AbstractSeries) = s.stats
nobs(s::AbstractSeries) = s.n
value(s::AbstractSeries) = value.(stats(s))

getweight(s::AbstractSeries) = s.weight
weight(s::AbstractSeries) = s.weight(s.n)
weight!(s::AbstractSeries) = s.weight(s.n += 1)

function Base.:(==)(o1::AbstractSeries, o2::AbstractSeries)
    nms = fieldnames(o1)
    all(getfield.(o1, nms) .== getfield.(o2, nms))
end
function Base.:(≈)(o1::AbstractSeries, o2::AbstractSeries)
    nms = fieldnames(o1)
    all(getfield.(o1, nms) .≈ getfield.(o2, nms))
end
Base.copy(s::AbstractSeries) = deepcopy(s)

# Optional second line of show method
describe(s::AbstractSeries) = ""

function Base.show(io::IO, s::AbstractSeries{N}) where {N}
    header = "▦ $(name(s,false,false)){$N}  |  $(getweight(s))  |  nobs = $(nobs(s))"
    print_with_color(:green, io, header)
    desc = describe(s)
    desc != "" && print_with_color(:green, io, "\n▦ ", describe(s))
    n = length(stats(s))
    i = 0
    for o in stats(s)
        i += 1
        char = (i == n) ? "└──" : "├──"
        print(io, "\n$char $o")
    end
end

function series(args::Union{OnlineStat, Weight}...; kw...)
    s = Series(args...)
    length(kw) == 0 ? s : AugmentedSeries(s; kw...)
end
function series(y::Data, args::Union{OnlineStat, Weight}...; kw...)
    s = series(args...; kw...)
    fit!(s, y)
    s
end


#-----------------------------------------------------------------------# Series
"""
    Series(stats...)
    Series(weight, stats...)
    Series(data, weight, stats...)
    Series(data, stats...)
    Series(weight, data, stats...)

Track any number of OnlineStats.

# Example 

    Series(Mean())
    Series(randn(100), Mean())
    Series(randn(100), ExponentialWeight(), Mean())

    s = Series(Quantile([.25, .5, .75]))
    fit!(s, randn(1000))
"""
mutable struct Series{N, T <: Tuple, W} <: AbstractSeries{N}
    stats::T
    weight::W
    n::Int
end
const WeightLike = Union{Weight, Function}
function Series(w::WeightLike, o::OnlineStat{N}...) where {N} 
    Series{N, typeof(o), typeof(w)}(o, w, 0)
end
Series(o::OnlineStat{N}...) where {N} = Series(default_weight(o), o...)

# init with data
Series(y::Data, o::OnlineStat{N}...) where {N} = (s = Series(o...); fit!(s, y))
function Series(y::Data, wt::WeightLike, o::OnlineStat{N}...) where {N}
    s = Series(wt, o...)
    fit!(s, y)
end
Series(wt::WeightLike, y::Data, o::OnlineStat{N}...) where {N} = Series(y, wt, o...)

function fit!(s::Series{0}, y::ScalarOb)
    γ = weight!(s)
    map(x -> fit!(x, y, γ), stats(s))
    s
end
function fit!(s::Series{1}, y::VectorOb)
    s.n += 1
    γ = s.weight(s.n)
    map(x -> fit!(x, y, γ), stats(s))
    s
end
function fit!(s::Series{(1,0)}, xy::Tuple{<:VectorOb, <:ScalarOb})
    γ = weight!(s)
    map(o -> fit!(o, xy, γ), stats(s))
    s
end


#-----------------------------------------------------------------------# AugmentedSeries 
"""
    AugmentedSeries(s::Series; filter = x->true, transform = identity)

Wrapper around a `Series` so that for new `data`, fitting occurs on `transform(data)`, but 
only if `filter(data) == true`.
"""
struct AugmentedSeries{N, S <: Series{N}, F1, F2, F3} <: AbstractSeries{N}
    series::S
    filter::F1 
    transform::F2 
    callback::F3
end
function AugmentedSeries(s::Series{N}; filter=always, transform=identity, callback=identity) where {N}
    S, A, B, C = typeof(s), typeof(filter), typeof(transform), typeof(callback)
    AugmentedSeries{N, S, A, B, C}(s, filter, transform, callback)
end

describe(s::AugmentedSeries) = "filter = $(s.filter)  |  transform = $(s.transform)"

"always returns true"
always(args...) = true

for f in [:nobs, :value, :stats, :weight, :weight!, :getweight]
    @eval $f(o::AugmentedSeries) = $f(o.series)
end

function fit!(s::AugmentedSeries{0}, y::ScalarOb) 
    s.filter(y) && fit!(s.series, s.transform(y))
    s 
end
function fit!(s::AugmentedSeries{1}, y::VectorOb) 
    s.filter(y) && fit!(s.series, s.transform(y))
    s
end
function fit!(s::AugmentedSeries{(1,0)}, xy::XyOb)
    s.filter(xy) && fit!(s.series, s.transform(xy))
    s
end

#-----------------------------------------------------------------------# fit! 0
"""
    fit!(s::Series, data)

Update a Series with more `data`. 

# Examples

    # Univariate Series 
    s = Series(Mean())
    fit!(s, randn(100))

    # Multivariate Series
    x = randn(100, 3)
    s = Series(CovMatrix(3))
    fit!(s, x)  # Same as fit!(s, x, Rows())
    fit!(s, x', Cols())

    # Model Series
    x, y = randn(100, 10), randn(100)
    s = Series(LinReg(10))
    fit!(s, (x, y))
"""
function fit!(s::AbstractSeries{0}, y::AbstractArray)
    for yi in y 
        fit!(s, yi)
    end
    s
end

function fit!(s::AbstractSeries{1}, y::AbstractMatrix, ::Rows = Rows())
    n, p = size(y)
    buffer = Vector{eltype(y)}(p)
    for i in 1:n
        for j in 1:p
            @inbounds buffer[j] = y[i, j]
        end
        fit!(s, buffer)
    end
    s
end
function fit!(s::AbstractSeries{1}, y::AbstractMatrix, ::Cols)
    p, n = size(y)
    buffer = Vector{eltype(y)}(p)
    for i in 1:n
        for j in 1:p
            @inbounds buffer[j] = y[j, i]
        end
        fit!(s, buffer)
    end
    s
end

function fit!(s::AbstractSeries{(1,0)}, xy::Tuple{<:AbstractMatrix, <:VectorOb}, ::Rows = Rows())
    x, y = xy
    n, p = size(x)
    buffer = Vector{eltype(x)}(p)
    for i in 1:n 
        for j in 1:p 
            buffer[j] = x[i, j]
        end
        fit!(s, (buffer, y[i]))
    end
    s
end
function fit!(s::AbstractSeries{(1,0)}, xy::Tuple{<:AbstractMatrix, <:VectorOb}, ::Cols)
    x, y = xy
    p, n = size(x)
    buffer = Vector{eltype(x)}(p)
    for i in 1:n 
        for j in 1:p 
            @inbounds buffer[j] = x[j, i]
        end
        fit!(s, (buffer, y[i]))
    end
    s
end

# undocumented, sometimes useful helpers for JuliaDB, testing, etc.
(s::Series)(args...) = fit!(s, args...)
(::Series)(s::Series, args...) = s(args...)
fit!(o::OnlineStat, y) = Series(y, o)

#-----------------------------------------------------------------------# merging
"See [`merge!`](@ref)"
Base.merge(s1::T, s2::T, w::Float64) where {T<:AbstractSeries} = merge!(copy(s1), s2, w)
Base.merge(s1::T, s2::T, m::Symbol = :append) where {T <: AbstractSeries} = merge!(copy(s1), s2, m)



"""
    merge!(s1::Series, s2::Series, arg)

Merge `s2` into `s1` in place where `s2`'s influence is determined by `arg`. Options for
`arg`` are:

- `:append` (default)
    - `append `s2` to `s1` with influence determined by number of observations.  For 
    `EqualWeight`, this is equivalent to `fit!(s1, data2)` where `s2 = Series(data2, o...)`.
- `:mean`
    - Use the average (weighted by nobs) of the Series' generated weights.
- `:singleton`
    - treat `s2` as a single observation.
- any `Float64` in [0, 1]
"""
function Base.merge!(s1::T, s2::T, method::Symbol = :append) where {T <: Series}
    n1 = nobs(s1)
    n2 = nobs(s2)
    n2 == 0 && return s1
    s1.n += n2
    if method == :append
        merge!.(s1.stats, s2.stats, n2 / s1.n)
    elseif method == :mean
        w = (n1 * s1.weight(n1) + n2 * s2.weight(n2)) / (n1 + n2)
        merge!.(s1.stats, s2.stats, w)
    elseif method == :singleton
        merge!.(s1.stats, s2.stats, s1.weight(s1.n))
    else
        throw(ArgumentError("method must be :append, :mean, or :singleton"))
    end
    s1
end
function Base.merge!(s1::T, s2::T, w::Float64) where {T <: Series}
    n2 = nobs(s2)
    n2 == 0 && return s1
    0 <= w <= 1 || throw(ArgumentError("weight must be between 0 and 1"))
    s1.n += n2
    merge!.(s1.stats, s2.stats, w)
    s1
end

# merge AugmentedSeries
function Base.merge!(s1::T, s2::T, method::Symbol = :append) where {T <: AugmentedSeries}
    n1 = nobs(s1)
    n2 = nobs(s2)
    n2 == 0 && return s1
    s1.series.n += n2
    if method == :append
        merge!.(s1.series.stats, s2.series.stats, n2 / s1.series.n)
    elseif method == :mean
        w = (n1 * s1.series.weight(n1) + n2 * s2.weight(n2)) / (n1 + n2)
        merge!.(s1.series.stats, s2.series.stats, w)
    elseif method == :singleton
        merge!.(s1.series.stats, s2.series.stats, s1.series.weight(s1.series.n))
    else
        throw(ArgumentError("method must be :append, :mean, or :singleton"))
    end
    s1
end
function Base.merge!(s1::T, s2::T, w::Float64) where {T <: AugmentedSeries}
    n2 = nobs(s2)
    n2 == 0 && return s1
    0 <= w <= 1 || throw(ArgumentError("weight must be between 0 and 1"))
    s1.series.n += n2
    merge!.(s1.series.stats, s2.series.stats, w)
    s1
end