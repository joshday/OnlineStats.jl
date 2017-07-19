"""
    Series(stats...)
    Series(data, stats...)
    Series(weight, stats...)
    Series(weight, data, stats...)
A Series is a container for a Weight and any number of OnlineStats.  Updating the Series
with `fit!(s, data)` will update the OnlineStats it holds according to its Weight.

### Examples
    Series(randn(100), Mean(), Variance())
    Series(ExponentialWeight(.1), Mean())

    s = Series(Mean())
    fit!(s, randn(100))
    s2 = Series(randn(123), Mean())
    merge(s, s2)
"""
struct Series{I, OS <: Union{OnlineStat, Tuple}, W <: Weight} <: AbstractSeries
    weight::W
    stats::OS
end
# These act as inner constructors
Series(wt::Weight, t::Tuple)      = Series{input(t), typeof(t), typeof(wt)}(wt, t)
Series(wt::Weight, o::OnlineStat) = Series{input(o), typeof(o), typeof(wt)}(wt, o)

nobs(s::AbstractSeries) = OnlineStatsBase.nobs(s)

# empty
Series(t::Tuple)         = Series(weight(t), t)
Series(o::OnlineStat)    = Series(weight(o), o)
Series(o::OnlineStat...) = Series(weight(o), o)
Series(wt::Weight, o::OnlineStat, os::OnlineStat...) = Series(wt, tuple(o, os...))

# init with data
Series(y::AA, o::OnlineStat)                = (s = Series(weight(o), o); fit!(s, y))
Series(y::AA, o::OnlineStat...)             = (s = Series(weight(o), o); fit!(s, y))
Series(y::AA, wt::Weight, o::OnlineStat)    = (s = Series(wt, o);        fit!(s, y))
Series(y::AA, wt::Weight, o::OnlineStat...) = (s = Series(wt, o);        fit!(s, y))
Series(wt::Weight, y::AA, o::OnlineStat)    = (s = Series(wt, o);        fit!(s, y))
Series(wt::Weight, y::AA, o::OnlineStat...) = (s = Series(wt, o);        fit!(s, y))

# Special constructors for (1, 0) input
# x, y, o
function Series(x::AbstractMatrix, y::AbstractVector, o::OnlineStat{(1,0)})
    s = Series(weight(o), o)
    fit!(s, x, y)
end
# x, y, o...
function Series(x::AbstractMatrix, y::AbstractVector, o::OnlineStat{(1,0)}...)
    s = Series(weight(o), o)
    fit!(s, x, y)
end
# w, x, y, o
function Series(wt::Weight, x::AbstractMatrix, y::AbstractVector, o::OnlineStat{(1,0)}...)
    s = Series(wt, o)
    fit!(s, x, y)
end
# x, y, w, o
function Series(x::AbstractMatrix, y::AbstractVector, wt::Weight, o::OnlineStat{(1,0)}...)
    s = Series(wt, o)
    fit!(s, x, y)
end

#--------------------------------------------------------------------------# Series methods
"Map `value` to the `stats` field of a Series."
value(s::Series) = map(value, s.stats)
value(s::Series, i) = value(s.stats[i])

"Return the `stats` field of a Series."
stats(s::Series) = s.stats

#---------------------------------------------------------------------------# fit helpers
const ScalarOb = Union{Number, AbstractString, Symbol}
const VectorOb = Union{AbstractVector, NTuple}
const Rows = ObsDim.First
const Cols = ObsDim.Last
const Data = Union{ScalarOb, VectorOb, AbstractMatrix}
const ColsRows = LearnBase.ObsDimension

struct ArraySlices{Dim, T <: AbstractMatrix}
    data::T
    ArraySlices(data::T, dim) where {T <: AbstractMatrix} = new{dim, typeof(data)}(data)
end
Base.start(o::ArraySlices) = 1
Base.next(o::ArraySlices{Rows()}, i) = view(o.data, i, :), i + 1
Base.next(o::ArraySlices{Cols()}, i) = view(o.data, :, i), i + 1
Base.done(o::ArraySlices, i) = i > length(o)
Base.length(o::ArraySlices{Rows()}) = size(o.data, 1)
Base.length(o::ArraySlices{Cols()}) = size(o.data, 2)


eachob(y,           s::Series,    dim) = error("$(typeof(y)) is not an input for $(typeof(s))")
eachob(y::ScalarOb, s::Series{0}, dim) = y
eachob(y::VectorOb, s::Series{1}, dim) = (y,)
eachob(y::VectorOb, s::Series{0}, dim) = y
eachob(y::AMat,     s::Series{1}, dim) = ArraySlices(y, dim)


#--------------------------------------------------------------------------------# fit!
"""
```julia
fit!(s, y)
fit!(s, y, w)
```
Update a Series `s` with more data `y` and optional weighting `w`.
### Examples
```julia
y = randn(100)
w = rand(100)

s = Series(Mean())
fit!(s, y[1])        # one observation: use Series weight
fit!(s, y[1], w[1])  # one observation: override weight
fit!(s, y)           # multiple observations: use Series weight
fit!(s, y, w[1])     # multiple observations: override each weight with w[1]
fit!(s, y, w)        # multiple observations: y[i] uses weight w[i]
```
"""
function fit!(s::Union{Series{0}, Series{1}}, y::Data, dim::ColsRows = Rows())
    for yi in eachob(y, s, dim)
        γ = weight!(s)
        foreach(s -> fit!(s, yi, γ), s.stats)
    end
    s
end
function fit!(s::Union{Series{0}, Series{1}}, y::Data, w::Float64, dim::ColsRows = Rows())
    for yi in eachob(y, s, dim)
        updatecounter!(s)
        foreach(s -> fit!(s, yi, w), s.stats)
    end
    s
end
function fit!(s::Union{Series{0}, Series{1}}, y::Data, w::VecF, dim::ColsRows = Rows())
    data_it = eachob(y, s, dim)
    length(w) == length(data_it) || throw(DimensionMismatch("weights don't match data length"))
    for (yi, wi) in zip(data_it, w)
        updatecounter!(s)
        foreach(s -> fit!(s, yi, wi), s.stats)
    end
    s
end
fit!(s1::T, s2::T) where {T <: Series} = merge!(s1, s2)


# TODO: put (1,0) input into above format
#-----------------------------------------------------------------------# Series{(1, 0)}
function fit!(s::Series{(1,0)}, x::AVec, y::Real)
    γ = weight!(s)
    foreach(s -> fit!(s, x, y, γ), s.stats)
    s
end
function fit!(s::Series{(1,0)}, x::AVec, y::Number, γ::Float64)
    updatecounter!(s)
    foreach(s -> fit!(s, x, y, γ), s.stats)
    s
end
function fit!(s::Series{(1, 0)}, x::AMat, y::AVec)
    for i in eachindex(y)
        fit!(s, view(x, i, :), y[i])
    end
    s
end
function fit!(s::Series{(1, 0)}, x::AMat, y::AVec, γ::Float64)
    for i in eachindex(y)
        fit!(s, view(x, i, :), y[i], γ)
    end
    s
end
function fit!(s::Series{(1, 0)}, x::AMat, y::AVec, γ::AVecF)
    for i in eachindex(y)
        fit!(s, view(x, i, :), y[i], γ[i])
    end
    s
end
