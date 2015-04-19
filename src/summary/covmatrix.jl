export CovarianceMatrix

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type CovarianceMatrix <: ContinuousMultivariateOnlineStat
    A::Matrix    # X' * X
    B::Vector    # X * 1'
    n::Int64     # number of observations used
    p::Int64     # number of columns (variables)
end


function CovarianceMatrix{T <: Real}(x::Matrix{T})
    n, p = size(x)
    A = BLAS.syrk('L', 'T', 1.0, x) / n
    B = vec(mean(x, 1))
    CovarianceMatrix(A, B, n, p)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T <: Real}(obj::CovarianceMatrix, x::Matrix{T})
    n2 = size(x, 1)
    A2 = BLAS.syrk('L', 'T', 1.0, x) / n2
    B2 = vec(mean(x, 1))

    obj.n += n2
    γ = n2 / obj.n
    obj.A += γ * (A2 - obj.A)
    obj.B += γ * (B2 - obj.B)
end


#-----------------------------------------------------------------------------#
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

    return covmat
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::CovarianceMatrix) = CovarianceMatrix(obj.A. obj.B, obj.n, obj.p)

Base.mean(obj::CovarianceMatrix) = return obj.B

Base.var(obj::CovarianceMatrix) = diag(state(obj::CovarianceMatrix))

Base.std(obj::CovarianceMatrix) = sqrt(diag(state(obj::CovarianceMatrix)))

Base.cov(obj::CovarianceMatrix) = state(obj::CovarianceMatrix)

Base.cor(obj::CovarianceMatrix) = state(obj::CovarianceMatrix, true)


function Base.merge(c1::CovarianceMatrix, c2::CovarianceMatrix)
    n1 = c1.n
    n2 = c2.n
    n = n1 + n2

    A1::Matrix = c1.A
    B1::Vector = c1.B
    A2::Matrix = c2.A
    B2::Vector = c2.B

    γ = n2 / n
    A = A1 + γ * (A2 - A1)
    B = B1 + γ * (B2 - B1)

    CovarianceMatrix(A, B, n, c1.p)
end

function Base.merge!(c1::CovarianceMatrix, c2::CovarianceMatrix)
    n2 = c2.n
    A2 = c2.A
    B2 = c2.B

    c1.n += n2
    γ = n2 / c1.n
    c1.A += γ * (A2 - c1.A)
    c1.B += γ * (B2 - c1.B)
end

function Base.show(io::IO, obj::CovarianceMatrix)
    println(io, "Online Covariance Matrix:\n", state(obj))
end


