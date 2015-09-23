#--------------------------------------------------------# Type and Constructors
"""
Online update of the cholesky decomposition of X'X / n = R'R
"""
type OnlineCholesky{W <: Weighting} <: OnlineStat
    L::MatF    # Lower Triangle
    n::Int
    weighting::W
end

function OnlineCholesky(p::Int, wgt::Weighting = default(Weighting))
    OnlineCholesky(zeros(p, p), 0, wgt)
end

function OnlineCholesky(x::MatF, wgt::Weighting = default(Weighting))
    n, p = size(x)
    o = OnlineCholesky(p, wgt)
    update!(o, x)
    o
end

#----------------------------------------------------------------------# update!
function update!(o::OnlineCholesky, x::AVecF)
end


#------------------------------------------------------------------------# state
statenames(o::OnlineCholesky) = [:L, :nobs]
state(o::OnlineCholesky) = Any[copy(o.L), nobs(o)]
