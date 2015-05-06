"""
Symmetric sweep of matrix A.  Only the lower triangular part is read and swept.
"""
:sweep!


function sweep!(A::Matrix{Float64}, k::Int, inv::Bool=false)
    n = size(A, 1)
    # pivot element
    p = 1.0 / A[k, k]
    # pointer to A[k, 1]
    pAk1 = pointer(A) + (k - 1) * sizeof(Float64)
    # pointer to A[k+1, k]
    pAkk = pointer(A) + ((k - 1) * n + k) * sizeof(Float64)
    # pointer to v[1]
    v = zeros(n)
    pv1 = pointer(v)
    # pointer to v[k+1]
    pvk = pointer(v) + k * sizeof(Float64)
    # copy k-th column of A to v
    BLAS.blascopy!(k, pAk1, n, pv1, 1)
    BLAS.blascopy!(n - k, pAkk, 1, pvk, 1)
    # rank 1 update of A
    BLAS.syrk!('L', 'N', -p, v, 1.0, A)
    # update the k-th column and k-th row of A
    if inv
        BLAS.axpy!(k, -p, pv1, 1, pAk1, n)
        BLAS.axpy!(n - k, -p, pvk, 1, pAkk, 1)
    else
        BLAS.axpy!(k, p, pv1, 1, pAk1, n)
        BLAS.axpy!(n - k, p, pvk, 1, pAkk, 1)
    end
    # update the pivot element
    A[k, k] = -p
    return A
end


function sweep!(A::Matrix{Float64}, I::Range{Int}=1:size(A, 1), inv::Bool=false)
    for k in I
        sweep!(A, k, inv)
    end
    return A
end


function sweep!(A::Matrix{Float64}, S::Vector{Int}, inv::Bool=false)
    for k in S
        sweep!(A, k, inv)
    end
    return A
end


