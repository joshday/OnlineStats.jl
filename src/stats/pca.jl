# Implements Candid Covariance-Free Incremental PCA algorithm of Weng et al:
# Weng, Juyang, Yilu Zhang, and Wey-Shiuan Hwang. "Candid covariance-free 
# incremental principal component analysis." IEEE Transactions on Pattern 
# Analysis and Machine Intelligence 25.8 (2003): 1034-1040.
#
# A comparison of online PCA algorithms in 2018 showed it to be a good
# trade-off in that it is fast and has low reconstruction error:
# H. Cardot and D. Degras, "Online Principal Component Analysis in 
# High Dimension: Which Algorithm to Choose?", Int. Statistical Review, 2018-

"""
    CCIPCA(outdim::Int, indim::Int; l::Int)

Online PCA with the CCIPCA (Candid Covariance-free Incremental PCA) algorithm,
where outdim is the number of dimension to project to, indim is the length
of incoming vectors, and l is the level of amnesia. Give values in the range
2-4 of l if you want old vectors to be gradually less important, i.e.
latest vectors added get more weight.

This is a very fast, simple, and online approximation of PCA. It can be used
for Dimensionality Reduction to project high-dimensional vectors into a 
low-dimensional (typically 2D or 3D) space. This algorithm has shown very 
good properties in comparative studies; it is both fast and give a good 
approximation to (batch) PCA.
"""
mutable struct CCIPCA <: OnlineStat{Vector{Float64}}
    U::Matrix{Float64}      # Eigenvectors, one row per indim, one column per outdim
    lambda::Vector{Float64} # Eigenvalues, one per outdim
    center::Vector{Float64} # Center/mean, one per indim
    l::Int
    n::Int
end
function CCIPCA(indim::Int, outdim::Int; l::Int=0)
    @assert outdim < indim
    @assert l >= 0
    center = zeros(Float64, indim)
    lambda = zeros(Float64, outdim)
    U      = zeros(Float64, indim, outdim)
    CCIPCA(U, lambda, center, l, 0)
end
Base.length(o::CCIPCA) = outdim(o) # Number of eigen-vectors
Base.getindex(o::CCIPCA, i) = o.U[:, i]
Base.lastindex(o::CCIPCA) = outdim(o)
Base.size(o::CCIPCA) = (indim(o), outdim(o))
@inline outdim(o::CCIPCA) = length(o.lambda)
@inline indim(o::CCIPCA) = length(o.center)
function _fit!(o::CCIPCA, x::Vector{Float64})
    @assert length(x) == indim(o)
    n = o.n + 1
    # update center with new observation:
    o.center = (o.n * o.center .+ x)/n
    # center the new observation, unless this is the first observation:
    xi = (o.n > 0) ? (x .- o.center) : deepcopy(x)
    # Now recalc eigen-values and -vectors given the new observation:
    f = (1.0+o.l)/n
    @inbounds for i in 1:outdim(o)
        if i == n
            o.lambda[i] = norm(xi)
            o.U[:, i] = xi / o.lambda[i]
            break
        end
        v = (1-f) * o.lambda[i] * o.U[:, i] + f * dot(o.U[:, i], xi) * xi
        o.lambda[i] = norm(v)
        o.U[:, i] = v/o.lambda[i]
        xi = xi .- (dot(o.U[:, i], xi) * o.U[:, i])
    end
    o.n = n
end
function transform(o::CCIPCA, u::AbstractArray{Float64})
    @assert indim(o) == length(u)
    (u .- o.center)' * o.U
end
function reconstruct(o::CCIPCA, uproj::AbstractArray{Float64})
    @assert outdim(o) == length(uproj)
    o.center .+ (o.U * uproj')
end
function fittransform!(o::CCIPCA, u::Vector)
    _fit!(o, u)
    transform(o, u)
end
function eigenvalue(o::CCIPCA, i::Int)
    @assert 1 <= i <= outdim(o) "This CCIPCA has $(outdim(o)) eigenvalues, cannot return eigenvalue $(i)!"
    o.lambda[i]
end
function eigenvector(o::CCIPCA, i::Int)
    @assert 1 <= i <= outdim(o) "This CCIPCA has $(outdim(o)) eigenvectors, cannot return eigenvector $(i)!"
    o.U[:, i]
end
eigenvalues(o::CCIPCA) = o.lambda
