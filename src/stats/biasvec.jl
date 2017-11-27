struct BiasVec{T, A <: AbstractVector{T}} <: AbstractVector{T}
    x::A
end
BiasVec(x) = BiasVec{eltype(x), typeof(x)}(x)

Base.length(v::BiasVec) = length(v.x) + 1

Base.size(v::BiasVec) = (length(v), )

Base.getindex(v::BiasVec, i::Int) = i > length(v.x) ? 1.0 : v.x[i]

Base.IndexStyle(::Type{<:BiasVec}) = IndexLinear()