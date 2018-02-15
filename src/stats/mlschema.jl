"""
    MLFeature(Variance())
    MLFeature(Unique())

Track mean/std for continuous variables (`Variance`) or the unique values for categorical 
variables (`Unique`).
"""
struct MLFeature{T <: Union{Variance, Unique}}
    stat::T 
    hasmissing::Bool
end
MLFeature(stat::OnlineStat) = MLFeature(stat, false)

fit!(o::MLFeature, y, γ::Number) = fit!(o.stat, y, γ)

function Base.show(io::IO, o::MLFeature)
    print(io, description(o))
    o.hasmissing && print(io, " with missing.")
end

#-----------------------------------------------------------------------# continuous
width(o::MLFeature{Variance}) = 1 + o.hasmissing
description(o::MLFeature{Variance}) = "📈  | μ = $(mean(o.stat)), σ = $(std(o.stat))"
transform(o::MLFeature{Variance}, x) = (x .- mean(o.stat)) ./ std(o.stat)

#-----------------------------------------------------------------------# categorical
width(o::MLFeature{<:Unique}) = length(o.stat) + o.hasmissing - 1
description(o::MLFeature{<:Unique}) = "📊  | $(value(o.stat))"
transform(o::MLFeature{Unique{T}}, x::T) where {T} = [Float64(v == x) for v in unique(o.stat)]


#-----------------------------------------------------------------------# FeatureExtractor
"""
    FeatureExtractor(s::String) 
    FeatureExtractor(d::Dict)

Track the necessary values for standardizing continuous variables and/or generating one-hot 
vectors for categorical variables.  Allowed characters in the `String` method are:

- 'c': Continuous variable with missing values 
- 'C': Continuous variable 
- 'n': Nominal variable with missing values 
- 'N': Nominal variable

# Example

    o = FeatureExtractor("CCCC")
    series(randn(1000, 4), o)
"""
struct FeatureExtractor <: ExactStat{1}
    names::Vector{Symbol}
    schema::Vector{MLFeature}
end
function FeatureExtractor(s::String)
    names = Symbol[]
    schema = MLFeature[]
    for (i, si) in enumerate(s)
        sym = Symbol("x$i")
        push!(names, sym)
        if si == 'c'
            push!(schema, MLFeature(Variance(), true))
        elseif si == 'C'
            push!(schema, MLFeature(Variance()))
        elseif si == 'n'
            push!(schema, MLFeature(Unique(Any), true))
        elseif si == 'N'
            push!(schema, MLFeature(Unique(Any)))
        else 
            error("String must only contain 'c', 'C', 'n', or 'N'")
        end
    end
    FeatureExtractor(names, schema)
end
width(o::FeatureExtractor) = sum(width, o.schema)

function fit!(o::FeatureExtractor, y::VectorOb, γ::Number)
    for (si, yi) in zip(o.schema, y)
        fit!(si, yi, γ)
    end
end

function Base.show(io::IO, o::FeatureExtractor)
    println(io, "FeatureExtractor")
    for (ky, val) in zip(o.names, o.schema)
        println(io, "$ky: $val")
    end
end
