# This keeps track of the top d principal compoents

#-------------------------------------------------------------# Type and Constructors
type TopPCA{W <: Weighting} <: OnlineStat
    C::CovarianceMatrix{W}
    corr::Bool  # Use correlation instead of covariance?
    alg::Symbol # algorithm for update (:power or :eigs)

    # eigen:
    values::VecF
    vectors::MatF  # currently sorted smallest to largest: this is what eig() does
    n::Int64
    function TopPCA(C::CovarianceMatrix{W}, corr::Bool, alg::Symbol, values::VecF)
end


TopPCA(p::Int, d::Int = p, wgt::Weighting = default(Weighting);
       corr::Bool = true, alg::Symbol = :power) =
    TopPCA(CovarianceMatrix(p, wgt), corr, alg, zeros(p), zeros(p, p), 0)


# Weighting is ignored for the first batch
function TopPCA(X::MatF, d::Int = size(X, 2), wgt::Weighting = default(Weighting);
                corr::Bool = true, alg::Symbol = :eigs)
    # create "empty" TopPCA
    o = TopPCA(size(X, 2), d, wgt, corr = corr, alg = alg)
    updatebatch!(o.C, X)
    # Set inital values to be analytical values
    if o.corr
        o.values, o.vectors = eig(Symmetric(cor(o.C)))
    else
        o.values, o.vectors = eig(Symmetric(cov(o.C)))
    end
    # Only keep top d
    o.values = o.values[end-d:end]
    o.vectors = o.vectors[:, end-d:end]
    o.n += size(X, 1)
    o
end


#-----------------------------------------------------------------------------# state
statenames(o::TopPCA) = [:v, :λ, :nobs]  # decomposition is X'X v = λv
state(o::TopPCA) = Any[o.vectors, o.values, o.n]


#---------------------------------------------------------------------------# update!
function updatebatch!(o::TopPCA, X::MatF)
    updatebatch!(o.C, X)
    if o.alg == :eigs
        if o.corr
            o.values, o.vectors = eigs(cor(o.C))
        else
            o.values, o.vectors = eigs(cov(o.C))
        end
    elseif o.alg == :power
        #TODO
    end
    o.n += size(X, 1)
    return
end
