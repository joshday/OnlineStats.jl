# Each type needs fields:
#   - value:    value of the statistic
#   - weight:   subtype of Weight
#   - n:        nobs
#   - nup:      n updates
#
# Each type needs to have:
#   - empty constructor
#   - StatsBase.fit! method
#
#-------------------------------------------------------------------------# Mean
type Mean{W <: Weight} <: OnlineStat
    value::Float64
    weight::W
    n::Int
    nup::Int
end
Mean(wgt::Weight = EqualWeight()) = Mean(0.0, wgt, 0, 0)
function fit!(o::Mean, y::Real)
    γ = weight!(o, 1)
    o.value = smooth(o.value, y, γ)
end
function fitbatch!{T <: Real}(o::Mean, y::AVec{T})
    γ = weight!(o, length(y))
    o.value = smooth(o.value, mean(y), γ)
end
Base.mean(o::Mean) = value(o)


#------------------------------------------------------------------------# Means
type Means{W <: Weight} <: OnlineStat
    value::VecF
    weight::W
    n::Int
    nup::Int
end
Means(p::Int, wgt::Weight = EqualWeight()) = Means(zeros(p), wgt, 0, 0)
function fit!{T <: Real}(o::Means, y::AVec{T})
    γ = weight!(o, 1)
    smooth!(o.value, y, γ)
end
function fitbatch!{T <: Real}(o::Means, y::AMat{T})
    γ = weight!(o, size(y, 1))
    smooth!(o.value, row(mean(y, 1), 1), γ)
end
Base.mean(o::Means) = value(o)


#---------------------------------------------------------------------# Variance
type Variance{W <: Weight} <: OnlineStat
    value::Float64
    μ::Float64
    weight::W
    n::Int
    nup::Int
end
Variance(wgt::Weight = EqualWeight()) = Variance(0.0, 0.0, wgt, 0, 0)
function fit!(o::Variance, y::Real)
    γ = weight!(o, 1)
    μ = o.μ
    o.μ = smooth(o.μ, y, γ)
    o.value = smooth(o.value, (y - o.μ) * (y - μ), γ)
end
Base.var(o::Variance) = value(o)
Base.std(o::Variance) = sqrt(var(o))
Base.mean(o::Variance) = o.μ
value(o::Variance) = o.value * _unbias(o)


#--------------------------------------------------------------------# Variances
type Variances{W <: Weight} <: OnlineStat
    value::VecF
    μ::VecF
    μold::VecF  # help avoid allocation in update
    weight::W
    n::Int
    nup::Int
end
function Variances(p::Integer, wgt::Weight = EqualWeight())
    Variances(zeros(p), zeros(p), zeros(p), wgt, 0, 0)
end
function fit!{T <: Real}(o::Variances, y::AVec{T})
    γ = weight!(o, 1)
    copy!(o.μold, o.μ)
    smooth!(o.μ, y, γ)
    for i in 1:length(y)
        o.value[i] = smooth(o.value[i], (y[i] - o.μ[i]) * (y[i] - o.μold[i]), γ)
    end
end
function fitbatch!{T <: Real}(o::Variances, y::AMat{T})
    n2 = size(y, 1)
    γ = weight!(o, n2)
    smooth!(o.μ, row(mean(y, 1), 1), γ)
    smooth!(o.value, row(var(y,1), 1) * ((n2 - 1) / n2), γ)
    return
end
Base.var(o::Variances) = value(o)
Base.std(o::Variances) = sqrt(value(o))
Base.mean(o::Variances) = o.μ
value(o::Variances) = o.value * _unbias(o)


#--------------------------------------------------------------------# CovMatrix
type CovMatrix{W <: Weight} <: OnlineStat
    value::MatF
    cormat::MatF
    A::MatF  # X'X / n
    B::VecF  # X * 1' / n (column means)
    weight::W
    n::Int
    nup::Int
end
function CovMatrix(p::Integer, wgt::Weight = EqualWeight())
    CovMatrix(zeros(p, p), zeros(p,p), zeros(p, p), zeros(p), wgt, 0, 0)
