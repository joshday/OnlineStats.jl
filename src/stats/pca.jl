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
    CCIPCA(outdim::Int, indim; l::Int)

Online PCA with the CCIPCA (Candid Covariance-free Incremental PCA) algorithm,
where indim is the length of incoming vectors, outdim is the number of 
dimension to project to, and l is the level of amnesia. Give values of l in 
the range 2-4 if you want old vectors to be gradually less important, i.e. 
latest vectors added get more weight.

If no indim is specified it will be set later, on first call to fit. After
that it is fixed and cannot change.

The CCIPCA is a very fast, simple, and online approximation of PCA. It can be used
for Dimensionality Reduction to project high-dimensional vectors into a 
low-dimensional (typically 2D or 3D) space. This algorithm has shown very 
good properties in comparative studies; it is both fast and give a good 
approximation to (batch) PCA.

# Example

    o = CCIPCA(2, 10)                # Project 10-dimensional vectors into 2D
    u1 = rand(10)
    fit!(o, u1)                      # Fit to u1
    u2 = rand(10)
    fit!(o, u2)                      # Fit to u2
    u3 = rand(10)
    OnlineStats.transform(o, u3)     # Project u3 into PCA space fitted to u1 and u2 but don't change the projection
    u4 = rand(10)
    OnlineStats.fittransform!(o, u4) # Fit u4 and then project u4 into the space
    sort!(o)                         # Sort from high to low eigenvalues
    o[1]                             # Get primary (1st) eigenvector
    OnlineStats.relativevariances(o)         # Get the variation (explained) "by" each eigenvector
"""
mutable struct CCIPCA <: OnlineStat{AbstractVector{<:Real}}
    lambda::Vector{Float64} # Eigenvalues, one per outdim
    U::Matrix{Float64}      # Eigenvectors, one row per indim, one column per outdim
    center::Vector{Float64} # Center/mean, one per indim
    xi::Vector{Float64}     # temp var used in calc, saved here for speed
    v::Vector{Float64}      # temp var used in calc, saved here for speed
    l::Int
    n::Int
    indimdet::Bool          # True iff indim has been determined (if not it is set on first fit)
end
function CCIPCA(outdim::Int, indim::Union{Nothing,Int} = nothing; l::Int=0)
    if isnothing(indim)
        indim = 1 # Dummy value, since we will update on first _fit
        indimdet = false
    elseif indim > 0
        @assert outdim < indim "indim ($indim) must be larger than outdim ($outdim)"
        indimdet = true
    else
        error("indim cannot take a value below 1, was set to $indim")
    end
    @assert l >= 0
    CCIPCA(setup_internal_vars(outdim, indim)..., l, 0, indimdet)
end
function setup_internal_vars(outdim::Int, indim::Int)
    lambda = zeros(Float64, outdim)
    U      = zeros(Float64, indim, outdim)
    center = zeros(Float64, indim)
    xi     = zeros(Float64, indim)
    v      = zeros(Float64, indim)
    return (lambda, U, center, xi, v)
end
Base.length(o::CCIPCA) = outdim(o) # Number of eigen-vectors
Base.getindex(o::CCIPCA, i) = o.U[:, i]
Base.lastindex(o::CCIPCA) = outdim(o)
Base.size(o::CCIPCA) = (indim(o), outdim(o))
@inline outdim(o::CCIPCA) = length(o.lambda)
@inline indim(o::CCIPCA) = length(o.center)
function _fit!(o::CCIPCA, x::Vector{Float64})
    if o.indimdet == false
        # Now indim is known so we set up accordingly
        idim = length(x)
        o.indimdet = true
        odim = size(o.U, 2)
        @assert odim < idim "indim ($idim) must be larger than outdim ($odim)"
        o.lambda, o.U, o.center, o.xi, o.v = setup_internal_vars(odim, idim)
    else
        @assert length(x) == OnlineStats.indim(o)
    end
    n = o.n + 1
    # update center with new observation:
    #o.center = (o.n * o.center .+ x)/n
    o.center += (x .- o.center) ./ n
    # center the new observation, unless this is the first observation:
    o.xi = (o.n > 0) ? (x .- o.center) : deepcopy(x)
    # Now recalc eigen-values and -vectors given the new observation:
    f = (1.0+o.l)/n
    @inbounds for i in 1:outdim(o)
        if i == n
            o.lambda[i] = norm(o.xi)
            o.U[:, i] = o.xi / o.lambda[i]
            break
        end
        o.v = (1-f) * o.lambda[i] * o.U[:, i] + f * dot(o.U[:, i], o.xi) * o.xi
        o.lambda[i] = norm(o.v)
        o.U[:, i] = o.v/o.lambda[i]
        o.xi = o.xi .- (dot(o.U[:, i], o.xi) * o.U[:, i])
    end
    o.n = n
end
"""
    transform(o::CCIPCA, u::AbstractArray{Float64})

