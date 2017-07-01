struct Series{I, OS <: Union{OnlineStat, Tuple}, W <: Weight} <: AbstractSeries
    weight::W
    stats::OS
end
function Series(wt::Weight, T::Union{Tuple, OnlineStat})
    Series{input(T), typeof(T), typeof(wt)}(wt, T)
end

# check default weights match during outer constructors
default_weight(o::OnlineStat) = EqualWeight()
default_weight(o::StochasticStat) = LearningRate()
function default_weight(t::Tuple)
    w = default_weight(t[1])
    if !all(map(x -> default_weight(x) == w, t))
        throw(ArgumentError("Default weights differ.  Weight must be specified"))
    end
    w
end

nobs(s::AbstractSeries) = OnlineStatsBase.nobs(s)

# empty
Series(t::Tuple)         = Series(default_weight(t), t)
Series(o::OnlineStat)    = Series(default_weight(o), o)
Series(o::OnlineStat...) = Series(default_weight(o), o)
Series(wt::Weight, o...) = Series(wt, o)  # leave out type annotation to avoid method confusion

# init with data
Series(y::AA, o::OnlineStat) = (s = Series(default_weight(o), o); fit!(s, y))
Series(y::AA, o::OnlineStat...) = (s = Series(default_weight(o), o); fit!(s, y))
Series(y::AA, wt::Weight, o::OnlineStat) = (s = Series(wt, o); fit!(s, y))
Series(y::AA, wt::Weight, o::OnlineStat...) = (s = Series(wt, o); fit!(s, y))
Series(wt::Weight, y::AA, o::OnlineStat) = (s = Series(wt, o); fit!(s, y))
Series(wt::Weight, y::AA, o::OnlineStat...) = (s = Series(wt, o); fit!(s, y))

# Special constructors for (1, 0) input
function Series(x::AbstractMatrix, y::AbstractVector, o::OnlineStat{(1,0)})
    s = Series(default_weight(o), o)
    fit!(s, x, y)
end
function Series(x::AbstractMatrix, y::AbstractVector, o::OnlineStat{(1,0)}...)
    s = Series(default_weight(o), o)
    fit!(s, x, y)
end
function Series(wt::Weight, x::AbstractMatrix, y::AbstractVector, o::OnlineStat{(1,0)})
    s = Series(wt, o)
    fit!(s, x, y)
end
function Series(x::AbstractMatrix, y::AbstractVector, wt::Weight, o::OnlineStat{(1,0)})
    s = Series(wt, o)
    fit!(s, x, y)
end

#--------------------------------------------------------------------------# Series methods
"Map `value` to the `stats` field of a Series."
value(s::Series) = map(value, s.stats)
value(s::Series, i) = value(s.stats[i])

"Return the `stats` field of a Series."
stats(s::Series) = s.stats

#--------------------------------------------------------------------------# fit!
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


# tuple version
function fit!(s::Series{1}, y::NTuple)
    γ = weight!(s)
    map(s -> fit!(s, y, γ), s.stats)
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


fit!{T <: Series}(s1::T, s2::T) = merge!(s1, s2)