end
function fit!{T<:Real}(o::CovMatrix, x::AVec{T})
    γ = weight!(o, 1)
    for j in 1:size(o.A, 2), i in 1:j
        @inbounds o.A[i, j] = (1 - γ) * o.A[i, j] + γ * x[i] * x[j]
    end
    smooth!(o.B, x, γ)
end
function fitbatch!{T<:Real}(o::CovMatrix, x::AMat{T})
    n2 = size(x, 1)
    γ = weight!(o, n2)
    BLAS.syrk!('U', 'T', γ / n2, x, 1 - γ, o.A)
    smooth!(o.B, row(mean(x, 1), 1), γ)
end
function value(o::CovMatrix)
    copy!(o.value, _unbias(o) * (o.A - BLAS.syrk('U', 'N', 1.0, o.B)))
    _covfill!(o.value)
    o.value
end
function _covfill!(A::MatF)  # fill in lower triangle
    p = size(A, 1)
    for j in 1:p, i in j+1:p
        @inbounds A[i, j] = A[j, i]
    end
end
Base.mean(o::CovMatrix) = o.B
Base.cov(o::CovMatrix) = value(o)
Base.var(o::CovMatrix) = diag(value(o))
Base.std(o::CovMatrix) = [sqrt(x) for x in var(o) ]
function Base.cor(o::CovMatrix)
    copy!(o.cormat, value(o))
    v = 1.0 ./ sqrt(diag(o.cormat))
    scale!(o.cormat, v)
    scale!(v, o.cormat)
    o.cormat
end



#----------------------------------------------------------------------# Extrema
# Weight gets ignored for Extrema
type Extrema <: OnlineStat
    min::Float64
    max::Float64
    n::Int
    nup::Int
end
Extrema(wgt::Weight = EqualWeight()) = Extrema(Inf, -Inf, 0, 0)
function Extrema{T<:Real}(y::AVec{T}, wgt::Weight = EqualWeight())
    Extrema(minimum(y), maximum(y), length(y), 1)
end
function fit!(o::Extrema, y::Real)
    n_and_nup!(o, 1)
    o.min = min(o.min, y)
    o.max = max(o.max, y)
end
Base.extrema(o::Extrema) = (o.min, o.max)
value(o::Extrema) = extrema(o)



#------------------------------------------------------------------# QuantileSGD
type QuantileSGD{W <: Weight} <: OnlineStat
    value::VecF
    τ::VecF
    weight::W
    n::Int
    nup::Int
end
function QuantileSGD(wgt::Weight = LearningRate();
        tau::VecF = [0.25, 0.5, 0.75], value::VecF = zeros(length(tau))
    )
    @inbounds for i in 1:length(tau)
        @assert 0 < tau[i] < 1
    end
    QuantileSGD(value, tau, wgt, 0, 0)
end
function fit!(o::QuantileSGD, y::Float64)
    γ = weight!(o, 1)
    @inbounds for i in 1:length(o.τ)
        v = Float64(y < o.value[i]) - o.τ[i]
        o.value[i] = subgrad(o.value[i], γ, v)
    end
end
function fitbatch!{T <: Real}(o::QuantileSGD, y::AVec{T})
    n2 = length(y)
    γ = weight!(o, n2) / n2
    @inbounds for yi in y
        for i in 1:length(o.τ)
            v = Float64(yi < o.value[i]) - o.τ[i]
            o.value[i] = subgrad(o.value[i], γ, v)
        end
    end
end
function Base.show(io::IO, o::QuantileSGD)
    printheader(io, "QuantileSGD, τ = $(o.τ)")
    print_value_and_nobs(io, o)
end


#------------------------------------------------------------------# QuantileMM
type QuantileMM{W <: Weight} <: OnlineStat
    value::VecF
    τ::VecF

    s::VecF
    t::VecF
    o::Float64

    weight::W
    n::Int
    nup::Int
end
function QuantileMM(wgt::Weight = LearningRate();
        tau::VecF = [0.25, 0.5, 0.75], value::VecF = zeros(length(tau))
    )
    p = length(tau)
    for i in 1:p
        @assert 0 < tau[i] < 1
    end
    QuantileMM(value, tau, zeros(p), zeros(p), 0.0, wgt, 0, 0)
