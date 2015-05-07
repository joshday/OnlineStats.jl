#-------------------------------------------------------# Type and Constructors
type QuantRegMM{W <: Weighting} <: OnlineStat
    β::VecF
    τ::Float64        # Desired conditional quantile
    ϵ::Float64        # epsilon for approximate quantile loss function
    XtWX::MatF         # "sufficient statistic" 1
    Xu::VecF          # "sufficient statistic" 2
    n::Int64
    weighting::W
end

function QuantRegMM(p::Int, wgt::Weighting = StochasticWeighting();
                    τ::Float64 = .5, start::VecF = zeros(p), ϵ::Float64 = 1e-8)
    @assert τ > 0 && τ < 1
    QuantRegMM(start, τ, ϵ, zeros(p, p), zeros(p), 0, wgt)
end

function QuantRegMM(X::MatF, y::VecF, wgt::Weighting = StochasticWeighting();
                    τ::Float64 = .5, start::VecF = zeros(size(X, 2)), ϵ::Float64 = 1e-8,
                    batch = true)
    o = QuantRegMM(size(X, 2), wgt, τ = τ, start = start, ϵ = ϵ)
    batch ? updatebatch!(o, X, y) : update(o, X, y)
    o
end

#-----------------------------------------------------------------------# state
statenames(o::QuantRegMM) = [:β, :τ, :nobs]
state(o::QuantRegMM) = Any[coef(o), o.τ, nobs(o)]

coef(o::QuantRegMM) = copy(o.β)

#---------------------------------------------------------------------# update!
function update!(o::QuantRegMM, x::VecF, y::Float64)
    γ = weight(o)

    w = o.ϵ + abs(y - x' * o.β)[1]
    u = y / w + 2 * o.τ - 1

    smooth!(o.XtWX, x * (x / w)', γ)
    smooth!(o.Xu, x .* u, γ)
    o.β = o.XtWX \  o.Xu
    o.n += 1
end

function update!(o::QuantRegMM, X::MatF, y::VecF)
    for i in 1:size(X,1)
        update!(o, vec(X[i, :]), y[i])
    end
end

function updatebatch!(o::QuantRegMM, X::MatF, y::VecF)
    n = size(X, 1)
    γ = weight(o)

    w = 1 ./ (o.ϵ + abs(y - X * o.β))
    u = y .* w + 2 * o.τ - 1

    smooth!(o.XtWX, X' * scale(w, X), γ)
    smooth!(o.Xu, X' * u, γ)

    o.β = o.XtWX \ o.Xu
    o.n += n
end


#######################
#testing
srand(100)
x = rand(100,4); x_int = [ones(100) x]; y = vec(sum(x,2)) + randn(100)
o = OnlineStats.QuantRegMM(x_int, y)

for i in 1:1000
    x = rand(100,4); x_int = [ones(100) x]; y = vec(sum(x,2)) + randn(100)
    OnlineStats.updatebatch!(o, x_int, y)
end
o
