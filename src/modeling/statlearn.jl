#-------------------------------------------------------------------------# StatLearn
type StatLearn{
        A <: Algorithm,
        M <: Model,
        P <: Penalty,
        W <: StochasticWeight
    } <: OnlineStat{XYInput}

    β0::Float64     # intercepts
    β::VecF         # coefficients, β[:, i] = βᵢ
    intercept::Bool # should β0 be estimated?
    η::Float64      # constant part of learning rate

    # Storage
    H0::Float64
    G0::Float64
    H::VecF
    G::VecF

    algorithm::A    # determines how updates work
    model::M        # model definition
    penalty::P      # type of penalty
    weight::W       # Weight, may not get used, depending on algorithm
end
function _StatLearn(p::Integer, wgt::Weight;
        model::Model = L2Regression(),
        eta::Real = 1.0,
        penalty::Penalty = NoPenalty(),
        algorithm::Algorithm = SGD(),
        intercept::Bool = true,
    )
    o = StatLearn(0.0, zeros(p), intercept, Float64(eta), _ϵ, _ϵ,
        _ϵ * ones(p), _ϵ * ones(p), algorithm, model, penalty, wgt)
    o
end
function StatLearn(p::Integer, args...; kw...)
    wgt = LearningRate()
    mod = LinearRegression()
    alg = SGD()
    pen = NoPenalty()
    for arg in args
        T = typeof(arg)
        if T <: Weight
            wgt = arg
        elseif T <: Model
            mod = arg
        elseif T <: Algorithm
            alg = arg
        elseif T <: Penalty
            pen = arg
        end
    end
    _StatLearn(p, wgt; model = mod, algorithm = alg, penalty = pen, kw...)
end
function StatLearn(x::AMat, y::AVec, args...; kw...)
    o = StatLearn(size(x, 2), args...;kw...)
    fit!(o, x, y)
end
function StatLearn(x::AMat, y::AVec, b::Integer, args...; kw...)
    o = StatLearn(size(x, 2), args...; kw...)
    fit!(o, x, y, b)
    o
end



function Base.show(io::IO, o::StatLearn)
    printheader(io, "StatLearn")
    o.intercept && print_item(io, "Intercept", o.β0)``
    print_item(io, "β", o.β)
    print_item(io, "Model", o.model)
    print_item(io, "Penalty", o.penalty)
    print_item(io, "Algorithm", o.algorithm)
    print_item(io, "η", o.η)
    print_item(io, "Weight", typeof(o.weight))
    print_item(io, "Nobs", nobs(o))
end

coef(o::StatLearn) = o.intercept ? vcat(o.β0, o.β) : o.β
predict(o::StatLearn, x) = predict(o.model, xβ(o, x))
classify(o::StatLearn, x) = classify(o.model, xβ(o, x))

xβ(o::StatLearn, x::AVec) = o.β0 + dot(o.β, x)
xβ(o::StatLearn, x::AMat) = o.β0 + x * o.β

loss(o::StatLearn, x::AVec, y::Real) = loss(o.model, y, xβ(o, x))
loss(o::StatLearn, x::AMat, y::AVec) = loss(o.model, y, xβ(o, x))
cost(o::StatLearn, x::AVec, y::Real) = loss(o.model, y, xβ(o, x)) + penalty(o.penalty, o.β)
cost(o::StatLearn, x::AMat, y::AVec) = loss(o.model, y, xβ(o, x)) + penalty(o.penalty, o.β)







#-------------------------------------------------------------------------------# SGD
immutable SGD <: Algorithm end
updateβ0!(o::StatLearn{SGD}, γ, ηγ, g, ηγg) = (o.β0 -= ηγg)
function updateβ!(o::StatLearn{SGD}, P, β, j, γ, ηγ, gx, ηγgx)
    @inbounds β[j] -= ηγ * (gx + deriv(P, β[j]))
end

#---------------------------------------------------------------------------# AdaGrad
immutable AdaGrad <: Algorithm end
function updateβ0!(o::StatLearn{AdaGrad}, γ, ηγ, g, ηγg)
    o.H0 = smooth(o.H0, g * g, 1 / nups(o.weight))
    o.β0 -= ηγg / sqrt(o.H0)
