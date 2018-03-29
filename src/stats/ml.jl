#-----------------------------------------------------------------------# DataPreprocessor
mutable struct Ignored <: OnlineStat{0} 
    n::Int
end 
Ignored() = Ignored(0)
value(o::Ignored) = nothing
_fit!(o::Ignored, y) = (o.n += 1)

"""
    DataPreprocessor(group)
    OnlineStats.preprocess(itr, hints::Pair...)

An object for standardizing continuous variables and creating one-hot vectors of 
categorical variables.

# Example

    gp = OnlineStats.preprocess(zip(randn(1000), rand('a':'f', 1000)))
    transform!(gp, [1.0, 'a'])
"""
struct DataPreprocessor{G} <: OnlineStat{VectorOb}
    group::G 
    x::Vector{Float64}
end
DataPreprocessor(g::Group) = DataPreprocessor(g, zeros(sum(_width, g.stats)))
nobs(o::DataPreprocessor) = nobs(o.group)

function Base.show(io::IO, o::DataPreprocessor)
    print(io, "DataPreprocessor:")
    for (i, stat) in enumerate(o.group.stats)
        char = i == length(o.group.stats) ? '└' : '├'
        s = ""
        if stat isa Variance 
            s = "📈 | μ = $(mean(stat)), σ = $(std(stat))"
        elseif stat isa CountMap 
            s = "📊 | ncategories = $(nkeys(stat))"
        else
            s = "-"
        end
        print(io, "\n  $(char)── $s")
    end
end

function transform!(o::DataPreprocessor, x::VectorOb)
    i = 0
    for (xi, stat) in zip(x, o.group.stats)
        for j in 1:_width(stat)
            i += 1 
            o.x[i] = transform(stat, xi, j)
        end
    end
    o.x
end

function transform(o::DataPreprocessor, x::AbstractMatrix)
    out = zeros(size(x, 1), _width(o))
    for (i, row) in enumerate(eachrow(x))
        transform!(o, row)
        for j in 1:size(out, 2)
            out[i, j] = o.x[j]
        end
    end
    out
end

function preprocess(itr, hints::Pair...) 
    row = first(itr)
    p = Pair.(_keys(row), mlstat.(values(row)))
    d = OrderedDict{Any, Any}(p...)
    for (k,v) in hints 
        d[k] = v
    end
    g = fit!(Group(collect(values(d))...), itr)
    DataPreprocessor(g)
end

_keys(o) = keys(o)
_keys(o::Tuple) = 1:length(o)

transform(o::Variance, xi, j) = (xi - mean(o)) / std(o)
function transform(o::CountMap, xi, j) 
    for (i,k) in enumerate(keys(o))
        i == j && return xi == k ? 1.0 : 0.0
    end
end

mlstat(y) = Ignored()
mlstat(y::Number) = Variance() 
mlstat(y::T) where {T<:Union{Bool, AbstractString, Char, Symbol}} = CountMap(T)

_width(o::DataPreprocessor) = sum(_width, o.group.stats)
_width(o::Variance) = 1 
_width(o::CountMap) = nkeys(o) - 1 
_width(o::Ignored) = 0
