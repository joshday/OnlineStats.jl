"""
`sweep!(A, k, inv = false)`

Symmetric sweep of the matrix `A` on element `k`.
"""
function sweep!(A::AMatF, k::Integer, inv::Bool = false)
    n, p = size(A)
    # ensure @inbounds is safe
    @assert n == p "A must be square"
    @assert k <= p "pivot element not within range"
    @inbounds d = 1.0 / A[k, k]  # pivot
    # get column A[:, k] (hack because only upper triangle is available)
    akk = zeros(p)
    for j in 1:p
        if j <= k
            @inbounds akk[j] = A[j, k]
        else
            @inbounds akk[j] = A[k, j]
        end
    end
    BLAS.syrk!('U', 'N', -d, akk, 1.0, A)  # everything not in col/row k
    scale!(akk, d * (-1) ^ inv)
    for i in 1:k-1  # col k
        @inbounds A[i, k] = akk[i]
    end
    for j in k+1:p  # row k
        @inbounds A[k, j] = akk[j]
    end
    A[k, k] = -d  # pivot element
    A
end

function sweep!{T<:Integer}(A::AMatF, ks::AVec{T}, inv::Bool = false)
    for k in ks
        sweep!(A, k, inv)
    end
    A
end


#------------------------------------------------------------------------------#
"""
`sweep!(A, k, v, inv = false)`

Symmetric sweep of the matrix `A` on element `k` using vector `v` as storage to
avoid memory allocation.  This requires `length(v) == size(A, 1)`.  Both `A` and `v`
will be overwritten.

`inv = true` will perform an inverse sweep.  Only the upper triangle is read and swept.
"""
function sweep!(A::AMatF, k::Integer, v::AVecF, inv::Bool = false)
    n, p = size(A)
    # ensure that @inbounds is safe
    @assert n == p "A must be square"
    @assert length(v) == p "placeholder length ≠ size(A, 1)"
    @assert k <= p "pivot element not within range"
    @inbounds d = 1.0 / A[k, k]  # pivot
    for j in 1:p   # get column A[:, k]
        if j <= k
            @inbounds v[j] = A[j, k]
        else
            @inbounds v[j] = A[k, j]
        end
    end
    BLAS.syrk!('U', 'N', -d, v, 1.0, A)  # everything not in col/row k
    scale!(v, d * (-1) ^ inv)
    for i in 1:k-1  # col k
        @inbounds A[i, k] = v[i]
    end
    for j in k+1:p  # row k
        @inbounds A[k, j] = v[j]
    end
    @inbounds A[k, k] = -d  # pivot element
    A
end

function sweep!{T<:Integer}(A::AMatF, ks::AVec{T}, v::VecF, inv::Bool = false)
    for k in ks
        sweep!(A, k, v, inv)
    end
    A
end
