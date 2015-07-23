# generalized SGD framework

# Link and Loss functions are defined in SGD.julia

#--------------------------------------------------------# Type and Constructors
"""
`SGD(x, y, wgt; link, loss, reg, start)`

Generic type for stochastic gradient descent algorithms.

Keyword arguments are:

- `link`: link function (`IdentityLink()`, `LogisticLink()`)
- `loss`: loss function (`SquareLoss()`, `LogisticLoss()`, `QuantileLoss(τ)`)
- `reg`: regularizer/penalty (`NoReg`, `L1Reg`, `L2Reg`)
- `start`: starting value (defaults to zeros)
"""
type SGD{LINK<:LinkFunction, LOSS<:LossFunction, REG<:RegularizationFunction} <: OnlineStat
    β::VecF
    link::LINK
    loss::LOSS
    reg::REG
    weighting::StochasticWeighting
    n::Int
end

function SGD(p::Integer, wgt::StochasticWeighting = StochasticWeighting();
             link::LinkFunction = IdentityLink(),
             loss::LossFunction = SquareLoss(),
             reg::RegularizationFunction = NoReg(),
             start::VecF = zeros(p))
    SGD(start, link, loss, reg, wgt, 0)
end

function SGD(X::AMatF, y::AVecF, wgt::StochasticWeighting = StochasticWeighting(); kwargs...)
    o = SGD(ncols(X), wgt; kwargs...)
    update!(o, X, y)
    o
end


#---------------------------------------------------------------------# update!
function update!(o::SGD, x::AVecF, y::Float64)
    ε = y - predict(o, x)

    λ = weight(o)
    for j in 1:length(x)
        g = ∇f(o.loss, ε, x[j]) + ∇Ψ(o.reg, o.β, j)
        o.β[j] -= λ * g
    end

    o.n += 1
    nothing
end


@inline function _update_average_gradient!(o::SGD, x::AVecF, y::Float64, w::Float64)
    ε = y - predict(o, x)
    n2inv = @compat Float64(1 / length(x))
    for j in 1:length(x)
        g = ∇f(o.loss, ε, x[j]) + ∇Ψ(o.reg, o.β, j)
        o.β[j] -= w * g * n2inv
    end
    o.n += 1
    nothing
end

function updatebatch!(o::SGD, x::AMatF, y::AVecF)
    n2 = length(y)
    λ = weight(o)

    for i in 1:n2
        _update_average_gradient!(o, row(x, i), y[i], λ)
    end
end


#-----------------------------------------------------------------------# state

state(o::SGD) = Any[copy(o.β), nobs(o)]
statenames(o::SGD) = [:β, :nobs]

StatsBase.coef(o::SGD) = o.β
StatsBase.predict(o::SGD, x::AVecF) = invlink(o.link, dot(x, o.β))
StatsBase.predict(o::SGD, X::AMatF) = invlink(o.link, X * o.β)
