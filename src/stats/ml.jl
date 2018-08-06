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
Statistics.mean(o::Numerical) = mean(o.stat)
Statistics.std(o::Numerical) = std(o.stat)
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

function preprocess(itr, hints::Pair...; kw...) 
    row = first(itr)
    p = Pair.(_keys(row), make_modeling_type.(values(row)))
    d = OrderedDict{Any, Any}(p...)
    for (k,v) in hints 
        d[k] = v
    end
    g = fit!(Group(collect(values(d))...), itr)
    DataPreprocessor(g; kw...)
end
_keys(o) = keys(o)
_keys(o::Tuple) = 1:length(o)

# function width(o::DataPreprocessor, lhs::Expr)
#     out = 0 
#     for ex in lhs.args[2:end]
#         if ex isa Symbol 

#         end
#     end
# end

# #-----------------------------------------------------------------------# Terms
# abstract type ModelTerm end

# struct SingleTerm{T <: ModelingType} <: ModelTerm
#     a::T 
# end

# struct Interaction{A<:ModelingType, B <: ModelingType} <: ModelTerm
#     a::A
#     b::B
# end
# Interaction(a::Numerical, b::Categorical) = Interaction(b, a)

# #-----------------------------------------------------------------------# Formula 
# struct ModelFormula{L,R,D<:DataPreprocessor}
#     lhs 
#     rhs::Vector{ModelTerm}
# end
