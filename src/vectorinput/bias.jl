# TODO: This files belongs in a different package

# """
# Add a bias/intercept term to a vector on the fly without creating or copying data:
#
# - `BiasVector(rand(10))` is roughly equivalent to `vcat(rand(10), 1.0)`
# """
# immutable BiasVector{A <: AVecF} <: AVecF
#     vec::A
# end
#
# Base.length(v::BiasVector) = length(v.vec) + 1
# Base.size(v::BiasVector) = (length(v),)
# Base.getindex(v::BiasVector, i::Integer) = i > length(v.vec) ? 1.0 : getindex(v.vec, i)
# Base.setindex!(v::BiasVector, x::Real, i::Integer) = setindex!(v.vec, x, i)
#
# """
# Adda bias/intercept term to a matrix on the fly without creating or copying data:
#
# - `BiasMatrix(rand(10,5))` is roughly equivalent to `hcat(rand(10,5), ones(10))`
# """
# immutable BiasMatrix{A <: AMatF} <: AMatF
#     mat::A
# end
#
# Base.length(m::BiasMatrix) = length(m.mat) + nrows(m.mat)
# Base.size(m::BiasMatrix) = (nrows(m.mat), ncols(m.mat)+1)
# Base.getindex(m::BiasMatrix, i::Integer, j::Integer) = j > ncols(m.mat) ? 1.0 : getindex(m.mat, i, j)
# Base.setindex!(m::BiasMatrix, x::Real, i::Integer, j::Integer) = setindex!(m.mat, x, i, j)
#
#
#
# #-----------------------------------------------------------------------------------#
# """
# Add second-order interaction terms on the fly without creating or copying data:
#
# - `TwoWayInteractionVector(rand(p))` "adds" the `binomial(p, 2)` interaction terms
# """
# immutable TwoWayInteractionVector{A<:AVecF} <: AVecF
#     vec::A
# end
# Base.length(v::TwoWayInteractionVector) = length(v.vec) + binomial(length(v.vec), 2)
# Base.size(v::TwoWayInteractionVector) = (length(v),)
# function Base.getindex(v::TwoWayInteractionVector, i::Integer)
#     first = 0
#     second = i
#     n = length(v.vec)
#     if i <= n
#         return v.vec[i]
#     else
#         while second > n
#             second -= n
#             first += 1
#             n -= 1
#         end
#         return v.vec[first] * v.vec[first + second]
#     end
# end
#
# """
# Add second-order interaction terms on the fly without creating or copying data:
#
# - `TwoWayInteractionMatrix(rand(n, p))` "adds" the `binomial(p, 2)` interaction terms
# to each row
# """
# immutable TwoWayInteractionMatrix{A<:AMatF} <: AMatF
#     mat::A
# end
# function Base.length(m::TwoWayInteractionMatrix)
#     n, p = size(m.mat)
#     n * (p + binomial(p, 2))
# end
# function Base.size(m::TwoWayInteractionMatrix)
#     n, p = size(m. mat)
#     (n, p + binomial(p, 2))
# end
# function Base.getindex(m::TwoWayInteractionMatrix, i::Integer, j::Integer)
#     first = 0
#     second = j
#     n, p = size(m.mat)
#     if j <= p
#         return m.mat[i, j]
#     else
#         while second > p
#             second -= p
#             first += 1
#             p -= 1
#         end
#         return m.mat[i, first] * m.mat[i, first + second]
#     end
# end
