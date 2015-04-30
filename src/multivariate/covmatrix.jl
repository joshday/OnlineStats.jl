
#-------------------------------------------------------# Type and Constructors
type CovarianceMatrix{W <: Weighting} <: OnlineStat
    A::Matrix{Float64}    # X' * X / n
    B::Vector{Float64}    # X * 1' / n (column means)
    n::Int64              # number of observations used
    weighting::W
end

# (p by p) covariance matrix from an (n by p) data matrix
function CovarianceMatrix{T <: Real}(x::Matrix{T}, wgt::Weighting = default(Weighting))
    o = CovarianceMatrix(wgt; p = size(x, 2))
    update!(o, x)
    o
end

CovarianceMatrix(wgt::Weighting = default(Weighting); p = 2) =
    CovarianceMatrix(zeros(p,p), zeros(p), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::CovarianceMatrix) = [:μ, :Σ, :nobs]

state(o::CovarianceMatrix) = Any[mean(o), cov(o), o.n]


#---------------------------------------------------------------------# update!
function update!{T <: Real}(o::CovarianceMatrix, x::Matrix{T})
    n2 = size(x, 1)
    λ = weight(o, n2)
    o.n += n2

    # Update B
    o.B = smooth(o.B, vec(mean(x,1)), λ)
    # Update A
    BLAS.syrk!('L', 'T', λ, x / sqrt(n2), 1 - λ, o.A)
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
            covmat[i, j] = covmat[j, i]
        end
    end
    return covmat
end

function Base.cor(o::CovarianceMatrix)
    B = o.B
    p = size(B, 1)
    covmat = o.A * o.n / (o.n - 1) -
        BLAS.syrk('L','N',1.0, B) * o.n / (o.n - 1)
    for j in 1:p
        for i in 1:j - 1
            covmat[i, j] = covmat[j, i]
        end
    end
    V = 1 ./ sqrt(diag(covmat))
    covmat = V .* covmat .* V'
    return covmat
end




#------------------------------------------------------------------------# Base
# function Base.merge!(c1::CovarianceMatrix, c2::CovarianceMatrix)
#     n2 = c2.n
#     A2 = c2.A
#     B2 = c2.B

#     c1.n += n2
#     γ = n2 / c1.n
#     c1.A += γ * (A2 - c1.A)
#     c1.B += γ * (B2 - c1.B)
# end

function Base.show(io::IO, o::CovarianceMatrix)
    println(io, "Online Covariance Matrix:\n", cov(o))
end

function DataFrame(o::CovarianceMatrix, corr = false)
    convert(DataFrame, corr ? cor(o) : cov(o))
end
