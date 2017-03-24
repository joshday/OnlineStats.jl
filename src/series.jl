struct Series{STATS <: Tuple, T}
    obs::STATS
    id::T
end
Series(args...; id = :x) = Series(args, id)
function Base.show(io::IO, o::Series)
    printheader(io, "Series: $(o.id) ($(length(o.obs)))\n")
    for s in o.obs
        show(io, s)
    end
end

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
    printheader(io, "Stats with ")
    print_with_color(:light_cyan, io, o.weight)
    println(io)
    for s in o.stats
        print_item(io, name(s), value(s))
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
