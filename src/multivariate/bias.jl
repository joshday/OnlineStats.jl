
# these are simple AbstractArray implementations that make it easy to add a bias term on the fly without
# creating or copying array data:
  # "BiasVector(rand(10))" is roughly equivalent to "vcat(rand(10), 1.0)"
  # "BiasMatrix(rand(10,5))" is roughly equivalent to "hcat(rand(10,5), ones(10))"


immutable BiasVector{A<:AbstractVector{Float64}} <: AbstractVector{Float64}
  vec::A
end

Base.length(v::BiasVector) = length(v.vec) + 1
Base.size(v::BiasVector) = (length(v),)
Base.getindex(v::BiasVector, i::Int) = i > length(v.vec) ? 1.0 : getindex(v.vec, i)
Base.setindex!(v::BiasVector, x::Float64, i::Int) = setindex!(v.vec, x, i)


immutable BiasMatrix{A<:AbstractMatrix{Float64}} <: AbstractMatrix{Float64}
  mat::A
end

Base.length(m::BiasMatrix) = length(m.mat) + nrows(m.mat)
Base.size(m::BiasMatrix) = (nrows(m.mat), ncols(m.mat)+1)
Base.getindex(m::BiasMatrix, i::Int, j::Int) = j > ncols(m.mat) ? 1.0 : getindex(m.mat, i, j)
Base.setindex!(m::BiasMatrix, x::Float64, i::Int, j::Int) = setindex!(m.mat, x, i, j)
