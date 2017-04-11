"""
AbstractSeries:  Managers for a group or single OnlineStat

Subtypes should:
- Have fields `weight::Weight`, `nobs::Int`, and `nups::Int`
"""
abstract type AbstractSeries end
#----------------------------------------------------------------# AbstractSeries methods
# helpers for weight
nobs(o::AbstractSeries) = nobs(o.weight)

"Return the number of updates"
nups(o::AbstractSeries) = nups(o.weight)
weight(o::AbstractSeries, n2::Int = 1) = weight(o.weight, n2)
weight!(o::AbstractSeries, n2::Int = 1) = weight!(o.weight, n2)
updatecounter!(o::AbstractSeries, n2::Int = 1) = updatecounter!(o.weight, n2)


Base.copy(o::AbstractSeries) = deepcopy(o)
function Base.show(io::IO, o::AbstractSeries)
    header(io, "$(name(o))\n")
    subheader(io, "weight = $(o.weight)\n")
    show_series(io, o)
end
show_series(io::IO, o::AbstractSeries) = print(io)

#----------------------------------------------------------------# Series
"""
    Series(onlinestats...)
    Series(weight, onlinestats...)
    Series(data, onlinestats...)
    Series(data, weight, onlinestats...)

Manager for an OnlineStat or tuple of OnlineStats.

    s = Series(Mean())
    s = Series(ExponentialWeight(), Mean(), Variance())
    s = Series(randn(100, 3), CovMatrix(3))
"""
mutable struct Series{I, OS <: Union{Tuple, OnlineStat{I}}, W <: Weight} <: AbstractSeries
    weight::W
    stats::OS
end
function Series(wt::Weight, S::Union{Tuple, OnlineStat})
    Series{input(S), typeof(S), typeof(wt)}(wt, S)
end
Series(wt::Weight, s...) = Series(wt, s)
Series(wt::Weight, s) = Series(wt, s)

Series(s...) = Series(default(Weight, s), s)
Series(s) = Series(default(Weight, s), s)

Series(y::AA, s...) = (o = Series(default(Weight, s), s); fit!(o, y))
Series(y::AA, s) = (o = Series(default(Weight, s), s); fit!(o, y))

Series(y::AA, wt::Weight, s...) = (o = Series(wt, s); fit!(o, y))
Series(y::AA, wt::Weight, s) = (o = Series(wt, s); fit!(o, y))


show_series(io::IO, s::Series) = print_item.(io, name.(s.stats), value.(s.stats))

"Map `value` to the `stats` field of a Series."
value(s::Series) = map(value, s.stats)
value(s::Series, i::Integer) = value(s.stats[i])

"Return the `stats` field of a Series."
stats(s::Series) = s.stats
stats(s::Series, i::Integer) = s.stats[i]


Base.map(f::Function, o::OnlineStat) = f(o)
#-----------------------------------------------------------------------# Series{0}
"""
    fit!(s, y)
    fit!(s, y, w)
Update a Series `s` with more data `y` and optional weighting `w`.
"""
function fit!(s::Series{0}, y::Real)
    γ = weight!(s)
    map(s -> fit!(s, y, γ), s.stats)
    s
end
function fit!(s::Series{0}, y::Real, γ::Float64)
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
