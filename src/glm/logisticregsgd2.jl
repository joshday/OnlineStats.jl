inverselogit(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real inverselogit


#-------------------------------------------------------# Type and Constructors
type LogRegSGD2{W <: Weighting} <: OnlineStat
    β::VecF             # Coefficients
    xtx_n::MatF         # X'X / n
    n::Int64
    weighting::W
end

function LogRegSGD2(p::Int, wgt::Weighting = StochasticWeighting();
                   start::VecF = zeros(p))
    LogRegSGD2(start, zeros(p,p), 0, wgt)
end

function LogRegSGD2(X::MatF, y::Vector, wgt::Weighting = StochasticWeighting();
                   start::VecF = zeros(size(X, 2)), batch::Bool = true)
    o = LogRegSGD2(size(X, 2), wgt, start = start)
    batch ? updatebatch!(o, X, y) : update!(o, X, y)
    o
end


#---------------------------------------------------------------------# update!
function updatebatch!(o::LogRegSGD2, X::Matrix, y::Vector)
    n = length(y)
    all([y[i] in [0, 1] for i in 1:n]) || error("y values must be 0 or 1")

    γ = weight(o)
    smooth!(o.xtx_n, X'X / n, γ)

    o.β += γ * inv(o.xtx_n) * vec(X' * (y - inverselogit(X * o.β))) / n

    o.n += n
end


#-----------------------------------------------------------------------# state
statenames(o::LogRegSGD2) = [:β, :nobs]
state(o::LogRegSGD2) = Any[copy(o.β), nobs(o)]

StatsBase.coef(o::LogRegSGD2) = copy(o.β)






####################### Testing
β = [-.5:.1:.5]
X = [ones(100) randn(100, 10)]
y = int(OnlineStats.inverselogit(X * β) .> rand(100))

o = OnlineStats.LogRegSGD2(X, y, OnlineStats.StochasticWeighting(.7))
df = DataFrame(o)

for i in 1:9999
    X = [ones(100) randn(100, 10)]
    y = int(OnlineStats.inverselogit(X * β) .< rand(100))

    OnlineStats.updatebatch!(o, X, y)
    push!(df, o)  # append results to DataFrame
end
coef(o)
