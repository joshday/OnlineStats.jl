# Author: Josh Day <emailjoshday@gmail.com>

export CovarianceMatrix

#------------------------------------------------------------------------------#
#-------------------------------------------------------# CovarianceMatrix Type
type CovarianceMatrix <: ContinuousMultivariateOnlineStat
    A::Matrix    # X' * X
    B::Vector    # X * 1'
    n::Int64     # number of observations used
    p::Int64     # number of columns (variables)
    nb::Int64    # number of batches used
end

@doc* doc"""
    Usage: `CovarianceMatrix(x::Matrix)`

    | Field       |  Description                 |
    |:------------|:-----------------------------|
    | `A::Matrix` | $ X^T X / n $                |
    | `B::Matrix` | $ X^T 1_n $                  |
    | `n::Int64`  | number of observations used  |
    | `p::Int64`  | number of variables          |
    | `nb::Int64` | number of batches used       |
    """ ->
function CovarianceMatrix(x::Matrix)
    n, p = size(x)
    vec1 = ones(n)

    A = BLAS.syrk('L', 'T', 1.0, x) / n
    B = x' * vec1 / n
    CovarianceMatrix(A, B, n, p, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj1::CovarianceMatrix, obj2::CovarianceMatrix)
    if obj1.p != obj2.p
        error("different number of variables")
    end
    n1 = obj1.n
    n2 = obj2.n
    n = n1 + n2

    A1::Matrix = obj1.A
    B1::Vector = obj1.B
    A2::Matrix = obj2.A
    B2::Vector = obj2.B

    A = (n1 * A1 + n2 * A2) / n
    B = (n1 * B1 + n2 * B2) / n


    CovarianceMatrix(A, B, n, obj1.p, obj1.nb + obj2.nb)
end

function update!(obj::CovarianceMatrix, newmat::Matrix)
    obj2 = CovarianceMatrix(newmat)
    mergeobj = update!(obj, obj2)
    obj.A = mergeobj.A
    obj.B = mergeobj.B
    obj.n += obj2.n
    obj.nb += 1
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::CovarianceMatrix)
    B = obj.B
    obj.A * obj.n / (obj.n - 1) -
        BLAS.syrk('L','N',1.0, B) * obj.n / (obj.n - 1)
end

