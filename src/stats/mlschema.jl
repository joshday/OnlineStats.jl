"""
    ML.FeatureExtractor()

Type for extracting feature vectors from continuous and discrete variables.  Under the hood,
each variable is tracked by one of the following:

- `ML.Numerical()`
- `ML.Categorical()`
- `ML.Ignored()`

# Example 

    o = ML.FeatureExtractor()
    x = [randn(100) rand('a':'d', 100) rand(Date(2010):Date(2011), 100)]
    series(x, o)
    o.dict
"""
module ML

import ..Variance
import ..Unique
import OnlineStatsBase: ExactStat, VectorOb
import LearnBase: fit!, value, transform
import NamedTuples: NamedTuple
import DataStructures: SortedDict
export Numerical, Categorical

abstract type AbstractMLColumn <: ExactStat{0} end
fit!(o::AbstractMLColumn, y, γ::Number) = fit!(o.stat, y, γ)
Base.merge!(o::AbstractMLColumn, o2::AbstractMLColumn, γ) = merge!(o.stat, o2.stat, γ)

#-----------------------------------------------------------------------# Numerical
struct Numerical <: AbstractMLColumn  
    stat::Variance
end
Numerical() = Numerical(Variance())
width(o::Numerical) = 1
value(o::Numerical) = (mean(o.stat), std(o.stat))
Base.show(io::IO, o::Numerical) = print(io, "📈: $(round.(value(o), 4))")

#-----------------------------------------------------------------------# Categorical
struct Categorical{T} <: AbstractMLColumn
    stat::Unique{T} 
end
Categorical(T::Type = Any) = Categorical(Unique(T))
width(o::Categorical) = min(0, length(o.stat) - 1)
value(o::Categorical) = value(o.stat)
Base.show(io::IO, o::Categorical) = print(io, "📊: $(value(o.stat))")

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

function Base.show(io::IO, o::FeatureExtractor)
    print(io, "FeatureExtractor:")
    for di in o.dict 
        println(io)
        print(io, di)
    end

end

function fit!(o::FeatureExtractor, y::VectorOb, γ::Number)
    o.nobs += 1
    if o.nobs == 1
        for (ky, val) in zip(colnames(y), values(y))
            o.dict[ky] = guess_feature(val)
        end
    else
        for (yi, oi) in zip(y, values(o.dict))
            fit!(oi, yi, γ)
        end
    end
end

Base.sort(o::FeatureExtractor) = sort(o.dict)

const StringLike = Union{AbstractString, Char, Symbol}
guess_feature(val) = Ignored()
guess_feature(val::Number) = (o = Numerical(); fit!(o, val, 1.0); o)
guess_feature(val::T) where {T <: StringLike} = (o=Categorical(T); fit!(o, val, 1.0); o)

colnames(y::NamedTuple) = keys(y)
colnames(y::VectorOb) = [Symbol("x$i") for i in 1:length(y)]

end # module
