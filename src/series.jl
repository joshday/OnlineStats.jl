struct Series{STATS <: Tuple, T}
    obs::STATS
    id::T
end
Series(args...; id = :unlabeled) = Series(args, id)
function Base.show(io::IO, o::Series)
    header(io, "Series(nstats = $(length(o.obs))): $(o.id)\n")
    for s in o.obs
        show(io, s)
        println(io)
    end
end
function fit!(o::Series, args...)
    for stat in o.obs
        fit!(stat, args...)
    end
    o
end

fit(o::OnlineStat{ScalarInput}, y::AVec) = Stats(y, o)
fit(o::OnlineStat{ScalarInput}, y::AVec, wt::Weight) = Stats(y, o; weight = wt)

#--------------------------------------------------------------------# Stats
mutable struct Stats{OS <: Tuple, W <: Weight} <: AbstractStats
    weight::W
    stats::OS
    nobs::Int
    nups::Int
end
Stats(wt::Weight, args...) = Stats(wt, args, 0, 0)
Stats(args...; weight::Weight = EqualWeight()) = Stats(weight, args, 0, 0)
function Stats(y::AVec, args...; weight::Weight = EqualWeight())
    o = Stats(weight, args...)
    fit!(o, y)
    o
end
function Base.show(io::IO, o::Stats)
    subheader(io, "Stats(nobs = $(nobs(o))) | ")
    print_with_color(:light_cyan, io, o.weight)
    println(io)
    n = length(o.stats)
    for i in 1:n
        s = o.stats[i]
        print_item(io, name(s), value(s), i != n)
    end
end
value(o::Stats) = o.stats

updatecounter!(o::Stats, n2::Int = 1) = (o.nups += 1; o.nobs += n2)

function fit!(o::Stats, y::Real, γ::Float64 = nextweight(o))
    updatecounter!(o)
    for stat in o.stats
        fit!(stat, y, γ)
    end
    o
end
function fit!(o::Stats, y::AVec)
    for yi in y
        fit!(o, yi)
    end
    o
end



#--------------------------------------------------------------------# Mean
mutable struct Mean <: OnlineStat{ScalarInput}
    μ::Float64
    Mean() = new(0.0)
end
fit!(o::Mean, y::Real, γ::Float64) = (o.μ = smooth(o.μ, y, γ))

#--------------------------------------------------------------------# Variance
mutable struct Variance <: OnlineStat{ScalarInput}
    σ²::Float64
    μ::Float64
    Variance() = new(0.0, 0.0)
end
function fit!(o::Variance, y::Real, γ::Float64)
    μ = o.μ
    o.μ = smooth(o.μ, y, γ)
    o.σ² = smooth(o.σ², (y - o.μ) * (y - μ), γ)
end

#--------------------------------------------------------------------# Extrema
mutable struct Extrema <: OnlineStat{ScalarInput}
    min::Float64
    max::Float64
    Extrema() = new(Inf, -Inf)
end
function fit!(o::Extrema, y::Real, γ::Float64)
    o.min = min(o.min, y)
    o.max = max(o.max, y)
    o
end
value(o::Extrema) = (o.min, o.max)

#--------------------------------------------------------------------# OrderStatistics
mutable struct OrderStatistics <: OnlineStat{ScalarInput}
    value::VecF
    buffer::VecF
    OrderStatistics(p::Integer) = new(zeros(p), zeros(p))
end
function fit!(o::OrderStatistics, y::Real, γ::Float64)
    p = length(o.value)
    buffer = o.buffer
    i = (nobs(o) % p) + 1
    @inbounds buffer[i] = y
    if i == p
        sort!(buffer)
        nreps = div(nobs(o), p - 1)
        smooth!(o.value, buffer, 1 / nreps)
    end
    o
end
showfields(o::OrderStatistics) = [:value]

#--------------------------------------------------------------------# Moments
type Moments <: OnlineStat{ScalarInput}
    m::VecF
    Moments() = new(zeros(4))
end
function fit!(o::Moments, y::Real, γ::Float64)
    @inbounds o.m[1] = smooth(o.m[1], y, γ)
    @inbounds o.m[2] = smooth(o.m[2], y * y, γ)
    @inbounds o.m[3] = smooth(o.m[3], y * y * y, γ)
    @inbounds o.m[4] = smooth(o.m[4], y * y * y * y, γ)
