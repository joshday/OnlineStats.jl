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

    s = Series(QuantileMM([.25, .5, .75]))
    fit!(s, randn(1000))
"""
mutable struct Series{N, T <: Tuple, W}
    stats::T
    weight::W
    n::Int
end
function Series(w::Weight, o::OnlineStat{N}...) where {N} 
    Series{N, typeof(o), typeof(w)}(o, w, 0)
end
Series(o::OnlineStat{N}...) where {N} = Series(default_weight(o), o...)

# init with data
Series(y::Data, o::OnlineStat{N}...) where {N} = (s = Series(o...); fit!(s, y))
function Series(y::Data, wt::Weight, o::OnlineStat{N}...) where {N}
    s = Series(wt, o...)
    fit!(s, y)
end
Series(wt::Weight, y::Data, o::OnlineStat{N}...) where {N} = Series(y, wt, o...)


#-----------------------------------------------------------------------# methods
header(io::IO, s::AbstractString) = println(io, "▦ $s" )

function header(io::IO, s::Series{N}) where {N} 
    println(io, "▦ Series{$N} with $(s.weight)")
    print(io, "  ├── ", "nobs = $(s.n)")
end

function Base.show(io::IO, s::Series)
    header(io, s)
    # print(io, "├──── "); println(io, "$(s.weight), nobs = $(nobs(s))")
    # print(io, "└─┐")
    n = length(stats(s))
    i = 0
    for o in stats(s)
        i += 1
        char = ifelse(i == n, "└──", "├──")
        # char = '>'
        print(io, "\n  $char $o")
        # print(io, "\n  $char $(name(o)): $(round.(value(o), 4))")
    end
end
Base.showcompact(io::IO, s::Series) = (header(io,s); print(io, s.stats))

"""
    stats(s::Series)

Return a tuple of the OnlineStats contained in the Series.

# Example

    s = Series(randn(100), Mean(), Variance())
    m, v = stats(s)
"""
stats(s::Series) = s.stats

"""
    value(s::Series)

Return a tuple of `value` mapped to the OnlineStats contained in the Series.
"""
value(s::Series) = value.(stats(s))

"""
    nobs(s::Series)

Return the number of observations the Series has `fit!`-ted.
"""
nobs(s::Series) = s.n

weight(s::Series, n2::Int = 1) = s.weight(s.n, n2)
weight!(s::Series, n2::Int = 1) = (s.n += n2; weight(s, n2))

function Base.:(==)(o1::Series, o2::Series)
    typeof(o1) == typeof(o2) || return false
    nms = fieldnames(o1)
    all(getfield.(o1, nms) .== getfield.(o2, nms))
end
Base.copy(w::Series) = deepcopy(w)

#-----------------------------------------------------------------------# fit! 0
"""
    fit!(s::Series, data, args...)

Update a Series with more `data`.  Additional arguments can be used to 

- override the weight
- use the columns of a matrix as observations (default is rows)

