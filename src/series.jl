abstract type AbstractSeries end
#----------------------------------------------------------------# AbstractSeries methods
# helpers for weight
nobs(o::AbstractSeries) = nobs(o.weight)

"""
```julia
nups(Series(Mean()))
```
Return the number of updates a series has done.  Differs from `nobs` only when batch updates
have been used.
"""
nups(o::AbstractSeries) = nups(o.weight)
weight(o::AbstractSeries, n2::Int = 1) = weight(o.weight, n2)
weight!(o::AbstractSeries, n2::Int = 1) = weight!(o.weight, n2)
updatecounter!(o::AbstractSeries, n2::Int = 1) = updatecounter!(o.weight, n2)


Base.copy(o::AbstractSeries) = deepcopy(o)
function Base.show(io::IO, o::AbstractSeries)
    header(io, "$(name(o))\n")
    subheader(io, "$(o.weight)\n")
    show_series(io, o)
end
show_series(io::IO, o::AbstractSeries) = print(io)

#----------------------------------------------------------------# Series
"""
```julia
Series(onlinestats...)
Series(weight, onlinestats...)
Series(data, onlinestats...)
Series(data, weight, onlinestats...)
```

Manager for an OnlineStat or tuple of OnlineStats.
### Examples
```julia
s = Series(Mean())
s = Series(ExponentialWeight(), Mean(), Variance())
s = Series(randn(100, 3), CovMatrix(3))
```
"""
mutable struct Series{I, OS <: Union{Tuple, OnlineStat{I}}, W <: Weight} <: AbstractSeries
    weight::W
    stats::OS
end
function Series(wt::Weight, T::Union{Tuple, OnlineStat})
    Series{input(T), typeof(T), typeof(wt)}(wt, T)
end

Series(wt::Weight, o) = Series(wt, o)
Series(wt::Weight, o...) = Series(wt, o)

Series(o) = Series(default_weight(o), o)
Series(o...) = Series(default_weight(o), o)

Series(y::AA, o) = (s = Series(default_weight(o), o); fit!(s, y))
Series(y::AA, o...) = (s = Series(default_weight(o), o); fit!(s, y))

Series(y::AA, wt::Weight, o) = (s = Series(wt, o); fit!(s, y))
Series(y::AA, wt::Weight, o...) = (s = Series(wt, o); fit!(s, y))


# Need the following so this works:  for stat in s.stats
Base.start(o::OnlineStat) = false
Base.next(o::OnlineStat, state) = o, true
Base.done(o::OnlineStat, state) = state

show_series(io::IO, s::Series{0}) = print_item.(io, name.(s.stats), value.(s.stats))
function show_series(io::IO, s::Series)
    for stat in s.stats
        print_item(io, name(stat), "")
        print(io, value(stat))
    end
end

"Map `value` to the `stats` field of a Series."
value(s::Series) = map(value, s.stats)
value(s::Series, i::Integer) = value(s.stats[i])

"Return the `stats` field of a Series."
stats(s::Series) = s.stats
stats(s::Series, i::Integer) = s.stats[i]


Base.map(f::Function, o::OnlineStat) = f(o)
#-----------------------------------------------------------------------# Series{0}
const Singleton = Union{Real, Symbol, AbstractString}  # for FitCategorical/HyperLogLog
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
function fit!(s::Series{0}, y::Singleton)
    γ = weight!(s)
    map(s -> fit!(s, y, γ), s.stats)
    s
end
function fit!(s::Series{0}, y::Singleton, γ::Float64)
    updatecounter!(s)
    map(s -> fit!(s, y, γ), s.stats)
    s
end
function fit!(s::Series{0}, y::AVec)
    for yi in y
        fit!(s, yi)
    end
    s
end
function fit!(s::Series{0}, y::AVec, γ::Float64)
    for yi in y
        fit!(s, yi, γ)
    end
    s
end
function fit!(s::Series{0}, y::AVec, γ::AVecF)
    length(y) == length(γ) || throw(DimensionMismatch())
    for (yi, γi) in zip(y, γ)
        fit!(s, yi, γi)
    end
    s
