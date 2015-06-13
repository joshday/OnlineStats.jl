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


AnalyticalPCA(p::Int, wgt::Weighting = default(Weighting), corr = true) =
    AnalyticalPCA(CovarianceMatrix(p, wgt), corr, zeros(p), zeros(p, p), 0)

function AnalyticalPCA(X::MatF, wgt::Weighting = default(Weighting), corr = true)
    o = AnalyticalPCA(size(X, 2), wgt, corr)
    updatebatch!(o, X)
    o
end


#-----------------------------------------------------------------------# state
statenames(o::AnalyticalPCA) = [:v, :λ, :nobs]  # decomposition is X'X v = λv
state(o::AnalyticalPCA) = Any[o.vectors, o.values, o.n]


#---------------------------------------------------------------------# update!
function updatebatch!(o::AnalyticalPCA, X::MatF)
    updatebatch!(o.C, X)
    if o.corr
        o.values, o.vectors = eig(Symmetric(cor(o.C)))
    else
        o.values, o.vectors = eig(Symmetric(cov(o.C)))
    end
    o.n += size(X, 1)
    return
end

