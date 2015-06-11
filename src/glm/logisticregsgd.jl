inverselogit(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real inverselogit


#-------------------------------------------------------# Type and Constructors
type LogRegSGD{W <: Weighting} <: OnlineStat
    β::VecF             # Coefficients
    n::Int64
    weighting::W
end

function LogRegSGD(p::Int, wgt::Weighting = StochasticWeighting();
                   start::VecF = zeros(p))
    LogRegSGD(start, 0, wgt)
end

function LogRegSGD(X::MatF, y::Vector, wgt::Weighting = StochasticWeighting();
                   start::VecF = zeros(size(X, 2)), batch::Bool = true)
    o = LogRegSGD(size(X, 2), wgt, start = start)
    batch ? updatebatch!(o, X, y) : update!(o, X, y)
    o
end


#---------------------------------------------------------------------# update!
function updatebatch!(o::LogRegSGD, X::Matrix, y::Vector)
    n = length(y)
    all([y[i] in [0, 1] for i in 1:n]) || error("y values must be 0 or 1")

    γ = weight(o)

    o.β += γ * vec(X' * (y - inverselogit(X * o.β)))

    o.n += n
end


#-----------------------------------------------------------------------# state
statenames(o::LogRegSGD) = [:β, :nobs]
state(o::LogRegSGD) = Any[copy(o.β), nobs(o)]

coef(o::LogRegSGD) = copy(o.β)






####################### Testing
# β = [-.5:.1:.5]
# X = [ones(100) randn(100, 10)]
# y = int(OnlineStats.inverselogit(X * β) .> rand(100))

# o = OnlineStats.LogRegSGD(X, y, OnlineStats.StochasticWeighting(.7))
# df = DataFrame(o)

# for i in 1:9999
#     X = [ones(100) randn(100, 10)]
#     y = int(OnlineStats.inverselogit(X * β) .< rand(100))

#     OnlineStats.updatebatch!(o, X, y)
#     push!(df, o)  # append results to DataFrame
# end
# coef(o)
