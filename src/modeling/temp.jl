abstract Algorithm






abstract Model
abstract BivariateModel <: Model  # LogisticRegression and SVMLike
# function Base.show(io::IO, m::Model)
#     s = string(typeof(m))
#     s = replace(s, "SparseRegression.", "")
#     print(s)
# end

# ====================================================================# Model methods
function lossvector!(m::Model, storage::Vector, y::Vector, η::Vector)
    for i in eachindex(y)
        @inbounds storage[i] = loss(m, y[i], η[i])
    end
end
function loss(m::Model, y::Vector, η::Vector)
    storage = zeros(length(y))
    lossvector!(m, storage, y, η)
    mean(storage)
end
function predict!(m::Model, storage::Vector, η::Vector)
    for i in eachindex(η)
        @inbounds storage[i] = predict(m, η[i])
    end
end
function predict(m::Model, η::Vector)
    storage = zeros(length(η))
    predict!(m, storage, η)
    storage
end
function classify!(m::BivariateModel, storage::Vector, η::Vector)
    for i in eachindex(η)
        @inbounds storage[i] = classify(m, η[i])
    end
end


#------------------------------------------------------------------# LinearRegression
immutable LinearRegression <: Model end
loss(m::LinearRegression, y::Real, η::Real) = 0.5 * (y - η) ^ 2
lossderiv(m::LinearRegression, y::Real, η::Real) = -(y - η)
predict(m::LinearRegression, η::Real) = η

#----------------------------------------------------------------------# L1Regression
immutable L1Regression <: Model end
loss(m::L1Regression, y::Real, η::Real) = abs(y - η)
lossderiv(m::L1Regression, y::Real, η::Real) = -sign(y - η)
predict(m::L1Regression, η::Real) = η

#----------------------------------------------------------------# LogisticRegression
"For data in {0, 1}"
immutable LogisticRegression <: BivariateModel end
loss(m::LogisticRegression, y::Real, η::Real) = -y * η + log(1.0 + exp(η))
lossderiv(m::LogisticRegression, y::Real, η::Real) = -(y - predict(m, η))
predict(m::LogisticRegression, η::Real) = 1.0 / (1.0 + exp(-η))
classify(m::LogisticRegression, η::Real) = Float64(η > 0.0)

#------------------------------------------------------------------# ProbitRegression
# TODO
# "For data in {0, 1}"
# immutable ProbitRegression <: BivariateModel end
# d = Ds.Normal()
# function loss(m::ProbitRegression, y::Real, η::Real)
#     -y * Ds.logcdf(d, η) - (1 - y) * Ds.logccdf(d, η)
# end
# loglikelihood(m::ProbitRegression, y::Real, η::Real) = -loss(m, y, η)
# function lossderiv(m::ProbitRegression, y::Real, η::Real)
#     (y - Ds.logcdf(d, η)) * Ds.pdf(η) / (Ds.cdf(d, η) * Ds.ccdf(d, η))
# end
# predict(m::ProbitRegression, η::Real) = Ds.cdf(d, η)
# classify(m::ProbitRegression, η::Real) = Float64(η > 0.0)


#----------------------------------------------------------------# PoissonRegression
immutable PoissonRegression <: Model end
loss(m::PoissonRegression, y::Real, η::Real) = -y * η + exp(η)
lossderiv(m::PoissonRegression, y::Real, η::Real) = -y + exp(η)
predict(m::PoissonRegression, η::Real) = exp(η)

#---------------------------------------------------------------------------# SVMLike
"For data in {-1, 1}"
immutable SVMLike <: BivariateModel end
loss(m::SVMLike, y::Real, η::Real) = max(0.0, 1.0 - y * η)
lossderiv(m::SVMLike, y::Real, η::Real) = 1.0 < y * η ? 0.0 : -y
predict(m::SVMLike, η::Real) = η
classify(m::SVMLike, η::Real) = sign(η)

#----------------------------------------------------------------# QuantileRegression
immutable QuantileRegression <: Model τ::Float64 end
function loss(m::QuantileRegression, y::Real, η::Real)
    r = y - η
    r * (m.τ - (r < 0.0))
