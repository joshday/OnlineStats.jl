module ML

import ..Variance
import ..Unique
import OnlineStatsBase: ExactStat, VectorOb
import LearnBase: fit!, value, transform
import NamedTuples: NamedTuple
import DataStructures: SortedDict
export Continuous, Discrete

abstract type AbstractMLColumn <: ExactStat{0} end
fit!(o::AbstractMLColumn, y, γ::Number) = fit!(o.stat, y, γ)
Base.merge!(o::AbstractMLColumn, o2::AbstractMLColumn, γ) = merge!(o.stat, o2.stat, γ)

#-----------------------------------------------------------------------# Continuous
struct Continuous <: AbstractMLColumn  
    stat::Variance
end
Continuous() = Continuous(Variance())
width(o::Continuous) = 1
value(o::Continuous) = (mean(o.stat), std(o.stat))
Base.show(io::IO, o::Continuous) = print(io, "Continuous: (μ, σ) = $(value(o))")

#-----------------------------------------------------------------------# Discrete
struct Discrete{T} <: AbstractMLColumn
    stat::Unique{T} 
end
Discrete(T::Type = Any) = Discrete(Unique(T))
width(o::Discrete) = min(0, length(o.stat) - 1)
value(o::Discrete) = value(o.stat)
Base.show(io::IO, o::Discrete) = print(io, "Discrete: $(value(o.stat))")

#-----------------------------------------------------------------------# Ignored 
struct Ignored <: AbstractMLColumn end
width(o::Ignored) = 0
value(o::Ignored) = nothing 
fit!(o::Ignored, y, γ::Number) = o
Base.show(io::IO, o::Ignored) = print(io, "Ignored")

#-----------------------------------------------------------------------# FeatureExtractor
mutable struct FeatureExtractor <: ExactStat{1}
    dict::SortedDict{Symbol, Any}
    nobs::Int
end
FeatureExtractor() = FeatureExtractor(SortedDict{Symbol, Any}(), 0)

function fit!(o::FeatureExtractor, y::VectorOb, γ::Number)
    o.nobs += 1
    if o.nobs == 1
        for (ky, val) in zip(colnames(y), values(y))
            o.dict[ky] = guess_feature(val)
        end
    else
        for (yi, oi) in zip(y, values(o.dict))
            @show oi, yi
            fit!(oi, yi, γ)
        end
    end
end

Base.sort(o::FeatureExtractor) = sort(o.dict)

guess_feature(val) = Ignored()
guess_feature(val::Number) = (o=Continuous(); fit!(o, val, 1.0); o)
guess_feature(val::T) where {T <: Union{AbstractString, Char, Symbol}} = (o=Discrete(T); fit!(o, val, 1.0); o)

colnames(y::NamedTuple) = keys(y)
colnames(y::VectorOb) = [Symbol("x$i") for i in 1:length(y)]

end # module
