# This is a "slow" analytical update based on CovarianceMatrix
# At each batch, CovarianceMatrix is updated and then eigenvalue decomposition is done.
#-------------------------------------------------------# Type and Constructors
type AnalyticalPCA{W <: Weighting} <: OnlineStat
    C::CovarianceMatrix{W}
    corr::Bool  # Use correlation instead of covariance?

    # eigen:
    values::VecF
    vectors::MatF  # currently sorted smallest to largest: this is what eig() does

    n::Int64
end


AnalyticalPCA(p::Integer, wgt::Weighting = default(Weighting); corr::Bool = true) =
    AnalyticalPCA(CovarianceMatrix(p, wgt), corr, zeros(p), zeros(p, p), 0)

function AnalyticalPCA(x::AMatF, wgt::Weighting = default(Weighting); corr::Bool = true)
    o = AnalyticalPCA(size(x, 2), wgt, corr = corr)
    updatebatch!(o, x)
    o
end


#-----------------------------------------------------------------------# state
statenames(o::AnalyticalPCA) = [:v, :λ, :nobs]  # decomposition is x'x v = λv
state(o::AnalyticalPCA) = Any[o.vectors, o.values, o.n]


#---------------------------------------------------------------------# update!
function updatebatch!(o::AnalyticalPCA, x::AMatF)
    updatebatch!(o.C, x)
    if o.corr
        o.values, o.vectors = eig(Symmetric(cor(o.C)))
    else
        o.values, o.vectors = eig(Symmetric(cov(o.C)))
    end
    o.n += size(x, 1)
    return
end