# Examples

    # Univariate Series 
    s = Series(Mean())
    fit!(s, randn(100))

    # Multivariate Series
    x = randn(100, 3)
    s = Series(CovMatrix(3))
    fit!(s, x)  # Same as fit!(s, x, Rows())
    fit!(s, x', Cols())

    # overriding the weight
    fit!(s, x, .1)  # use .1 for every observation's weight
    w = rand(100)
    fit!(s, x, w)  # use w[i] as the weight for observation x[i, :]

    # Model Series
    x, y = randn(100, 10), randn(100)
    s = Series(LinReg(10))
    fit!(s, (x, y))
"""
function fit!(s::Series{0}, y::ScalarOb)
    γ = weight!(s)
    map(x -> fit!(x, y, γ), stats(s))
    s
end
function fit!(s::Series{0}, y::ScalarOb, γ::Float64)
    s.n += 1
    map(x -> fit!(x, y, γ), stats(s))
    s
end
function fit!(s::Series{0}, y::AbstractArray)
    for yi in y 
        fit!(s, yi)
    end
    s
end
function fit!(s::Series{0}, y::AbstractArray, γ::Float64)
    for yi in y 
        fit!(s, yi, γ)
    end
    s
end
function fit!(s::Series{0}, y::AbstractArray, γ::Vector{Float64})
    for (yi, γi) in zip(y, γ) 
        fit!(s, yi, γi)
    end
    s
end
#-----------------------------------------------------------------------# fit! 1 
function fit!(s::Series{1}, y::VectorOb)
    s.n += 1
    γ = s.weight(s.n)
    map(x -> fit!(x, y, γ), stats(s))
    s
end
function fit!(s::Series{1}, y::VectorOb, γ::Float64)
    s.n += 1
    map(x -> fit!(x, y, γ), stats(s))
    s
end
function fit!(s::Series{1}, y::AbstractMatrix, ::Rows = Rows())
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
function fit!(s::Series{1}, y::AbstractMatrix, γ::Float64, ::Rows = Rows())
    n, p = size(y)
    buffer = Vector{eltype(y)}(p)
    for i in 1:n
        for j in 1:p
            @inbounds buffer[j] = y[i, j]
        end
        fit!(s, buffer, γ)
    end
    s
end
function fit!(s::Series{1}, y::AbstractMatrix, γ::Vector{Float64}, ::Rows = Rows())
    n, p = size(y)
    n == length(γ) || error("Weight vector has length $(length(γ)) instead of $n")
    buffer = Vector{eltype(y)}(p)
    for i in 1:n
        for j in 1:p
            @inbounds buffer[j] = y[i, j]
        end
        @inbounds fit!(s, buffer, γ[i])
    end
    s
end
function fit!(s::Series{1}, y::AbstractMatrix, ::Cols)
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
function fit!(s::Series{1}, y::AbstractMatrix, γ::Float64, ::Cols)
    p, n = size(y)
    buffer = Vector{eltype(y)}(p)
    for i in 1:n
        for j in 1:p
            @inbounds buffer[j] = y[j, i]
        end
        fit!(s, buffer, γ)
    end
    s
end
function fit!(s::Series{1}, y::AbstractMatrix, γ::Vector{Float64}, ::Cols)
    p, n = size(y)
    n == length(γ) || error("Weight vector has length $(length(γ)) instead of $n")
    buffer = Vector{eltype(y)}(p)
    for i in 1:n
        for j in 1:p
            @inbounds buffer[j] = y[j, i]
        end
        @inbounds fit!(s, buffer, γ[i])
    end
    s
end

#-----------------------------------------------------------------------# fit! (1, 0)
fit!(o::OnlineStat{(1,0)}, xy::Tuple{VectorOb, ScalarOb}, γ::Float64) = fit!(o, xy[1], xy[2], γ)

function fit!(s::Series{(1,0)}, xy::Tuple{<:VectorOb, <:ScalarOb})
    γ = weight!(s)
    map(x -> fit!(x, xy[1], xy[2], γ), stats(s))
    s
end
function fit!(s::Series{(1,0)}, xy::Tuple{<:VectorOb, <:ScalarOb}, γ::Float64)
    s.n += 1
    map(x -> fit!(x, xy[1], xy[2], γ), stats(s))
    s
end
function fit!(s::Series{(1,0)}, xy::Tuple{<:AbstractMatrix, <:VectorOb}, ::Rows = Rows())
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
function fit!(s::Series{(1,0)}, xy::Tuple{<:AbstractMatrix, <:VectorOb}, ::Cols)
    x, y = xy
    p, n = size(x)
    buffer = Vector{eltype(x)}(p)
    for i in 1:n 
        for j in 1:p 
            buffer[j] = x[j, i]
        end
        fit!(s, (buffer, y[i]))
    end
    s
end
function fit!(s::Series{(1,0)}, xy::Tuple{<:AbstractMatrix, <:VectorOb}, γ::Float64, ::Rows = Rows())
    x, y = xy
    n, p = size(x)
    buffer = Vector{eltype(x)}(p)
    for i in 1:n 
        for j in 1:p 
            buffer[j] = x[i, j]
        end
        fit!(s, (buffer, y[i]), γ)
    end
    s
end
function fit!(s::Series{(1,0)}, xy::Tuple{<:AbstractMatrix, <:VectorOb}, γ::Float64, ::Cols)
    x, y = xy
    p, n = size(x)
    buffer = Vector{eltype(x)}(p)
    for i in 1:n 
        for j in 1:p 
            buffer[j] = x[j, i]
        end
        fit!(s, (buffer, y[i]), γ)
    end
    s
end
function fit!(s::Series{(1,0)}, xy::Tuple{<:AbstractMatrix, <:VectorOb}, γ::AVecF, ::Rows = Rows())
    x, y = xy
    length(y) == length(γ) || error("Weight vector is incorrect length.")
    n, p = size(x)
    buffer = Vector{eltype(x)}(p)
    for i in 1:n 
        for j in 1:p 
            buffer[j] = x[i, j]
        end
        fit!(s, (buffer, y[i]), γ[i])
    end
    s
end
function fit!(s::Series{(1,0)}, xy::Tuple{<:AbstractMatrix, <:VectorOb}, γ::AVecF, ::Cols)
    x, y = xy
    length(y) == length(γ) || error("Weight vector is incorrect length.")
    p, n = size(x)
    buffer = Vector{eltype(x)}(p)
    for i in 1:n 
        for j in 1:p 
            buffer[j] = x[j, i]
        end
        fit!(s, (buffer, y[i]), γ[i])
    end
    s
end


#-----------------------------------------------------------------------# merging
"See [`merge!`](@ref)"
Base.merge(s1::T, s2::T, w::Float64) where {T <: Series} = merge!(copy(s1), s2, w)

function Base.merge(s1::T, s2::T, method::Symbol = :append) where {T <: Series}
    merge!(copy(s1), s2, method)
end

"""
    merge!(s1::Series, s2::Series, arg)

Merge `s2` into `s1` in place where `s2`'s influence is determined by `arg`. Options for
`arg`` are:

- `:append` (default)
    - append `s2` to `s1`.  Essentially `fit!(s1, data_which_s2_saw)`.
- `:mean`
    - Use the average of the Series' generated weights.
- `:singleton`
    - treat `s2` as a single observation.
- any `Float64` in [0, 1]
"""
function Base.merge!(s1::T, s2::T, method::Symbol = :append) where {T <: Series}
    n2 = nobs(s2)
    n2 == 0 && return s1
    s1.n += n2
    if method == :append
        merge!.(s1.stats, s2.stats, weight(s1, n2))
    elseif method == :mean
        merge!.(s1.stats, s2.stats, n2 / s1.n)
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