end
function updateβ!(o::StatLearn{AdaGrad}, P, β, j, γ, ηγ, gx, ηγgx)
    @inbounds o.H[j] = smooth(o.H[j], gx * gx, 1 / nups(o.weight))
    @inbounds step = ηγ / sqrt(o.H[j])
    @inbounds β[j] = prox(P, β[j] - step * gx, step)
end

#--------------------------------------------------------------------------# AdaGrad2
immutable AdaGrad2 <: Algorithm end
function updateβ0!(o::StatLearn{AdaGrad2}, γ, ηγ, g, ηγg)
    o.H0 = smooth(o.H0, g * g, γ)
    o.β0 -= ηγg / sqrt(o.H0)
end
function updateβ!(o::StatLearn{AdaGrad2}, P, β, j, γ, ηγ, gx, ηγgx)
    @inbounds o.H[j] = smooth(o.H[j], gx * gx, γ)
    @inbounds step = ηγ / sqrt(o.H[j])
    @inbounds β[j] = prox(P, β[j] - step * gx, step)
end

#--------------------------------------------------------------------------# AdaDelta
immutable AdaDelta <: Algorithm
    ρ::Float64
    AdaDelta(ρ::Real = .001) = new(ρ)
end
function updateβ0!(o::StatLearn{AdaDelta}, γ, ηγ, g, ηγg)
    o.H0 = smooth(o.H0, g * g, o.algorithm.ρ)
    Δ = sqrt(o.G0 / o.H0) * g
    o.β0 -= Δ
    o.G0 = smooth(o.G0, Δ * Δ, o.algorithm.ρ)
end
function updateβ!(o::StatLearn{AdaDelta}, P, β, j, γ, ηγ, gx, ηγgx)
    @inbounds o.H[j] = smooth(o.H[j], gx * gx, o.algorithm.ρ)
    @inbounds step = sqrt(o.G[j] / o.H[j])
    @inbounds β[j] = prox(P, β[j] - step * gx, step)
    Δ = step * gx
    @inbounds o.G[j] = smooth(o.G[j], Δ * Δ, o.algorithm.ρ)
end

#------------------------------------------------------------------------------# ADAM
immutable ADAM <: Algorithm
    m1::Float64
    m2::Float64
    ADAM(m1::Real = .01, m2::Real = .01) = new(m1, m2)
end
function updateβ0!(o::StatLearn{ADAM}, γ, ηγ, g, ηγg)
    m1, m2, nups = o.algorithm.m1, o.algorithm.m2, o.weight.nups
    ratio = sqrt(1.0 - m2 ^ nups) / (1.0 - m1 ^ nups)
    o.H0 = smooth(o.H0, g, m1)
    o.G0 = smooth(o.G0, g * g, m2)
    o.β0 -= ηγ * ratio * o.H0 / sqrt(o.G0)
end
function updateβ!(o::StatLearn{ADAM}, P, β, j, γ, ηγ, gx, ηγgx)
    m1, m2, nups = o.algorithm.m1, o.algorithm.m2, o.weight.nups
    ratio = sqrt(1.0 - m2 ^ nups) / (1.0 - m1 ^ nups)
    @inbounds o.H[j] = smooth(o.H[j], gx, m1)
    @inbounds o.G[j] = smooth(o.G[j], gx * gx, m2)
    @inbounds step = ηγ * ratio / sqrt(o.G[j])
    @inbounds β[j] = prox(P, β[j] - step * o.H[j], step)
end

#--------------------------------------------------------------------------# Momentum
immutable Momentum <: Algorithm
    α::Float64
    Momentum(α::Real = .1) = new(α)
end
function updateβ0!(o::StatLearn{Momentum}, γ, ηγ, g, ηγg)
    o.H0 = smooth(o.H0, g, o.algorithm.α)
    o.β0 -= ηγ * o.H0
