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
description(o::MLFeature{Variance}) = "📈 | μ = $(mean(o.stat)), σ = $(std(o.stat))"
transform(o::MLFeature{Variance}, x) = (x .- mean(o.stat)) ./ std(o.stat)

#-----------------------------------------------------------------------# categorical
width(o::MLFeature{<:Unique}) = length(o.stat) + o.hasmissing - 1
description(o::MLFeature{<:Unique}) = "📊 | $(value(o.stat))"
transform(o::MLFeature{Unique{T}}, x::T) where {T} = [Float64(v == x) for v in unique(o.stat)]



#-----------------------------------------------------------------------# MLSchema 
struct MLSchema <: ExactStat{1}
    ykey::Symbol
    schema::Dict{Symbol, MLFeature}
end
function MLSchema(s::String, )
    d = Dict{Symbol, MLFeature}()
    for si in s 
    end
end
function Base.show(io::IO, o::MLSchema)
    println(io, "MLSchema: ")
    println(io, "  > y: ", o.ykey)
    print(io, o.schema)
end
