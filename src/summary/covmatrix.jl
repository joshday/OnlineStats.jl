export CovarianceMatrix

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type CovarianceMatrix <: MatrixvariateOnlineStat
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
    obj.n += n2
    γ = n2 / obj.n

    # Update B
    obj.B += γ * (vec(mean(x, 1)) - obj.B)
    # Update A
    BLAS.syrk!('L', 'T', γ, x / sqrt(n2), 1 - γ, obj.A)
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::CovarianceMatrix, cormat=false)
    if cormat
        df = convert(DataFrame, cor(obj))
    else
        df = convert(DataFrame, cov(obj))
    end
    return df
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::CovarianceMatrix) = CovarianceMatrix(obj.A. obj.B, obj.n, obj.p)

Base.mean(obj::CovarianceMatrix) = return obj.B

Base.var(obj::CovarianceMatrix) = diag(cov(obj::CovarianceMatrix))

Base.std(obj::CovarianceMatrix) = sqrt(var(obj::CovarianceMatrix))

function Base.cov(obj::CovarianceMatrix)
    B = obj.B
    p = size(B, 1)
    covmat = obj.A * obj.n / (obj.n - 1) -
        BLAS.syrk('L','N',1.0, B) * obj.n / (obj.n - 1)
    for i in 1:p
        for j in i:p
            covmat[i, j] = covmat[j, i]
        end
    end
    return covmat
end

function Base.cor(obj::CovarianceMatrix)
    B = obj.B
    p = size(B, 1)
    covmat = obj.A * obj.n / (obj.n - 1) -
        BLAS.syrk('L','N',1.0, B) * obj.n / (obj.n - 1)
    for i in 1:p
        for j in i:p
            covmat[i, j] = covmat[j, i]
        end
    end
    V = 1 ./ sqrt(diag(covmat))
    covmat = V .* covmat .* V'
    return covmat
end


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
    println(io, "Online Covariance Matrix:\n", cov(obj))
end


