#-----------------------------------------------------------------------------# GradientCore 
"""
    GradientCore(Δf!::Function, storage)

Low-level struct for tracking a parameter and its gradient.  `Δf!` must have the method 

- `Δf!(storage, x, θ)`: overwrite `storage` with the gradient Δf(x|θ)
"""
struct GradientCore{Δf!, T}
    θ::Vector{T}
    Δ::Vector{T}
    GradientCore(f, θ::Vector{T}) where {T} = new{f, T}(θ, deepcopy(θ))
end
Base.show(io::IO, c::GradientCore) = print(io, "GradientCore | paramsize = $(size(c.θ))")
update!(core::GradientCore{f!}, x) where {f!} = f!(core.Δ, x, core.θ)

function init!(core::GradientCore, data)
    @info "Intializing GradientCore..."
    ready = false
    for i in 1:9999 
        push!(core.θ, 0.0)
        push!(core.Δ, 0.0)
        try 
            update!(core, data)
            ready = true
            break
        catch
        end
    end
    ready || error("GradientCore failed to initialize up to buffer size 9999.  Must be initialized manually.")
end

# utils
descent(θ, w, Δ) = θ - w * Δ

#-----------------------------------------------------------------------------# 
abstract type StochasticApproximation{T} <: OnlineStat{T} end

value(o::StochasticApproximation) = o.core.θ

function _fit!(o::StochasticApproximation, data)
    (o.n += 1) == 1 && init!(o.core, data)
    update!(o.core, data)
    updateθ!(o)
end

#-----------------------------------------------------------------------------# SGD_Stat 
"""
    SGD_Stat(T, core::GradientCore; rate = LearningRate())

Low-level OnlineStat for calculating stochastic gradient descent where `T` is the type of a 
single observation.

# Example 

This example approximates a linear regression via SGD:

    # Simulate Data
    n, p = 10^6, 10  # 10^6 obserations with 10 predictor variables
    x = randn(n, p)
    y = x * collect(1:p) + randn(n)

    # function for updating gradient
    function f!(storage, xy, θ)
        x, y = xy 
        storage .= x .* (x'θ - y)
    end

    o = SGD_Stat(OnlineStats.XY, GradientCore(f!, zeros(p)))

    fit!(o, zip(eachrow(x), y))
"""
mutable struct SGD_Stat{I, C <: GradientCore, W} <: StochasticApproximation{I}
    core::C
    rate::W 
    n::Int
end
function SGD_Stat(::Type{I}, core::C; rate = LearningRate()) where {I, C<:GradientCore}
    SGD_Stat{I, C, typeof(rate)}(core, rate, 0)
end
updateθ!(o::SGD_Stat) = o.core.θ .= descent.(o.core.θ, o.rate(o.n), o.core.Δ)

#-----------------------------------------------------------------------------# ADAGRAD_Stat 
"""
    ADAGRAD_Stat(T, core; rate=LearningRate())

Low-level OnlineStat for using the ADAGRAD algorithm.  See [@ref](SGD_Stat) for more details.
"""
mutable struct ADAGRAD_Stat{I, T, C<:GradientCore{<:Any, T}, W} <: StochasticApproximation{I}
    core::C 
    h::Vector{T}
    rate::W 
    n::Int
end
function ADAGRAD_Stat(::Type{I}, core::C; rate = LearningRate()) where {I, T, C<:GradientCore{<:Any, T}}
    ADAGRAD_Stat{I, T, C, typeof(rate)}(core, deepcopy(core.θ), rate, 0)
end
function updateθ!(o::ADAGRAD_Stat) 
    o.h .= smooth.(o.h, o.core.Δ .^ 2, 1 / o.n)
    o.core.θ .= descent.(o.core.θ, o.rate(o.n) ./ (sqrt.(o.h) .+ ϵ), o.core.Δ)
end

#-----------------------------------------------------------------------------# RMSPROP_Stat
"""
    RMSPROP_Stat(T, core; rate=LearningRate(), alpha=.9)

Low-level OnlineStat for the RMSProp algorithm.  See [@ref](SGD_Stat) for more details.
"""
mutable struct RMSPROP_Stat{I, T, C<:GradientCore{<:Any, T}, W} <: StochasticApproximation{I}
    core::C 
    h::Vector{T}
    α::T
    rate::W 
    n::Int
end
function RMSPROP_Stat(::Type{I}, core::C; α=.9, rate = LearningRate()) where {I, T, C<:GradientCore{<:Any, T}}
    RMSPROP_Stat{I, T, C, typeof(rate)}(core, deepcopy(core.θ), α, rate, 0)
end
function updateθ!(o::RMSPROP_Stat) 
    o.h .= smooth.(o.core.Δ .^ 2, o.h, o.α)
    o.core.θ .= descent.(o.core.θ, o.rate(o.n) ./ (sqrt.(o.h) .+ ϵ), o.core.Δ)
end

#-----------------------------------------------------------------------------# ADADELTA_Stat 
"""
    ADADELTA_Stat(T, core; rate=LearningRate(), alpha=.9)

Low-level OnlineStat for the Adadelta algorithm.  See [@ref](SGD_Stat) for more details.
"""
mutable struct ADADELTA_Stat{I, T, C<:GradientCore{<:Any, T}} <: StochasticApproximation{I}
    core::C 
    num::Vector{T} # numerator
    g::Vector{T}
    ρ::T
    n::Int
end
function ADADELTA_Stat(::Type{I}, core::C; ρ=.9) where {I, T, C<:GradientCore{<:Any, T}}
    ADADELTA_Stat{I, T, C}(core, deepcopy(core.θ), deepcopy(core.θ), ρ, 0)
end
function updateθ!(o::ADADELTA_Stat) 
    o.g .= smooth.(o.core.Δ .^ 2, o.g, o.ρ)
    o.core.θ .= descent.(o.core.θ, 1, sqrt.(o.num .+ ϵ) ./ sqrt.(o.g .+ ϵ) .* o.core.Δ)
    o.num .= smooth.((o.core.Δ ./ (sqrt.(o.g) .+ ϵ)) .^ 2, o.num, o.ρ)
end