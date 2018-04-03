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

function width(o::DataPreprocessor, lhs::Expr)
    out = 0 
    for ex in lhs.args[2:end]
        if ex isa Symbol 

        end
    end
end

# #-----------------------------------------------------------------------# Terms
# struct Interaction{V1, V2}
#     v1::V1
#     v2::V2
# end

# #-----------------------------------------------------------------------# FeatureMaker
# struct FeatureMaker{T, L, R, D<:DataPrerocessor} <: OnlineStat{VectorOb}
#     lhs::L
#     rhs::R
#     processor::D
#     x::Vector{T}
# end
# function FeatureMaker(lhs::L, rhs::R, processor::D; outtype=Float64) where {L,R,D}
#     FeatureMaker(lhs, rhs, processor, zeros(T, width(processor, rhs)))
# end



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