end
lossderiv(m::QuantileRegression, y::Real, η::Real) = (y < η) - m.τ
predict(m::QuantileRegression, η::Real) = η

#-------------------------------------------------------------------# HuberRegression
immutable HuberRegression <: Model δ::Float64 end
function loss(m::HuberRegression, y::Real, η::Real)
    r = y - η
    abs(r) < m.δ ? 0.5 * r * r : m.δ * (abs(r) - 0.5 * m.δ)
end
function lossderiv(m::HuberRegression, y::Real, η::Real)
    r = y - η
    abs(r) <= m.δ ? -r : m.δ * sign(-r)
end
predict(m::HuberRegression, η::Real) = η







abstract Penalty
# New Penalties need a:
#   - Constructor
#   - one line show method
#   - penalty method
#   - prox method prox_{s * λ * penalty}(βj)
#------------------------------------------------------------------# abstract methods
# c = step * λ (step size * regularization parameter)
function prox!(p::Penalty, β::VecF, c::Float64)
    for j in eachindex(β)
        @inbounds β[j] = prox(p, β[j], c)
    end
end
# if λs are not constant
function prox!(p::Penalty, β::VecF, c::VecF)
    for j in eachindex(β)
        @inbounds β[j] = prox(p, β[j], c[j])
    end
end

#-------------------------------------------------------------------------# NoPenalty
immutable NoPenalty <: Penalty end
Base.show(io::IO, p::NoPenalty) = print(io, "NoPenalty")
penalty(p::NoPenalty, β::VecF, λ::Float64) = 0.0
prox(p::NoPenalty, βj::Float64, c::Float64) = βj
deriv(p::NoPenalty, βj::Float64, λ::Float64) = 0.0

#----------------------------------------------------------------------# RidgePenalty
immutable RidgePenalty <: Penalty end
Base.show(io::IO, p::RidgePenalty) = print(io, "RidgePenalty")
penalty(p::RidgePenalty, β::VecF, λ::Float64) = 0.5 * λ * sumabs2(β)
prox(p::RidgePenalty, βj::Float64, c::Float64) = βj / (1.0 + c)
deriv(p::RidgePenalty, βj::Float64, λ::Float64) = λ * βj

#----------------------------------------------------------------------# LassoPenalty
immutable LassoPenalty <: Penalty end
Base.show(io::IO, p::LassoPenalty) = print(io, "LassoPenalty")
penalty(p::LassoPenalty, β::VecF, λ::Float64) = λ * sumabs(β)
prox(p::LassoPenalty, βj::Float64, c::Float64) = sign(βj) * max(abs(βj) - c, 0.0)
deriv(p::LassoPenalty, βj::Float64, λ::Float64) = λ * sign(βj)

#-----------------------------------------------------------------# ElasticNetPenalty
immutable ElasticNetPenalty <: Penalty
    a::Float64
    function ElasticNetPenalty(a::Real = .5)
        @assert a != 0 "Use RidgePenalty instead"
        @assert a != 1 "Use LassoPenalty instead"
        @assert 0 < a < 1
        new(a)
    end
end
Base.show(io::IO, p::ElasticNetPenalty) = print(io, "ElasticNetPenalty (α = $(p.a))")
function penalty(p::ElasticNetPenalty, β::VecF, λ::Float64)
    λ * (p.a * sumabs(β) + (1. - p.a) * 0.5 * sumabs2(β))
end
function prox(p::ElasticNetPenalty, βj::Float64, c::Float64)
    sign(βj) * max(abs(βj) - c * p.a, 0.0) / (1.0 + c * (1.0 - p.a))
end
function deriv(p::ElasticNetPenalty, βj::Float64, λ::Float64)
    p.a * deriv(LassoPenalty(), βj, λ) + (1 - p.a) * deriv(RidgePenalty(), βj, λ)
end