end
Base.mean(o::Moments) = value(o)[1]
Base.var(o::Moments) = (value(o)[2] - value(o)[1] ^ 2) * unbias(o)
Base.std(o::Moments) = sqrt.(var(o))
function StatsBase.skewness(o::Moments)
    v = value(o)
    (v[3] - 3.0 * v[1] * var(o) - v[1] ^ 3) / var(o) ^ 1.5
end
function StatsBase.kurtosis(o::Moments)
    v = value(o)
    (v[4] - 4.0 * v[1] * v[3] + 6.0 * v[1] ^ 2 * v[2] - 3.0 * v[1] ^ 4) / var(o) ^ 2 - 3.0
end

#--------------------------------------------------------------------# QuantileSGD
struct QuantileSGD <: OnlineStat{ScalarInput}
    value::VecF
    τ::VecF
    QuantileSGD(τ::VecF = [0.25, 0.5, 0.75]) = new(zeros(τ), τ)
    QuantileSGD(args...) = QuantileSGD(collect(args))
end
function fit!(o::QuantileSGD, y::Float64, γ::Float64)
    for i in eachindex(o.τ)
        @inbounds v = Float64(y < o.value[i]) - o.τ[i]
        @inbounds o.value[i] = subgrad(o.value[i], γ, v)
    end
end
function fitbatch!{T <: Real}(o::QuantileSGD, y::AVec{T}, γ::Float64)
    n2 = length(y)
    γ = γ / n2
    for yi in y
        for i in eachindex(o.τ)
            @inbounds v = Float64(yi < o.value[i]) - o.τ[i]
            @inbounds o.value[i] = subgrad(o.value[i], γ, v)
        end
    end
end

#--------------------------------------------------------------------# QuantileSGD
mutable struct QuantileMM <: OnlineStat{ScalarInput}
    value::VecF
    τ::VecF
    # "sufficient statistics"
    s::VecF
    t::VecF
    o::Float64
    QuantileMM(τ::VecF = [.25, .5, .75]) = new(zeros(τ), τ, zeros(τ), zeros(τ), 0.0)
end
showfields(o::QuantileMM) = [:value, :τ]
function fit!(o::QuantileMM, y::Real, γ::Float64)
    o.o = smooth(o.o, 1.0, γ)
    @inbounds for j in 1:length(o.τ)
        w::Float64 = 1.0 / (abs(y - o.value[j]) + _ϵ)
        o.s[j] = smooth(o.s[j], w * y, γ)
        o.t[j] = smooth(o.t[j], w, γ)
        o.value[j] = (o.s[j] + o.o * (2.0 * o.τ[j] - 1.0)) / o.t[j]
    end
end
function fitbatch!{T <: Real}(o::QuantileMM, y::AVec{T}, γ::Float64)
    n2 = length(y)
    γ = γ / n2
    o.o = smooth(o.o, 1.0, γ)
    @inbounds for yi in y
        for j in 1:length(o.τ)
            w::Float64 = 1.0 / abs(yi - o.value[j])
            o.s[j] = smooth(o.s[j], w * yi, γ)
            o.t[j] = smooth(o.t[j], w, γ)
        end
    end
    @inbounds for j in 1:length(o.τ)
        o.value[j] = (o.s[j] + o.o * (2.0 * o.τ[j] - 1.0)) / o.t[j]
    end
    o
end

#--------------------------------------------------------------------# Diff
type Diff{T <: Real} <: OnlineStat{ScalarInput}
    diff::T
    lastval::T
end
Diff() = Diff(0.0, 0.0)
Diff{T<:Real}(::Type{T}) = Diff(zero(T), zero(T))
Base.last(o::Diff) = o.lastval
Base.diff(o::Diff) = o.diff
function fit!{T<:AbstractFloat}(o::Diff{T}, x::Real, γ::Float64)
    v = convert(T, x)
    o.diff = v - last(o)
    o.lastval = v
end
function fit!{T<:Integer}(o::Diff{T}, x::Real, γ::Float64)
    v = round(T, x)
    o.diff = v - last(o)
    o.lastval = v
end

#--------------------------------------------------------------------# Sum
type Sum{T <: Real} <: OnlineStat{ScalarInput}
    sum::T
end
Sum() = Sum(0.0)
Sum{T<:Real}(::Type{T}) = Sum(zero(T), EqualWeight())
Base.sum(o::Sum) = o.sum
function fit!{T<:AbstractFloat}(o::Sum{T}, x::Real, γ::Float64)
    v = convert(T, x)
    o.sum += v
end
function fit!{T<:Integer}(o::Sum{T}, x::Real, γ::Float64)
    v = round(T, x)
    o.sum += v
end
