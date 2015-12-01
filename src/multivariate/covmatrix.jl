#-------------------------------------------------------# Type and Constructors
"""
Analytical estimate of covariance matrix.
"""
type CovarianceMatrix{W <: Weighting} <: OnlineStat
    A::MatF           # X' * X / n
    B::VecF           # X * 1' / n (column means)
    n::Int64
    weighting::W
end

# (p by p) covariance matrix from an (n by p) data matrix
function CovarianceMatrix{T <: Real}(x::AMat{T}, wgt::Weighting = default(Weighting))
    o = CovarianceMatrix(ncols(x), wgt)
    updatebatch!(o, x)
    o
end

CovarianceMatrix(p::Integer, wgt::Weighting = default(Weighting)) =
    CovarianceMatrix(zeros(p, p), zeros(p), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::CovarianceMatrix) = [:μ, :Σ, :nobs]
state(o::CovarianceMatrix) = Any[mean(o), cov(o), o.n]

"""
`pca(o, corr = true; kw...)`

Perform principal components analysis of the data provided to the `CovarianceMatrix`
object `o` using the correlation matrix (`corr = true`) or covariance matrix.

The keyword argument `maxoutdim` specifies the number of components to return.
"""
function pca(o::CovarianceMatrix, corr::Bool = true; keyargs...)
    if corr
        MultivariateStats.pcacov(cor(o), mean(o); keyargs...)
    else
        MultivariateStats.pcacov(cov(o), mean(o); keyargs...)
    end
end


#---------------------------------------------------------------------# update!
function updatebatch!(o::CovarianceMatrix, x::AMatF)
    n2 = size(x, 1)
    λ = weight(o, n2)
    o.n += n2
    smooth!(o.B, vec(mean(x, 1)), λ)  # update B
    BLAS.syrk!('L', 'T', λ / n2, x, 1.0 - λ, o.A)  # update A
    return
end

update!(o::CovarianceMatrix, x::AVecF) = updatebatch!(o, x')

function update!(o::CovarianceMatrix, x::AMatF)
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
