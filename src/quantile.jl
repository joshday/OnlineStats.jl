mutable struct Quantile{U <: Updater} <: OnlineStat{0, LearningRate}
    value::Vector{Float64}
    τ::Vector{Float64}
    updater::U
end

function τ_check(τ)
    all(0 .< τ .< 1) || error("τ values must be in (0, 1)")
    return τ
end

Quantile(τ = [.25, .5, .75]) = Quantile{OMAS}(zeros(τ), τ, OMAS(zeros(τ), zeros(τ)))

Quantile(u::Updater, τ = [.25, .5, .75]) = Quantile(zeros(τ), τ, u)
Quantile(u::OMAS,    τ = [.25, .5, .75]) = Quantile(zeros(τ), τ, OMAS(zeros(τ), zeros(τ)))

Base.show(io::IO, o::Quantile) = print(io, "Quantile($(o.updater), $(o.τ)) = $(o.value)")


#-----------------------------------------------------------------------# fit!
function fit!(o::Quantile, y::Real, γ::Float64)
    γ == 1.0 && fill!(o.value, y)  # initialize values with first observation
    fit_by_updater!(o, y, γ)
end

# SGD
function fit_by_updater!(o::Quantile{SGD}, y::Real, γ::Float64)
    o.value .-= γ .* deriv.(QuantileLoss.(o.τ), y, o.value)
end

# MSPI
function fit_by_updater!(o::Quantile{MSPI}, y::Real, γ::Float64)
    @inbounds for i in eachindex(o.τ)
        w = inv(abs(y - o.value[i]) + ϵ)
        b = o.τ[i] - .5 * (1 - y * w)
        o.value[i] = (o.value[i] + γ * b) / (1 + .5 * γ * w)
    end
end

# OMAS
function fit_by_updater!(o::Quantile{<:OMAS}, y::Real, γ::Float64)
    (s, t) = o.updater.suffvalues
    @inbounds for j in 1:length(o.τ)
        w = 1.0 / (abs(y - o.value[j]) + ϵ)
        s[j] = smooth(s[j], w * y, γ)
        t[j] = smooth(t[j], w, γ)
        o.value[j] = (s[j] + (2o.τ[j] - 1)) / t[j]
    end
end


function Base.merge!(o::Quantile, o2::Quantile, γ::Float64)
    o.updater == o2.updater || warn("Merging Quantiles with different updaters")
    o.τvec == o2.τvec       || error("Objects track different quantiles")
    smooth!(o.value, o2.value, γ)
end
