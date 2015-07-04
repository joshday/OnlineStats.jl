#-------------------------------------------------------# Type and Constructors
type CovarianceMatrix{W <: Weighting} <: OnlineStat
    A::MatF           # X' * X / n
    B::VecF           # X * 1' / n (column means)
    n::Int64
    weighting::W
end

# (p by p) covariance matrix from an (n by p) data matrix
function CovarianceMatrix{T <: Real}(x::Matrix{T}, wgt::Weighting = default(Weighting))
    o = CovarianceMatrix(size(x, 2), wgt)
    updatebatch!(o, x)
    o
end

CovarianceMatrix(p::Int, wgt::Weighting = default(Weighting)) =
    CovarianceMatrix(zeros(p, p), zeros(p), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::CovarianceMatrix) = [:μ, :Σ, :nobs]
state(o::CovarianceMatrix) = Any[mean(o), cov(o), o.n]

function pca(o::CovarianceMatrix, nev::Int = length(o.B), corr::Bool = true; keyargs...)
    if nev == length(o.B)
        if corr
            eig(Symmetric(cor(o)))
        else
            eig(Symmetric(cov(o)))
        end
    else
        if corr
            eigs(cor(o), nev = nev, which = :LR, keyargs...)
        else
            eigs(cor(o), nev = nev, which = :LR, keyargs...)
        end
    end
end


#---------------------------------------------------------------------# update!
function updatebatch!(o::CovarianceMatrix, x::MatF)
    n2 = size(x, 1)
    λ = weight(o, n2)
    o.n += n2

    # Update B
    smooth!(o.B, vec(mean(x,1)), λ)
    # Update A
    BLAS.syrk!('L', 'T', λ, x / sqrt(n2), 1 - λ, o.A)
    return
end

function update!(o::CovarianceMatrix, x::VecF)
    updatebatch!(o, x')
end

function update!(o::CovarianceMatrix, x::MatF)
    for i in 1:size(x, 1)
        updatebatch!(o, x[i, :])
    end
end

#-----------------------------------------------------------------------# state
Base.mean(o::CovarianceMatrix) = return o.B
Base.var(o::CovarianceMatrix) = diag(cov(o::CovarianceMatrix))
Base.std(o::CovarianceMatrix) = sqrt(var(o::CovarianceMatrix))

function Base.cov(o::CovarianceMatrix)
    B = o.B
    p = size(B, 1)
    covmat = o.n / (o.n - 1) * (o.A - BLAS.syrk('L','N',1.0, B))
    for j in 1:p
        for i in 1:j - 1
            @inbounds covmat[i, j] = covmat[j, i]
        end
    end
    return covmat
end

function Base.cor(o::CovarianceMatrix)
    covmat = cov(o)
    V = 1 ./ sqrt(diag(covmat))
    covmat = V .* covmat .* V'
    return covmat
end




#------------------------------------------------------------------------# Base
function Base.merge!(c1::CovarianceMatrix, c2::CovarianceMatrix)
    λ = mergeweight(c1, c2)
    c1.A = smooth(c1.A, c2.A, λ)
    c1.B = smooth(c1.B, c2.B, λ)
    c1.n += c2.n
end
