# Author: Josh Day <emailjoshday@gmail.com>

export CovarianceMatrix

#------------------------------------------------------------------------------#
#----------------------------------------------------------------# Summary Type
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

    A = BLAS.syrk('L', 'T', 1.0, x)
    B = x' * vec1
    CovarianceMatrix(A, B, n, p, 1)
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# merge
function Base.merge(obj1::CovarianceMatrix, obj2::CovarianceMatrix)
    if obj1.p != obj2.p
        error("different number of variables")
    end
    n1 = obj1.n
    n2 = obj2.n

    A1::Matrix = obj1.A
    B1::Vector = obj1.B
    A2::Matrix = obj2.A
    B2::Vector = obj2.B


    CovarianceMatrix(A1 + A2, B1 + B2, obj1.n + obj2.n, obj1.p, obj1.nb + obj2.nb)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::CovarianceMatrix, newmat::Matrix)
    obj2 = CovarianceMatrix(newmat)
    mergeobj = OnlineStats.merge(obj, obj2)
    obj.A = mergeobj.A
    obj.B = mergeobj.B
    obj.n += obj2.n
    obj.nb += 1
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::CovarianceMatrix)
    B = obj.B
    obj.A/ (obj.n - 1) - BLAS.syrk('L','N',1.0, B) / (obj.n*(obj.n-1))
end


#################################
#################################
#################################
#################################
#################################


x1 = rand(100,3)
obj1 = OnlineStats.CovarianceMatrix(x1)
OnlineStats.state(obj1)
OnlineStats.state(obj1) - cov(x1)

x2 = rand(100, 3)
obj2 = OnlineStats.CovarianceMatrix(x2)
OnlineStats.state(obj2)
OnlineStats.state(obj2) - cov(x2)

obj = Base.merge(obj1, obj2)
OnlineStats.state(obj)
OnlineStats.state(obj) - cov([x1, x2])

OnlineStats.update!(obj1, x2)
OnlineStats.state(obj1)
OnlineStats.state(obj1) - cov([x1, x2])

