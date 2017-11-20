abstract type Updater end

abstract type SGUpdater <: Updater end

Base.show(io::IO, u::Updater) = print(io, name(u, false, false))
Base.merge!(o::T, o2::T, γ::Float64) where {T <: Updater} = warn("$T can't be merged.")

init(u::Updater, p) = error("")


#-----------------------------------------------------------------------# SGD
"""
    SGD()

``\\theta^{(t)} = \\theta^{(t-1)} - \\gamma_t \\nabla \\ell_t(\\theta^{(t-1)})``

Stochastic gradient descent.
"""
struct SGD <: SGUpdater end
Base.merge!(a::SGD, b::SGD, γ::Float64) = a

#-----------------------------------------------------------------------# NSGD
"""
    NSGD(α)

Nesterov accelerated Proximal Stochastic Gradient Descent.
"""
struct NSGD <: SGUpdater
    α::Float64
    v::VecF
    θ::VecF
    NSGD(α = 0.0, p = 0) = new(α, zeros(p), zeros(p))
end
function Base.merge!(o::NSGD, o2::NSGD, γ::Float64)
    o.α == o2.α || error("Merge Failed.  NSGD objects use different α.")
    smooth!(o.v, o2.v, γ)
    smooth!(o.θ, o2.θ, γ)
end

#-----------------------------------------------------------------------# ADAGRAD
"""
    ADAGRAD()

Adaptive (element-wise learning rate) stochastic gradient descent.
"""
mutable struct ADAGRAD <: SGUpdater
    H::VecF
    nobs::Int
    ADAGRAD(p = 0) = new(zeros(p), 0)
end
init(u::ADAGRAD, p) = ADAGRAD(p)
function Base.merge!(o::ADAGRAD, o2::ADAGRAD, γ::Float64)
    o.nobs += o2.nobs
    smooth!(o.H, o2.H, γ)
    o
end

#-----------------------------------------------------------------------# MSPI, OMAS, OMAP
for T in [:OMAS, :OMAS2, :OMAP, :OMAP2, :MSPI, :MSPI2]
    @eval begin
        """
            MSPI()  # Majorized stochastic proximal iteration
            MSPI2()
            OMAS()  # Online MM - Averaged Surrogate
            OMAS2()
            OMAP()  # Online MM - Averaged Parameter
            OMAP2()

        Updaters based on majorizing functions.  `MSPI`/`OMAS`/`OMAP` define a family of 
        algorithms and not a specific update, thus each type has two possible versions.

        - See https://arxiv.org/abs/1306.4650 for OMAS
        - Ask @joshday for details on OMAP and MSPI
        """
        struct $T{T} <: Updater
            buffer::T 
        end
        $T() = $T(nothing)
        function Base.merge!(a::S, b::S, γ::Float64) where {S <: $T} 
            smooth!.(a.buffer, b.buffer, γ)
            a
        end
    end 
end