end
function updateβ!(o::StatLearn{Momentum}, P, β, j, γ, ηγ, gx, ηγgx)
    @inbounds o.H[j] = smooth(o.H[j], gx, o.algorithm.α)
    @inbounds β[j] -= ηγ * o.H[j]
    @inbounds β[j] -= ηγ * (gx + deriv(P, β[j]))
end



# #-------------------------------------------------------------------------------# OMM
# # Apparently this is equivalent to SGD...
# immutable OMM <: Algorithm end
# function updateβ0!(o::StatLearn{OMM}, γ, ηγ, g, ηγg)
#     o.H0 = smooth(o.H0, g, γ)
#     o.G0 = smooth(o.G0, o.β0, γ)
#     o.β0 = o.G0 - o.η * o.H0
# end
# function updateβ!(o::StatLearn{OMM}, β, j, γ, ηγ, gx, ηγgx)
#     @inbounds o.H[j] = smooth(o.H[j], gx, γ)
#     @inbounds o.G[j] = smooth(o.G[j], o.β[j], γ)
#     @inbounds β[j] = o.G[j] - o.η * o.H[j]
# end



#---------------------------------------------------------------------------# fitting
function _fit!{T <: Real}(o::StatLearn, x::AVec{T}, y::Real, γ::Float64)
    η, β, P = o.η, o.β, o.penalty
    ηγ = η * γ
    xb = dot(x, β) + o.β0
    g = lossderiv(o.model, y, xb)
    ηγg = ηγ * g
    if o.intercept
        updateβ0!(o, γ, ηγ, g, ηγg)
    end
    for j in eachindex(β)
        gx = g * x[j]
        ηγgx = ηγ * gx
        updateβ!(o, P, β, j, γ, ηγ, gx, ηγgx)
    end
    o
end

function _fitbatch!{T<:Real, S<:Real}(o::StatLearn, x::AMat{T}, y::AVec{S}, γ::Float64)
    η, β, P = o.η, o.β, o.penalty
    ηγ = η * γ
    xb = x * β
    gvec = zeros(size(x, 1))
    for i in eachindex(gvec)
        @inbounds gvec[i] = lossderiv(o.model, y[i], xb[i])
    end
    if o.intercept
        g = mean(gvec)
        ηγg = ηγ * g
        updateβ0!(o, γ, ηγ, g, ηγg)
    end
    for j in eachindex(β)
        gx = batch_gx(sub(x, :, j), gvec)
        ηγgx = ηγ * gx
        updateβ!(o, P, β, j, γ, ηγ, gx, ηγgx)
    end
    o
end
function batch_gx(xj::AVec, g::AVec)
    v = 0.0
    n = length(xj)
    for i in eachindex(xj)
        @inbounds v += xj[i] * g[i]
    end
    v / n
end


"""
`fit!` and update the tuning parameter for a `StatLearn` object.

`cvfit!(o::StatLearn, x, y, xtest, ytest)`

For regularization parameter `λ` and next weight `γ`, the updated `λ` will be one of:

- `λ + γ`
- `λ`
- `max(λ - γ, 0)`

The choice depends on which results in the smallest loss on the test set `(xtest, ytest)`.
"""
function cvfit!(o::StatLearn, x, y, xtest, ytest, arg = 1)
    @assert typeof(o.penalty) != NoPenalty
    γ = weight(o, size(x, 1))
    h = copy(o); h.penalty = typeof(h.penalty)(o.penalty.λ + γ)
    l = copy(o); l.penalty = typeof(l.penalty)(max(o.penalty.λ - γ, 0.0))
    fit!(h, x, y, arg)
    fit!(o, x, y, arg)
    fit!(l, x, y, arg)
    loss_h = loss(h, xtest, ytest)
    loss_o = loss(o, xtest, ytest)
    loss_l = loss(l, xtest, ytest)
    lossmin = minimum([loss_h, loss_o, loss_l])
    loss_l == lossmin && _copy!(o, l)
    loss_h == lossmin && _copy!(o, h)
    o
end
function _copy!(o::StatLearn, o2::StatLearn)
    o.β0 = o2.β0
    o.β[:] = o2.β
    o.penalty = o2.penalty
end