#----------------------------------------------------------------------# SCADPenalty
# TODO
# immutable SCADPenalty <: Penalty
#     a::Float64
#     function SCADPenalty(a::Real = 3.7)
#         @assert a > 2
#         new(a)
#     end
# end
# Base.show(io::IO, p::SCADPenalty) = print(io, "SCADPenalty (a = $(p.a))")
# function penalty(p::SCADPenalty, β::VecF, λ::Float64)
#     val = 0.0
#     for j in eachindex(β)
#         βj = abs(β[j])
#         if βj < λ
#             val += λ * βj
#         elseif βj < λ * p.a
#             val -= 0.5 * (βj ^ 2 - 2.0 * p.a * λ * βj + λ ^ 2) / (p.a - 1.0)
#         else
#             val += 0.5 * (p.a + 1.0) * λ ^ 2
#         end
#     end
#     return val
# end
# function prox(p::SCADPenalty, βj::Float64, c::Float64)
#     if abs(βj) > p.a * c
#     elseif abs(βj) < 2.0 * c
#         βj = sign(βj) * max(abs(βj) - c, 0.0)
#     else
#         βj = (βj - c * sign(βj) * p.a / (p.a - 1.0)) / (1.0 - (1.0 / p.a - 1.0))
#     end
#     βj
# end











#--------------------------------------------------------------------# sweep! methods
"""
`sweep!(A, k, inv = false)`, `sweep!(A, k, v, inv = false)`

Symmetric sweep operator of the matrix `A` on element `k`.  `A` is overwritten.
`inv = true` will perform the inverse sweep.  Only the upper triangle is read and swept.

An optional vector `v` can be provided to avoid memory allocation.
This requires `length(v) == size(A, 1)`.  Both `A` and `v`
will be overwritten.

```julia
x = randn(100, 10)
xtx = x'x
sweep!(xtx, 1)
sweep!(xtx, 1, true)
```
"""
function sweep!{T<:Real}(A::AMat{T}, k::Integer, inv::Bool = false)
    n, p = size(A)
    # ensure @inbounds is safe
    @assert n == p "A must be square"
    @assert k <= p "pivot element not within range"
    @inbounds d = 1.0 / A[k, k]  # pivot
    # get column A[:, k] (hack because only upper triangle is available)
    akk = zeros(p)
    for j in 1:p
        if j <= k
            @inbounds akk[j] = A[j, k]
        else
            @inbounds akk[j] = A[k, j]
        end
    end
    BLAS.syrk!('U', 'N', -d, akk, 1.0, A)  # everything not in col/row k
    scale!(akk, d * (-1) ^ inv)
    for i in 1:k-1  # col k
        @inbounds A[i, k] = akk[i]
    end
    for j in k+1:p  # row k
        @inbounds A[k, j] = akk[j]
    end
    A[k, k] = -d  # pivot element
    A
end

function sweep!{T<:Real, I<:Integer}(A::AMat{T}, ks::AVec{I}, inv::Bool = false)
    for k in ks
        sweep!(A, k, inv)
    end
    A
end



function sweep!{T<:Real}(A::AMat{T}, k::Integer, v::AVecF, inv::Bool = false)
    n, p = size(A)
    # ensure that @inbounds is safe
    @assert n == p "A must be square"
    @assert length(v) == p "storage length ≠ size(A, 1)"
    @assert k <= p "pivot element not within range"
    @inbounds d = 1.0 / A[k, k]  # pivot
    for j in 1:p   # get column A[:, k]
        if j <= k
            @inbounds v[j] = A[j, k]
        else
            @inbounds v[j] = A[k, j]
        end
    end
    BLAS.syrk!('U', 'N', -d, v, 1.0, A)  # everything not in col/row k
    scale!(v, d * (-1) ^ inv)
    for i in 1:k-1  # col k
        @inbounds A[i, k] = v[i]
    end
    for j in k+1:p  # row k
        @inbounds A[k, j] = v[j]
    end
    @inbounds A[k, k] = -d  # pivot element
    A
end

function sweep!{T<:Real,I<:Integer}(A::AMat{T}, ks::AVec{I}, v::VecF, inv::Bool = false)
    for k in ks
        sweep!(A, k, v, inv)
    end
    A
end
