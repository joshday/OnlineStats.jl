inverselogit(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real inverselogit


#-------------------------------------------------------# Type and Constructors
type LogRegSGD2{W <: Weighting} <: OnlineStat
    β::VecF             # Coefficients
    xtx_n::MatF         # X'X / n
    n::Int64
    weighting::W
end

function LogRegSGD2(p::Integer, wgt::Weighting = StochasticWeighting();
                   start::VecF = zeros(p))
    LogRegSGD2(start, zeros(p,p), 0, wgt)
end

function LogRegSGD2(X::AMatF, y::AVec, wgt::Weighting = StochasticWeighting();
                   start::VecF = zeros(size(X, 2)), batch::Bool = true)
    o = LogRegSGD2(ncols(X), wgt, start = start)
    batch ? updatebatch!(o, X, y) : update!(o, X, y)
    o
end


#---------------------------------------------------------------------# update!
function updatebatch!(o::LogRegSGD2, X::AMat, y::AVec)
    n = length(y)

    γ = weight(o)
    smooth!(o.xtx_n, X'X / n, γ)

    o.β += γ * inv(o.xtx_n) * vec(X' * (y - inverselogit(X * o.β))) / n

    o.n += n
end


#-----------------------------------------------------------------------# state
statenames(o::LogRegSGD2) = [:β, :nobs]
state(o::LogRegSGD2) = Any[copy(o.β), nobs(o)]

coef(o::LogRegSGD2) = copy(o.β)
predict(o::LogRegSGD2, X::AMatF) = inverselogit(X * o.β)
