

#-------------------------------------------------------------------------# Variances
"""
Variances of a multiple series, similar to `var(x, 1)`.

```julia
o = Variances(x, EqualWeight())
o = Variances(x)
fit!(o, x2)

mean(o)
var(o)
std(o)
```
"""
type Variances{W <: Weight} <: OnlineStat{VectorInput}
    value::VecF
    μ::VecF
    μold::VecF  # avoid allocation in update
    weight::W
end
function Variances(p::Integer, wgt::Weight = EqualWeight())
    Variances(zeros(p), zeros(p), zeros(p), wgt)
end
function _fit!(o::Variances, y::AVec, γ::Float64)
    copy!(o.μold, o.μ)
    smooth!(o.μ, y, γ)
    for i in eachindex(y)
        o.value[i] = smooth(o.value[i], (y[i] - o.μ[i]) * (y[i] - o.μold[i]), γ)
    end
end
Base.var(o::Variances) = value(o)
Base.std(o::Variances) = sqrt.(value(o))
Base.mean(o::Variances) = o.μ
value(o::Variances) = nobs(o) < 2 ? zeros(o.value) : o.value * unbias(o)
center{T<:Real}(o::Variances, x::AVec{T}) = x - mean(o)
function StatsBase.zscore{T<:Real}(o::Variances, x::AVec{T})
    σs = std(o)
    for j in eachindex(σs)
        @inbounds if σs[j] == 0.0
            σs[j] = 1.0
        end
    end
    center(o, x) ./ σs
end
function StatsBase.zscore{T<:Real}(o::Variances, x::AMat{T})
    σs = std(o)
    for j in eachindex(σs)
        if σs[j] == 0.0
            σs[j] = 1.0
        end
    end
    StatsBase.zscore(x, mean(o)', σs')
end
function _merge!(o::Variances, o2::Variances, γ::Float64)
    δ = mean(o2) - mean(o)
    for i in eachindex(o.value)
        o.value[i] = smooth(o.value[i], o2.value[i], γ) + δ[i] ^ 2 * γ * (1.0 - γ)
        o.μ[i] = smooth(o.μ[i], o2.μ[i], γ)
    end
end





#---------------------------------------------------------------------------# Extremas
"""
Extremas (maximum and minimum) of multiple series.

```julia
x = rand(1000,5)
o = Extremas(5)
fit!(o, x)
extrema(o)
```
"""
type Extremas <: OnlineStat{VectorInput}
    min::VecF
    max::VecF
    weight::EqualWeight
    Extremas(p::Int) = new(zeros(p)+Inf, zeros(p)-Inf, EqualWeight())
    Extremas{T<:Real}(y::AMat{T}) = new(squeeze(minimum(y,1),1), squeeze(maximum(y,1),1),
                                        EqualWeight(size(y,1)))
end
function _fit!(o::Extremas, y::AVec, γ::Float64)
    for i in 1:length(y)
        o.min[i] = min(o.min[i], y[i])
        o.max[i] = max(o.max[i], y[i])
    end
    o
end
Base.extrema(o::Extremas) = [(min,max) for (min,max) in zip(o.min,o.max)]
Base.minimum(o::Extremas) = o.min
Base.maximum(o::Extremas) = o.max
value(o::Extremas) = extrema(o)
function _merge!(o::Extremas, o2::Extremas, γ::Float64)
    @assert length(o.min)==length(o2.min)
    for i in 1:length(o.min)
        o.min[i] = min(o.min[i], o2.min[i])
        o.max[i] = max(o.max[i], o2.max[i])
    end
end





#------------------------------------------------------------------------# Diffs
"""
Track the last value and the last difference for multiple series.  Ignores `Weight`.

```julia
o = Diffs()
o = Diffs(y)
```
"""
type Diffs{T <: Real} <: OnlineStat{VectorInput}
    diffs::Vector{T}
    lastvals::Vector{T}
    weight::EqualWeight
end
Diffs(p::Integer) = Diffs(zeros(p), zeros(p), EqualWeight())
Diffs{T<:Real}(::Type{T}, p::Integer) = Diffs(zeros(T,p), zeros(T,p), EqualWeight())
Diffs{T<:Real}(x::AMat{T}) = (o = Diffs(T,ncols(x)); fit!(o, x); o)

value(o::Diffs) = o.diffs
Base.last(o::Diffs) = o.lastvals
Base.diff(o::Diffs) = o.diffs
function _fit!{T<:Real}(o::Diffs{T}, x::AVec{T}, γ::Float64)
    o.diffs = (nobs(o) == 0 ? zeros(T,length(o.diffs)) : x - last(o))
    o.lastvals = collect(x)
    o
end



"""
Track the running sum for multiple series.  Ignores `Weight`.

```julia
o = Sums()
o = Sums(y)
```
"""
type Sums{T <: Real} <: OnlineStat{VectorInput}
    sums::Vector{T}
    weight::EqualWeight
end
Sums(p::Integer) = Sums(zeros(p), EqualWeight())
Sums{T<:Real}(::Type{T}, p::Integer) = Sums(zeros(T,p), EqualWeight())
Sums{T<:Real}(x::AMat{T}) = (o = Sums(T, ncols(x)); fit!(o, x); o)

value(o::Sums) = o.sums
Base.sum(o::Sums) = o.sums
function _fit!{T<:Real}(o::Sums{T}, x::AVec{T}, γ::Float64)
    for i in eachindex(x)
        o.sums[i] += x[i]
    end
end
