struct ModelSchema{D<:OrderedDict} <: OnlineStat{1}
    d::D
end
function ModelSchema(t::VectorOb, hints::Pair...)
    p = Pair.(keys(t), mlstat.(values(t)))
    d = OrderedDict{eltype(keys(t)), Any}(p...)
    for (ky, val) in hints
        val isa Union{Variance, CountMap, Ignored} ||
            error("Not an allowed ModelSchema stat")
        d[ky] = val
    end
    ModelSchema(d)
end
function Base.show(io::IO, o::ModelSchema)
    print(io, "ModelSchema: ")
    for (k, v) in pairs(sort(o.d))
        s = '-'
        if v isa Variance 
            s = '📈' 
        elseif v isa CountMap 
            s = '📊'
        end
        @printf io "\n  %s  | %s" k s
    end
end
function _fit!(o::ModelSchema, y)
    for i in keys(o.d)
        fit!(o.d[i], y[i])
    end
end



#-----------------------------------------------------------------------# Default stats
struct Ignored <: OnlineStat{0} end 
value(o::Ignored) = nothing
_fit!(o::Ignored, y) = nothing

mlstat(y) = Ignored()
mlstat(y::Number) = Variance() 
mlstat(y::T) where {T<:Union{Bool, AbstractString, Char, Symbol}} = CountMap(T)


_width(o::Variance) = 1 
_width(o::CountMap) = nkeys(o) - 1 
_width(o::Ignored) = 0


# module ML

# # import ..Variance
# # import ..Unique
# # import NamedTuples
# # import OnlineStatsBase: ExactStat, VectorOb
# # import LearnBase: fit!, value, transform
# # import DataStructures: SortedDict
# # export Numerical, Categorical

# # For interface: width, transform(column, y)
# abstract type AbstractMLColumn <: ExactStat{0} end

# fit!(o::AbstractMLColumn, y, γ::Number) = fit!(o.stat, y, γ)
# Base.merge!(o::AbstractMLColumn, o2::AbstractMLColumn, γ) = merge!(o.stat, o2.stat, γ)

# #-----------------------------------------------------------------------# Numerical
# """
#     Numerical()

# Track a numerical variable.  Can be used to standardize future observations.
# """
# struct Numerical <: AbstractMLColumn  
#     stat::Variance
# end
# Numerical() = Numerical(Variance())
# width(o::Numerical) = 1
# value(o::Numerical) = (mean(o.stat), std(o.stat))
# Base.show(io::IO, o::Numerical) = print(io, "📈 : $(round.(value(o), 4))")
# transform(o::Numerical, y) = (y - mean(o.stat)) / std(o.stat)

# #-----------------------------------------------------------------------# Categorical
# """
#     Categorical(T::Type)

# Track a categorical variable.  Can be used to create one-hot vectors of future observations.
# """
# struct Categorical{T} <: AbstractMLColumn
#     stat::Unique{T} 
# end
# Categorical(T::Type = Any) = Categorical(Unique(T))
# width(o::Categorical) = min(0, length(o.stat) - 1)
# value(o::Categorical) = value(o.stat)
# Base.show(io::IO, o::Categorical) = print(io, "📊 : $(value(o.stat))")
# function transform(o::Categorical, y)
#     for (k, ky) in enumerate(keys(o.stat.value))
#         y == ky && return k
#     end
#     return 0
# end

# #-----------------------------------------------------------------------# Ignored 
# struct Ignored <: AbstractMLColumn end
# width(o::Ignored) = 0
# value(o::Ignored) = nothing 
# fit!(o::Ignored, y, γ::Number) = o
# Base.show(io::IO, o::Ignored) = print(io, "Ignored")

# #-----------------------------------------------------------------------# Schema
# """
#     ML.Schema(spec)

# Track any combination of [`Numerical`](@ref) and [`Categorical`](@ref) features.  The `spec`
# should be an example collection (e.g. first row of data) or a collection of data types (schema).

# # Example 

#     ML.Schema([Float64, Bool, String])  # schema
    
#     series(randn(100, 3), ML.Schema(rand(3)))

#     using NamedTuples
#     ML.Schema(@NT(x=Float64, y=String))  # example row
# """
# mutable struct Schema{T <: Tuple} <: ExactStat{1}
#     colnames::Vector{Symbol}
#     features::T
#     nobs::Int
# end

# Schema(c::Vector{Symbol}, hints...) = Schema(c, make_feature.(hints), 0)
# Schema(hints::VectorOb) = Schema(colnames(hints), hints...)

# colnames(y::NamedTuples.NamedTuple) = keys(y)
# colnames(y::VectorOb) = [Symbol("x$i") for i in 1:length(y)]

# const StringLike = Union{AbstractString, Char, Symbol}
# make_feature(val) = Ignored() 
# make_feature(val::AbstractMLColumn) = val
# make_feature(val::Type{<:Number}) = Numerical() 
# make_feature(val::Type{T}) where {T<:StringLike} = Categorical(T)
# make_feature(val::Number) = Numerical()
# make_feature(val::T) where {T<:StringLike} = Categorical(T)


# Schema(s::String) = Schema(s, fill("a", length(s)))
# function Schema(s::String, y::VectorOb)
#     out = []
#     for (si, T) in zip(s, typeof.(y))
#         if si == 'n'
#             push!(out, Numerical())
#         elseif si == 'c'
#             push!(out, Categorical(T))
#         elseif si == '-'
#             push!(out, Ignored())
#         else
#             error("must be 'n' (Numerical), 'c' (Categorical), or '-' (Ignored)")
#         end
#     end
#     Schema(colnames(y), out...)
# end

# function Base.show(io::IO, o::Schema)
#     print(io, "Schema:")
#     d = maximum(length.(string.(o.colnames))) + 1
#     for (colname, feat) in zip(o.colnames, o.features)
#         print(io, "\n  > $colname: ")
#         for i in 1:(d - length(string(colname)))
#             print(io, " ")
#         end
#         print(io, feat)
#     end
# end


# width(o::Schema) = sum(width, o.features)

# function fit!(o::Schema, y::VectorOb, γ)
#     for (oi, yi) in zip(o.features, y)
#         fit!(oi, yi, γ)
#     end
# end



# end # module



