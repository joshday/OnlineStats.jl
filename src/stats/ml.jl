# #-----------------------------------------------------------------------# DataPreprocessor
# mutable struct Ignored <: OnlineStat{0} 
#     n::Int
# end 
# Ignored() = Ignored(0)
# value(o::Ignored) = nothing
# _fit!(o::Ignored, y) = (o.n += 1)

# """
#     DataPreprocessor(group)
#     OnlineStats.preprocess(itr, hints::Pair...)

# An object for standardizing continuous variables and creating one-hot vectors of 
# categorical variables.

# # Example

#     gp = OnlineStats.preprocess(zip(randn(1000), rand('a':'f', 1000)))
#     transform!(gp, [1.0, 'a'])
# """
# struct DataPreprocessor{G} <: OnlineStat{VectorOb}
#     group::G 
#     x::Vector{Float64}
# end
# DataPreprocessor(g::Group) = DataPreprocessor(g, zeros(sum(_width, g.stats)))
# nobs(o::DataPreprocessor) = nobs(o.group)

# function Base.show(io::IO, o::DataPreprocessor)
#     print(io, "DataPreprocessor:")
#     for (i, stat) in enumerate(o.group.stats)
#         char = i == length(o.group.stats) ? '└' : '├'
#         s = ""
#         if stat isa Variance 
#             s = "📈 | μ = $(mean(stat)), σ = $(std(stat))"
#         elseif stat isa CountMap 
#             s = "📊 | ncategories = $(nkeys(stat))"
#         else
#             s = "-"
#         end
#         print(io, "\n  $(char)── $s")
#     end
# end

# function transform!(o::DataPreprocessor, x::VectorOb)
#     i = 0
#     for (xi, stat) in zip(x, o.group.stats)
#         for j in 1:_width(stat)
#             i += 1 
#             o.x[i] = transform(stat, xi, j)
#         end
#     end
#     o.x
# end

# function transform(o::DataPreprocessor, x::AbstractMatrix)
#     out = zeros(size(x, 1), _width(o))
#     for (i, row) in enumerate(eachrow(x))
#         transform!(o, row)
#         for j in 1:size(out, 2)
#             out[i, j] = o.x[j]
#         end
#     end
#     out
# end

# function preprocess(itr, hints::Pair...) 
#     row = first(itr)
#     p = Pair.(_keys(row), mlstat.(values(row)))
#     d = OrderedDict{Any, Any}(p...)
#     for (k,v) in hints 
#         d[k] = v
#     end
#     g = fit!(Group(collect(values(d))...), itr)
#     DataPreprocessor(g)
# end

# _keys(o) = keys(o)
# _keys(o::Tuple) = 1:length(o)

# transform(o::Variance, xi, j) = (xi - mean(o)) / std(o)
# function transform(o::CountMap, xi, j) 
#     for (i,k) in enumerate(keys(o))
#         i == j && return xi == k ? 1.0 : 0.0
#     end
# end

# mlstat(y) = Ignored()
# mlstat(y::Number) = Variance() 
# mlstat(y::T) where {T<:Union{Bool, AbstractString, Char, Symbol}} = CountMap(T)

# _width(o::DataPreprocessor) = sum(_width, o.group.stats)
# _width(o::Variance) = 1 
# _width(o::CountMap) = nkeys(o) - 1 
# _width(o::Ignored) = 0



#-----------------------------------------------------------------------# Formula 
# Borrowed from StatsModels
mutable struct Formula
    lhs::Union{Symbol, Expr, Void}
    rhs::Union{Symbol, Expr, Integer}
end

macro formula(ex)
    if (ex.head === :macrocall && ex.args[1] === Symbol("@~")) || (ex.head === :call && ex.args[1] === :(~))
        length(ex.args) == 3 || error("malformed expression in formula")
        lhs = Base.Meta.quot(ex.args[2])
        rhs = Base.Meta.quot(ex.args[3])
    else
        return :(error($("expected formula separator ~, got $(ex.head)")))
    end
    return Expr(:call, :Formula, lhs, rhs)
end

#-----------------------------------------------------------------------# ModelingType
abstract type ModelingType{T} <: OnlineStat{T} end
nobs(o::ModelingType) = nobs(o.stat)
_fit!(o::ModelingType, y) = _fit!(o.stat, y)

#### Numerical
struct Numerical <: ModelingType{Number}
    stat::Variance 
end 
Numerical() = Numerical(Variance())
function Base.show(io::IO, o::Numerical)
    print(io, "📈  Numerical: μ=", mean(o), ", σ=", std(o))
end
Base.mean(o::Numerical) = mean(o.stat)
Base.std(o::Numerical) = std(o.stat)
width(o::Numerical) = 1
transform(o::Numerical, xi, j) = (xi - mean(o)) / std(o)

#### Categorical
struct Categorical{T} <: ModelingType{T}
    stat::CountMap{T, OrderedDict{T, Int}}
end
Categorical(T) = Categorical(CountMap(T))
function Base.show(io::IO, o::Categorical{T}) where {T}
    print(io, "📊  Categorical{$T}: nclasses = ", length(o.stat.value))
end
width(o::Categorical) = max(0, length(o.stat.value) - 1)
function transform(o::Categorical, xi, j)
    out = 0 
    for (k, ky) in enumerate(keys(o))
        j == k && xi == ky && (out = 1) 
    end
    out
end

#-----------------------------------------------------------------------# DataPreprocessor 
# S = standardize?
# G = Group of Numerical/Categorical
struct DataPreprocessor{S, G} <: OnlineStat{VectorOb}
    group::G 
    x::Vector{Float64}
end
function DataPreprocessor(g::Group; standardize::Bool=true) 
    DataPreprocessor{standardize, typeof(g)}(g, zeros(sum(width, g.stats)))
end
function DataPreprocessor(row; kw...)
    stats = []
    for item in row
        push!(stats, make_modeling_type(item))
    end
    DataPreprocessor(Group(stats...); kw...)
end
nobs(o::DataPreprocessor) = nobs(o.group)
Base.show(io::IO, o::DataPreprocessor) = print(io, "DataPreprocessor:\n", o.group)

make_modeling_type(x::Number) = Numerical()
make_modeling_type(x::T) where {T<:Union{AbstractString, Bool, Char}} = Categorical(T)

_fit!(o::DataPreprocessor, y) = _fit!(o.group, y)

preprocess(itr) = fit!(DataPreprocessor(first(itr)), itr)

# @generated function transform!(o::DataPre)
# @generated function _fit!(o::DataPreprocessor{S, G}, y) where {S, G}
#     N = length(fieldnames(T))
#     :(Base.Cartesian.@nexprs $N i -> @inbounds(_fit!(o.stats[i], y[i])))
# end

# @generated function transform!(o::DataPreprocessor{true, Group{T}}, x::VectorOb) where {T}
#     N = fieldcount(T)
#     println(N)
#     quote 
#         Base.Cartesian.@nexprs $N i -> updatex!(o, i, x[i])
#     end
# end

# function update_x!(o::DataPreprocessor, i, xi)
#     ind = s
# end



# function transform!(o::DataPreprocessor{true}, x::VectorOb)
#     i = 0
#     for (xi, stat) in zip(x, o.group.stats)
#         for j in 1:_width(stat)
#             i += 1 
#             o.x[i] = transform(stat, xi, j)
#         end
#     end
#     o.x
# end
