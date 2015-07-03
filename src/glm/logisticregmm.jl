inverselogit(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real inverselogit

#-------------------------------------------------------# Type and Constructors
type LogRegMM{W <: Weighting} <: OnlineStat
    β::VecF
    t1::VecF            # Sufficient statistic 1
    t2::MatF            # Sufficient statistic 2
    t3::VecF            # Sufficient statistic 3
    n::Int
    weighting::W
end

function LogRegMM(p::Int, wgt::Weighting = StochasticWeighting(); start = zeros(p))
    LogRegMM(start, zeros(p), zeros(p, p), zeros(p), 0, wgt)
end

function LogRegMM(X::MatF, y::Vector, wgt::Weighting = StochasticWeighting();
                  start::VecF = zeros(size(X, 2)), batch::Bool = true)
    o = LogRegMM(size(X, 2), wgt; start = start)
    batch ? updatebatch!(o, X, y) : update!(o, X, y)
    o
end


#---------------------------------------------------------------------# update!
function updatebatch!(o::LogRegMM, X::MatF, y::Vector)
    n = length(y)
    all([y[i] in [0, 1] for i in 1:n]) || error("y values must be 0 or 1")

    γ = weight(o)

    xtx_n::MatF = X'X / n

    smooth!(o.t1, X' * (y - inverselogit(X * o.β)) / n, γ)
    smooth!(o.t2, xtx_n, γ)
    smooth!(o.t3, xtx_n * o.β, γ)

    o.β = Symmetric(o.t2) \ (o.t3 + 4 * o.t1)
    o.n += n
end


# Singleton updates may have issue with singularities
function update!(o::LogRegMM, x::VecF, y)
    updatebatch!(o, x', [y])
end

function update!(o::LogRegMM, X::MatF, y::Vector{Int})
    @inbounds for i in 1:length(y)
        update!(o, vec(x[i, :]), y[i])
    end
end


#-----------------------------------------------------------------------# state
state(o::LogRegMM) = Any[copy(o.β), nobs(o)]
statenames(o::LogRegMM) = [:β, :nobs]

coef(o::LogRegMM) = copy(o.β)
predict(o::LogRegMM, X::MatF) = inverselogit(X * o.β)
