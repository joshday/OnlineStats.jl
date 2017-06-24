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
struct Series{I, OS <: Union{Tuple, OnlineStat{I}}, W <: Weight}
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

#--------------------------------------------------------------------------# Series methods
# Need the following so certain things work for both an OnlineStat and tuple of OnlineStats
Base.start(o::OnlineStat) = false
Base.next(o::OnlineStat, state) = o, true
Base.done(o::OnlineStat, state) = state
Base.map(f::Function, o::OnlineStat) = f(o)
Base.length(o::OnlineStat) = 1

"Map `value` to the `stats` field of a Series."
value(s::Series) = map(value, s.stats)
value(s::Series, i::Integer) = value(s.stats[i])


"Return the `stats` field of a Series."
stats(s::Series) = s.stats
stats(s::Series, i::Integer) = s.stats[i]

# helpers for weight
nobs(o::Series) = nobs(o.weight)
nups(o::Series) = nups(o.weight)
weight(o::Series, n2::Int = 1) = weight(o.weight, n2)
weight!(o::Series, n2::Int = 1) = weight!(o.weight, n2)
updatecounter!(o::Series, n2::Int = 1) = updatecounter!(o.weight, n2)

Base.copy(o::Series) = deepcopy(o)

#--------------------------------------------------------------------------# Show
function Base.show{I, OS<:Tuple, W}(io::IO, s::Series{I, OS, W})
    header(io, name(s))
    println(io)
    print(io, "┣━━ ")
    println(io, s.weight)
    println(io, "┗━━ Tracking")
    names = name.(s.stats)
    indent = maximum(length.(names))
    n = length(names)
    i = 0
    for o in s.stats
        i += 1
        char = ifelse(i == n, "┗━━", "┣━━")
        print(io, "    $char ")
        print(io, names[i])
        print(io, repeat(" ", indent - length(names[i])))
        print(io, " : $(value(o))")
        i == n || println(io)
    end
end
function Base.show{I, O <: OnlineStat, W}(io::IO, s::Series{I, O, W})
    header(io, name(s))
    println(io)
    print(io, "┣━━ ")
    println(io, s.weight)
    print(io, "┗━━ $(name(s.stats)) : $(value(s.stats))")
end



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


#--------------------------------------------------------------------------# merge!
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

fit!{T <: Series}(s1::T, s2::T) = merge!(s1, s2)