end
function fit!(s::Series{0}, y::AVec, b::Integer)
    maprows(b, y) do yi
        bi = length(yi)
        γ = weight!(s, bi)
        map(o -> fitbatch!(o, yi, γ), s.stats)
    end
    s
end

#-----------------------------------------------------------------------# Series{1}
function fit!(s::Series{1}, y::AVec)
    γ = weight!(s)
    map(s -> fit!(s, y, γ), s.stats)
    s
end
function fit!(s::Series{1}, y::AVec, γ::Float64)
    updatecounter!(s)
    map(s -> fit!(s, y, γ), s.stats)
    s
end
function fit!(s::Series{1}, y::AMat)
    for i in 1:size(y, 1)
        fit!(s, view(y, i, :))
    end
    s
end
function fit!(s::Series{1}, y::AMat, γ::Float64)
    for i in 1:size(y, 1)
        fit!(s, view(y, i, :), γ)
    end
    s
end
function fit!(s::Series{1}, y::AMat, γ::AVecF)
    for i in 1:size(y, 1)
        fit!(s, view(y, i, :), γ[i])
    end
    s
end
function fit!(s::Series{1}, y::AMat, b::Integer)
    maprows(b, y) do yi
        bi = size(yi, 1)
        γ = weight!(s, bi)
        map(o -> fitbatch!(o, yi, γ), s.stats)
    end
    s
end


#----------------------------------------------------------------# Series{1}, ObsDim=2
function fit!(s::Series{1}, y::AMat, ::ObsDim.Last)
    for i in 1:size(y, 2)
        fit!(s, view(y, :, i))
    end
    s
end
function fit!(s::Series{1}, y::AMat, γ::Float64, ::ObsDim.Last)
    for i in 1:size(y, 2)
        fit!(s, view(y, :, i), γ)
    end
    s
end
function fit!(s::Series{1}, y::AMat, γ::AVecF, ::ObsDim.Last)
    for i in 1:size(y, 2)
        fit!(s, view(y, :, i), γ[i])
    end
    s
end

#-----------------------------------------------------------------------# Series{(1, 0)}
function fit!(s::Series{(1,0)}, x::AVec, y::Number)
    γ = weight!(s)
    map(s -> fit!(s, x, y, γ), s.stats)
    s
end
function fit!(s::Series{(1,0)}, x::AVec, y::Number, γ::Float64)
    updatecounter!(s)
    map(s -> fit!(s, x, y, γ), s.stats)
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
function fit!(s::Series{(1, 0)}, x::AMat, y::AVec, b::Integer)
    maprows(b, x, y) do xi, yi
        bi = length(yi)
        γ = weight!(s, bi)
        map(o -> fitbatch!(o, xi, yi, γ), s.stats)
    end
    s
end


#-------------------------------------------------------------------------# merge
Base.merge{T <: Series}(s1::T, s2::T, method::Symbol = :append) = merge!(copy(s1), s2, method)
Base.merge{T <: Series}(s1::T, s2::T, w::Float64) = merge!(copy(s1), s2, w)

function Base.merge!{T <: Series}(s1::T, s2::T, method::Symbol = :append)
    n2 = nobs(s2)
    n2 == 0 && return s1
    updatecounter!(s1, n2)
    if method == :append
        merge!.(s1.stats, s2.stats, weight(s1, n2))
    elseif method == :mean
        merge!.(s1.stats, s2.stats, (weight(s1) + weight(s2)))
    elseif method == :singleton
        merge!.(s1.stats, s2.stats, weight(s1))
    else
        throw(ArgumentError("method must be :append, :mean, or :singleton"))
    end
    s1
end
function Base.merge!{T <: Series}(s1::T, s2::T, w::Float64)
    n2 = nobs(s2)
    n2 == 0 && return s1
    updatecounter!(s1, n2)
    merge!.(s1.stats, s2.stats, w)
    s1
end
