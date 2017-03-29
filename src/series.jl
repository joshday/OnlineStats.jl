"""
AbstractSeries:  "Managers" for a group or single OnlineStat

Subtypes should:
- Be first parameterized by I <: Input
- Have fields `weight::Weight`, `nobs::Int`, `nups::Int`, and `id::Symbol`
"""
abstract type AbstractSeries end


"""
### Series

Manager for a collection of OnlineStats (`stats...`).  `Series` tracks values necessary for
updating an OnlineStat (number of observations, weight, etc.)

```julia
Series(id, weight, stats...)
Series(weight, id, stats...)
Series(stats...; weight = EqualWeight(), id = :unlabeled)
Series(datavector, stats...; weight = EqualWeight(), id = :unlabeled)
```

#### Examples
- Updating
```julia
y1 = randn(100)
y2 = randn(100)

s = Series(Variance())

fit!(s, y1)
fit!(s, y2)

value(s)
```

- Merging
```julia
y1 = randn(100)
y2 = randn(100)

s1 = Series(y1, Mean(), Variance())
s2 = Series(y2, Mean(), Variance())

merge!(s1, s2)

value(s1)
nobs(s1)
```

- Methods
```julia
o = Series(randn(1000), Variance(), Moments())

value(o)        # tuple of values
value(o, 1)     # value from 1st stat (Variance)

v, m = stats(o) # tuple of OnlineStats
v = stats(o, 1) # get the first stat
```
"""
mutable struct Series{I <: Input, W <: Weight, O <: Tuple} <: AbstractSeries
    weight::W
    stats::O
    nobs::Int
    nups::Int
    id::Symbol
end
function Series{W<:Weight, O<:Tuple,}(wt::W, stats::O, id::Symbol)
    I = _io(stats[1], 1)
    all(x -> _io(x, 1) == I, stats) || throw(ArgumentError("Input types are not all $I"))
    Series{I, W, O}(wt, stats, 0, 0, id)
end

Series(id::Symbol, wt::Weight, stats...) = Series(wt, stats, id)
Series(wt::Weight, id::Symbol, stats...) = Series(wt, stats, id)
function Series(stats...; weight::Weight = EqualWeight(), id::Symbol = :unlabeled)
    Series(weight, stats, id)
end
function Series(y::AA, stats...; weight::Weight = EqualWeight(), id::Symbol = :unlabeled)
    o = Series(weight, id, stats...)
    fit!(o, y)
    o
end

stats(o::Series) = o.stats
stats(o::Series, i::Integer) = o.stats[i]

value(o::Series) = value.(stats(o))
value(o::Series, i::Integer) = value(stats(o, i))

nobs(o::AbstractSeries) = o.nobs
nups(o::AbstractSeries) = o.nups
function Base.show{I}(io::IO, o::Series{I})
    header(io, "$(name(o))\n")
    subheader(io, "$(o.id) | $(o.nobs) | $(o.weight)\n")
    # subheader(io, "         id | $(o.id)\n")
    # subheader(io, "     weight | $(o.weight)\n")
    # subheader(io, "       nobs | $(o.nobs)\n")
    n = length(o.stats)
    for i in 1:n
        print(io, "  > ")
        print(io, o.stats[i])
        i != n && println(io)
        # s = o.stats[i]
        # print_item(io, name(s), value(s), i != n)
    end
end
updatecounter!(o::AbstractSeries, n2::Int = 1) = (o.nups += 1; o.nobs += n2)
weight(o::AbstractSeries, n2::Int = 1) = weight(o.weight, o.nobs, n2, o.nups)
nextweight(o::AbstractSeries, n2::Int = 1) = nextweight(o.weight, o.nobs, n2, o.nups)
Base.copy(o::AbstractSeries) = deepcopy(o)

#-------------------------------------------------------------------------# merge
Base.merge{T <: Series}(o::T, o2::T, method::Symbol = :append) = merge!(copy(o), o2, method)
function Base.merge!{T <: Series}(o::T, o2::T, method::Symbol = :append)
    n2 = nobs(o2)
    n2 == 0 && return o
    p = length(o.stats)
    for i in 1:p
        stat1 = o.stats[i]
        stat2 = o2.stats[i]
        if method == :append
            merge!(stat1, stat2, nextweight(o, n2))
        elseif method == :mean
            merge!(stat1, stat2, (weight(o) + weight(o2)))
        elseif method == :singleton
            merge!(stat1, stat2, nextweight(o))
        else
            throw(ArgumentError("method must be :append, :mean, or :singleton"))
        end
    end
    updatecounter!(o, n2)
    o
end

#-------------------------------------------------------------------------# ScalarIn
function fit!(o::Series{ScalarIn}, y::Real, γ::Float64 = nextweight(o))
    updatecounter!(o)
    map(stat -> fit!(stat, y, γ), o.stats)
    o
end
function fit!(o::Series{ScalarIn}, y::AVec)
    for yi in y
        fit!(o, yi)
    end
    o
end
function fit!(o::Series{ScalarIn}, y::AVec, b::Integer)
    maprows(b, y) do yi
        bi = length(yi)
        updatecounter!(o, bi)
        γ = weight(o, bi)
        map(stat -> fitbatch!(stat, yi, γ), o.stats)
    end
    o
end
function fit!(o::Series{ScalarIn}, y::AVec, γ::Float64)
    for yi in y
        fit!(o, yi, γ)
    end
    o
end
function fit!(o::Series{ScalarIn}, y::AVec, γ::AVecF)
    length(y) == length(γ) || throw(DimensionMismatch())
    for (yi, γi) in zip(y, γ)
        fit!(o, yi, γi)
    end
    o
end

#-------------------------------------------------------------------------# VectorIn
function fit!(o::Series{VectorIn}, y::AVec, γ::Float64 = nextweight(o))
    updatecounter!(o)
    map(stat -> fit!(stat, y, γ), o.stats)
    o
end
function fit!(o::Series{VectorIn}, y::AMat)
    for i in 1:size(y, 1)
        fit!(o, view(y, i, :))
    end
    o
end
function fit!(o::Series{VectorIn}, y::AMat, b::Integer)
    maprows(b, y) do yi
        bi = size(yi, 1)
        updatecounter!(o, bi)
        γ = weight(o, bi)
        map(stat -> fitbatch!(stat, yi, γ), o.stats)
    end
    o
end