end
function fit!(o::QuantileMM, y::Float64)
    γ = weight!(o, 1)
    o.o = smooth(o.o, 1.0, γ)
    @inbounds for j in 1:length(o.τ)
        w::Float64 = 1.0 / (abs(y - o.value[j]) + _ϵ)
        o.s[j] = smooth(o.s[j], w * y, γ)
        o.t[j] = smooth(o.t[j], w, γ)
        o.value[j] = (o.s[j] + o.o * (2.0 * o.τ[j] - 1.0)) / o.t[j]
    end
end
function fitbatch!{T <: Real}(o::QuantileMM, y::AVec{T})
    n2 = length(y)
    γ = weight!(o, n2) / n2
    o.o = smooth(o.o, 1.0, γ)
    @inbounds for yi in y
        for j in 1:length(o.τ)
            w::Float64 = 1.0 / abs(yi - o.value[j])
            o.s[j] = smooth(o.s[j], w * yi, γ)
            o.t[j] = smooth(o.t[j], w, γ)
        end
    end
    @inbounds for j in 1:length(o.τ)
        o.value[j] = (o.s[j] + o.o * (2.0 * o.τ[j] - 1.0)) / o.t[j]
    end
end
function Base.show(io::IO, o::QuantileMM)
    printheader(io, "QuantileMM, τ = $(o.τ)")
    print_value_and_nobs(io, o)
end

#----------------------------------------------------------------------# Moments
type Moments{W <: Weight} <: OnlineStat
    value::VecF
    weight::W
    n::Int
    nup::Int
end
Moments(wgt::Weight = EqualWeight()) = Moments(zeros(4), wgt, 0, 0)
@inbounds function fit!(o::Moments, y::Real)
    γ = weight!(o, 1)
    o.value[1] = smooth(o.value[1], y, γ)
    o.value[2] = smooth(o.value[2], y * y, γ)
    o.value[3] = smooth(o.value[3], y * y * y, γ)
    o.value[4] = smooth(o.value[4], y * y * y * y, γ)
end
Base.mean(o::Moments) = value(o)[1]
Base.var(o::Moments) = (value(o)[2] - value(o)[1] ^ 2) * _unbias(o)
Base.std(o::Moments) = sqrt(var(o))
function StatsBase.skewness(o::Moments)
    v = value(o)
    (v[3] - 3.0 * v[1] * var(o) - v[1] ^ 3) / var(o) ^ 1.5
end
function StatsBase.kurtosis(o::Moments)
    v = value(o)
    (v[4] - 4.0 * v[1] * v[3] + 6.0 * v[1]^2 * v[2] - 3.0 * v[1] ^ 4) / var(o) ^ 2 - 3.0
end
function Base.show(io::IO, o::Moments)
    printheader(io, "Moments")
    print_item(io, "mean", mean(o))
    print_item(io, "var", var(o))
    print_item(io, "skewness", skewness(o))
    print_item(io, "kurtosis", kurtosis(o))
    print_item(io, "nobs", nobs(o))
end


#---------------------------------------# convenience constructors and Base.show
# constructors
for nm in [:Mean, :Variance, :QuantileSGD, :QuantileMM, :Moments]
    eval(parse(
        """
        function $nm{T <: Real}(y::AVec{T}, wgt::Weight = EqualWeight())
            o = $nm(wgt)
            fit!(o, y)
            o
        end
        """
    ))
end

for nm in [:Means, :Variances, :CovMatrix]
    eval(parse(
        """
        function $nm{T <: Real}(y::AMat{T}, wgt::Weight = EqualWeight())
            o = $nm(size(y, 2), wgt)
            fit!(o, y, size(y, 1))
            o
        end
        """
    ))
end

# Base.show
for nm in [:Mean, :Variance, :Extrema, :Means, :Variances, :CovMatrix]
    eval(parse(
        """
        function Base.show(io::IO, o::$nm)
            printheader(io, "$nm")
            print_value_and_nobs(io, o)
        end
        """
    ))
end
