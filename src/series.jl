#--------------------------------------------------------------------# Series
mutable struct Series{STATS <: Tuple, W <: Weight} <: AbstractSeries
    weight::W
    stats::STATS
    nobs::Int
    nups::Int
end
Series(wt::Weight, args...) = Series(wt, args, 0, 0)
Series(args...; weight::Weight = EqualWeight()) = Series(weight, args, 0, 0)
function Base.show(io::IO, o::Series)
    printheader(io, "Series of $(typeof(o.weight))\n")
    for s in o.stats
        print_item(io, name(s), value(s))
    end
end

updatecounter!(o::Series, n2::Int = 1) = (o.nups += 1; o.nobs += n2)

function fit!(o::Series, y::Real, γ::Float64 = nextweight(o))
    updatecounter!(o)
    for stat in o.stats
        fit!(stat, y, γ)
    end
    o
end
function fit!(o::Series, y::AVec)
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
value(o::Mean) = o.μ

#--------------------------------------------------------------------# Variance
mutable struct Variance <: OnlineStat{ScalarInput}
    σ²::Float64
    μ::Float64
    Variance() = Variance(0.0, 0.0)
end
function fit!(o::Variance, y::Real, γ::Float64)
    μ = o.μ
    o.μ = smooth(o.μ, y, γ)
    o.σ² = smooth(o.σ², (y - o.μ) * (y - μ), γ)
end
value(o::Variance) = o.σ²

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
    OrderStatistics(p::Integer) = new(zeros(p), zeros(p), EqualWeight())
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