Transform (i.e. project) the vector `u` into the PCA space 
represented by `o`.
"""
function transform(o::CCIPCA, u::AbstractArray{Float64})
    @assert indim(o) == length(u)
    (u .- o.center)' * o.U
end
# We can also call the CCIPCA object itself to transform:
(o::CCIPCA)(u::AbstractArray{Float64}) = transform(o, u)
"""
    reconstruct(o::CCIPCA, uproj::AbstractArray{Float64})

Reconstruct the (projected) vector `uproj` back to the original
space from which `o` has been fitted.
"""
function reconstruct(o::CCIPCA, uproj::AbstractArray{Float64})
    @assert outdim(o) == length(uproj)
    o.center .+ (o.U * uproj')
end
"""
    fittransform!(o::CCIPCA, u::Vector{Float64})

First `fit!` and then `transform` the vector `u` into the PCA
space represented by `o`.
"""
function fittransform!(o::CCIPCA, u::Vector{Float64})
    _fit!(o, u)
    transform(o, u)
end
"""
    eigenvalue(o::CCIPCA, i::Int)

Get the `i`th eigenvalue of `o`. Also called principal variance
for PCA.
"""
function eigenvalue(o::CCIPCA, i::Int)
    @assert 1 <= i <= outdim(o) "This CCIPCA has $(outdim(o)) eigenvalues, cannot return eigenvalue $(i)!"
    o.lambda[i]
end
"""
    eigenvalue(o::CCIPCA, i::Int)

Get the `i`th eigenvalue of `o`. Also called principal variance
for PCA.
"""
principalvar(o::CCIPCA, i::Int) = eigenvalue(o, i)
"""
    eigenvector(o::CCIPCA, i::Int)

Get the `i`th eigenvector of `o`.
"""
function eigenvector(o::CCIPCA, i::Int)
    @assert 1 <= i <= outdim(o) "This CCIPCA has $(outdim(o)) eigenvectors, cannot return eigenvector $(i)!"
    o.U[:, i]
end
eigenvalues(o::CCIPCA) = Float64[eigenvalue(o, i) for i in 1:outdim(o)]
principalvars(o::CCIPCA) = eigenvalues(o)
"""
    relativevariances(o::CCIPCA)

Get the relative variance (explained) in the direction of each 
eigenvector. Returns a vector of zeros if no vectors have yet been fitted.
Note that this does not inclue the residual variance that is not captured
in the eigenvectors.
"""
function relativevariances(o::CCIPCA)
    if o.n == 0
        return zeros(Float64, outdim(o))
    else
        return o.lambda ./ sum(o.lambda)
    end
end
"""
    sort!(o::CCIPCA)

Sort eigenvalues and their eigenvectors of `o` so highest ones come first.
Useful before visualising since it ensures most variation is on the
first (X) axis.
"""
function Base.sort!(o::CCIPCA)
    perm = sortperm(o.lambda, rev=true)
    o.lambda = o.lambda[perm]
    o.U = o.U[:, perm]
end
