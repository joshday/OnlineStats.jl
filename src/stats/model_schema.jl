#-----------------------------------------------------------------------# Continuous 
struct Continuous <: ExactStat{0}
    stat::Variance
end
Continuous() = Continuous(Variance())
fit!(o::Continuous, y::Number, γ::Number) = fit!(o.stat, y, γ)
Base.show(io::IO, o::Continuous) = print(io, "Continuous(μ = $(mean(o.stat)), σ = $(std(o.stat)))")
width(o::Continuous) = 1


#-----------------------------------------------------------------------# Categorical 
mutable struct Categorical{T} <: ExactStat{0}
    stat::CountMap{T}
    maxlevels::Int
    maxlevelsreached::Bool
end
Categorical(T::Type = Any, maxlevels = 25) = Categorical(CountMap(T), maxlevels, false)
function fit!(o::Categorical, y, γ::Number) 
    o.maxlevelsreached = length(o.stat) > o.maxlevels
    !o.maxlevelsreached && fit!(o.stat, y, γ)
end
Base.show(io::IO, o::Categorical) = print(io, "Categorical($(keys(o.stat)))")
width(o::Categorical) = length(o.stat) - 1


#-----------------------------------------------------------------------# ModelSchema 
mutable struct ModelSchema <: ExactStat{1}
    d::Dict{Symbol, Any}
    ModelSchema(hint = Dict{Symbol, Any}()) = new(hint)
end
function Base.show(io::IO, o::ModelSchema) 
    println(io, "Schema:")
    lastkey = collect(keys(o.d))[end]
    for (key, val) in o.d
        print(io, "    ", key, ": ", val)
        key != lastkey && println(io)
    end
end

fit!(::Void, args...) = nothing

function fit!(o::ModelSchema, y::NamedTuple, γ::Number)
    for key in keys(y)
        if haskey(o.d, key)
            fit!(o.d[key], y[key], γ)
        else
            stat = make_stat(y[key])
            o.d[key] = stat
        end
    end
end



#------------------------------------------------# default continuous/categorical types
make_stat(y) = error("OnlineStats doesn't know if this type is continuous or categorical.")

make_stat(y::Number) = (o = Continuous(); fit!(o, y, 1.0); o)

const CategoricalType = Union{Bool, AbstractString, Symbol, Char}
make_stat(y::T) where {T<:CategoricalType} = (o = Categorical(T); fit!(o, y, 1.0); o)

