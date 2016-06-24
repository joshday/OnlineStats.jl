using SparseRegression

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
    λ::Float64      # lambdas to use
    H0::Float64     # "second order" info for intercept
    H::VecF         # diagonal matrix of "second order" info
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
        lambda::Float64 = 0.0
    )
    o = StatLearn(
        0.0, zeros(p), intercept, eta, lambda, 1.0, ones(p), algorithm, model,
        penalty, wgt
    )
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
    # TODO
    printheader(io, "StatLearn")
    o.intercept && print_item(io, "Bias", o.β0)
    print_item(io, "β", o.β)
    print_item(io, "Model", o.model)
    print_item(io, "Penalty", o.penalty)
    print_item(io, "λ", o.λ)
    print_item(io, "Algorithm", o.algorithm)
    print_item(io, "η", o.η)
    print_item(io, "Intercept", o.intercept)
    print_item(io, "Weight", typeof(o.weight))
    print_item(io, "Nobs", nobs(o))
end
coef(o::StatLearn) = o.intercept ? vcat(o.β0, o.β) : o.β

xβ(o::StatLearn, x::AVec) = o.β0 + dot(o.β, x)
xβ(o::StatLearn, x::AMat) = o.β0 + x * o.β

loss(o::StatLearn, x::AVec, y::Real) = loss(o.model, y, xβ(o))
loss(o::StatLearn, x::AMat, y::AVec) = loss(o.model, y, xβ(o))
cost(o::StatLearn, x::AVec, y::Real) = loss(o.model, y, xβ(o)) + Sp.penalty(o.penalty, o.β)
cost(o::StatLearn, x::AMat, y::AVec) = loss(o.model, y, xβ(o)) + Sp.penalty(o.penalty, o.β)


penalty_adjust!(::Algorithm, P, λ, β, ηγ) = Sp.prox!(P, β, ηγ * λ)
#-------------------------------------------------------------------------------# SGD
immutable SGD <: Algorithm end
update_β0!(o::StatLearn{SGD}, ηγ, g, ηγg) = (o.β0 -= ηγg)
function update_H!(o::StatLearn{SGD}, H, j, g, hγ) end
gradient_update!(::SGD, β, H, j, ηγg) = (@inbounds β[j] -= ηγg)
function penalty_adjust!(::SGD, P, λ, β, ηγ)
    for j in eachindex(β)
        @inbounds β[j] += ηγ * Sp.deriv(P, β[j], λ)
    end
end
#---------------------------------------------------------------------------# AdaGrad
immutable AdaGrad <: Algorithm end
function update_β0!(o::StatLearn{AdaGrad}, ηγ, g, ηγg)
    o.H0 = smooth(o.H0, g * g, 1 / nups(o.weight))
    o.β0 -= ηγg / sqrt(o.H0)
end
function update_H!(o::StatLearn{AdaGrad}, H, j, g, γ)
    @inbounds H[j] = smooth(H[j], g * g, 1 / nups(o.weight))
end
function gradient_update!(::AdaGrad, β, H, j, ηγg)
    @inbounds β[j] -= ηγg / sqrt(H[j])
end
#--------------------------------------------------------------------------# AdaGrad2
immutable AdaGrad2 <: Algorithm end
function update_β0!(o::StatLearn{AdaGrad2}, ηγ, g, ηγg)
    o.H0 = smooth(o.H0, g * g, 1 / nups(o.weight))
    o.β0 -= ηγg / sqrt(o.H0)
end
function update_H!(o::StatLearn{AdaGrad2}, H, j, g, γ)
    @inbounds H[j] = smooth(H[j], g * g, γ)
end
function gradient_update!(::AdaGrad2, β, H, j, ηγg)
    @inbounds β[j] -= ηγg / sqrt(H[j])
end




#---------------------------------------------------------------------------# fitting
function _fit!{T <: Real}(o::StatLearn, x::AVec{T}, y::Real, γ::Float64)
    β, H, A, M, P = o.β, o.H, o.algorithm, o.model, o.penalty
    @assert length(β) == length(x) "Wrong dimensions"
    ηγ = o.η * γ
    xb = dot(x, β) + o.β0
    g = SparseRegression.lossderiv(M, y, xb)
    ηγg = ηγ * g
    if o.intercept
        update_β0!(o, ηγ, g, ηγg)
    end
    for j in eachindex(β)
        Δ = ηγg * x[j]
        update_H!(o, H, j, g, γ)
        gradient_update!(A, β, H, j, Δ)
    end
    penalty_adjust!(A, P, o.λ, β, ηγ)
    o
end



function _fitbatch!{T<:Real, S<:Real}(o::StatLearn, x::AMat{T}, y::AVec{S}, γ::Float64)
    β, H, A, M, P = o.β, o.H, o.algorithm, o.model, o.penalty
    @assert length(β) == size(x, 2) "Wrong dimensions."
    ηγ = o.η * γ
    xb = x * β
    gvec = zeros(size(x, 1))
    for i in eachindex(gvec)
        @inbounds gvec[i] = SparseRegression.lossderiv(o.model, y[i], xb[i])
    end
    if o.intercept
        g = mean(gvec)
        ηγg = ηγ * g
        update_β0!(o, ηγ, g, ηγg)
    end
    for j in eachindex(β)
        g = batch_g(sub(x, :, j), gvec)
        update_H!(o, H, j, g, γ)
        gradient_update!(A, β, H, j, ηγ * g)
    end
    penalty_adjust!(A, P, o.λ, β, ηγ)
    o
end

function batch_g(xj::AVec, g::AVec)
    v = 0.0
    n = length(xj)
    for i in eachindex(xj)
        @inbounds v += xj[i] * g[i]
    end
    v / n
end
