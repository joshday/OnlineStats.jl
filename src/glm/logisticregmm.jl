#-------------------------------------------------------# Type and Constructors
type LogRegMM{W <: Weighting} <: OnlineStat
    β::VecF
    t1::VecF            # Sufficient statistic 1
    t2::MatF            # Sufficient statistic 2
    t3::VecF            # Sufficient statistic 3
    n::Int
    weighting::W
end

function LogRegMM(p::Integer, wgt::Weighting = StochasticWeighting();
        start = zeros(p)
    )
    LogRegMM(start, zeros(p), zeros(p, p), zeros(p), 0, wgt)
end

function LogRegMM(x::AMatF, y::AVec, wgt::Weighting = StochasticWeighting();
                  start::VecF = zeros(size(x, 2)), batch::Bool = true)
    o = LogRegMM(size(x, 2), wgt; start = start)
    batch ? updatebatch!(o, x, y) : update!(o, x, y)
    o
end


#---------------------------------------------------------------------# update!
function updatebatch!(o::LogRegMM, x::AMatF, y::AVec)
    n = length(y)

    γ = weight(o)

    xtx_n = x'x / n

    smooth!(o.t1, x' * (y - inverselogit(x * o.β)) / n, γ)
    smooth!(o.t2, xtx_n, γ)
    smooth!(o.t3, xtx_n * o.β, γ)

    o.β = Symmetric(o.t2) \ (o.t3 + 4 * o.t1)
    o.n += n
end


# Singleton updates may have issue with singularities
function update!(o::LogRegMM, x::VecF, y::Real)
    updatebatch!(o, x', [y])
end

function update!(o::LogRegMM, x::AMatF, y::AVec{Int})
    @inbounds for i in 1:length(y)
        update!(o, vec(x[i, :]), y[i])
    end
end


#-----------------------------------------------------------------------# state
state(o::LogRegMM) = Any[copy(o.β), nobs(o)]
statenames(o::LogRegMM) = [:β, :nobs]

StatsBase.coef(o::LogRegMM) = copy(o.β)
StatsBase.predict(o::LogRegMM, x::AMatF) = inverselogit(x * o.β)
