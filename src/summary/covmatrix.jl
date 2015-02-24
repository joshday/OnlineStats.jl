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
function state(obj::CovarianceMatrix, corr=false)
    B = obj.B
    p = size(B, 1)
    covmat = obj.A * obj.n / (obj.n - 1) -
        BLAS.syrk('L','N',1.0, B) * obj.n / (obj.n - 1)
    tril!(covmat)

    for i in 1:p
        for j in i:p
            covmat[i, j] = covmat[j, i]
        end
    end

    if corr
        V = 1 ./ sqrt(diag(covmat))
        covmat = V .* covmat .* V'
    end

    return(covmat)
end








#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# x1 = randn(103, 5)
# x2 = randn(271, 5)
# x3 = randn(149, 5)

# obj = OnlineStats.CovarianceMatrix(x1)
# OnlineStats.update!(obj, x2)
# OnlineStats.update!(obj, x3)
# mat = OnlineStats.state(obj, true)
# display(mat)
# display(mat - cor([x1, x2, x3]))

