
# these are simple AbstractArray implementations that make it easy to add a
# bias/intercept term on the fly without creating or copying array data:
  # "BiasVector(rand(10))" is roughly equivalent to "vcat(rand(10), 1.0)"
  # "BiasMatrix(rand(10,5))" is roughly equivalent to "hcat(rand(10,5), ones(10))"


immutable BiasVector{A<:AVecF} <: AVecF
  vec::A
end

Base.length(v::BiasVector) = length(v.vec) + 1
Base.size(v::BiasVector) = (length(v),)
Base.getindex(v::BiasVector, i::Integer) = i > length(v.vec) ? 1.0 : getindex(v.vec, i)
Base.setindex!(v::BiasVector, x::Real, i::Integer) = setindex!(v.vec, x, i)


immutable BiasMatrix{A<:AMatF} <: AMatF
  mat::A
end

Base.length(m::BiasMatrix) = length(m.mat) + nrows(m.mat)
Base.size(m::BiasMatrix) = (nrows(m.mat), ncols(m.mat)+1)
Base.getindex(m::BiasMatrix, i::Integer, j::Integer) = j > ncols(m.mat) ? 1.0 : getindex(m.mat, i, j)
Base.setindex!(m::BiasMatrix, x::Real, i::Integer, j::Integer) = setindex!(m.mat, x, i, j)
