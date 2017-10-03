#--------------------------------------------------------------------# QuantileSGD
struct QuantileSGD <: OnlineStat{0, 1, LearningRate}
    value::VecF
    τ::VecF
    function QuantileSGD(τ::VecF = [0.25, 0.5, 0.75])
        Base.depwarn("QuantileSGD is deprecated.  Use Quantiles{:SGD} instead.", :QuantileSGD)
        new(zeros(τ), τ)
    end
    QuantileSGD(args...) = QuantileSGD(collect(args))
end
function fit!(o::QuantileSGD, y::Float64, γ::Float64)
    for i in eachindex(o.τ)
        @inbounds o.value[i] -= γ * deriv(QuantileLoss(o.τ[i]), y, o.value[i])
    end
end
function Base.merge!(o::QuantileSGD, o2::QuantileSGD, γ::Float64)
    o.τ == o2.τ || throw(ArgumentError("objects track different quantiles"))
    smooth!(o.value, o2.value, γ)
end
