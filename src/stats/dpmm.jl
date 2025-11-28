
# Implements the single-pass nonparametric mixture model learning algorithm in:
# Dahua Lin, "Online Learning of Nonparametric Mixture Models via Sequential
# Variational Approximation." Advances in Neural Information Processing Systems
# 26, 2013.
# Only univariate mixtures are currently supported.

function transformnatural(μ, λ, α, β)
    η₁ = λ*μ
    η₂ = -β - λ.*μ.^2/2
    η₃ = α .- 1/2
    η₄ = λ/-2
    η₁, η₂, η₃, η₄
end

function transformnatural⁻¹(η₁, η₂, η₃, η₄)
    λ = η₄*-2
    μ = η₁ ./ (η₄*-2)
    α = η₃ .+ 1/2
    β = -η₂ + (η₁.^2 ./ (4*η₄))
    μ, λ, α, β
end

"""
    DPMM(comp_mu::Real,
         comp_lambda::Real,
         comp_alpha::Real,
         comp_beta::Real,
         dirichlet_alpha::Real;
         comp_birth_thres=1e-2,
         comp_death_thres=1e-2,
         n_comp_max=10)

Online univariate dirichlet process Gaussian mixture model algorithm.

# Mathematical Description

The model is described as

    G ~ DP(dirchlet_alpha, Normal-Gamma)
    (μₖ, τₖ) ~ G
    x ~ N(μ, 1/sqrt(τ))

where the base measure is defined as

    τₖ ~ Gamma(comp_alpha, 1/comp_beta)
    μₖ ~ N(comp_mu, 1/sqrt(comp_lambda*τₖ)).

The variational distribution is the mean-field family defined as

    q(μₖ | τₖ; mₖ, lₖ) q(τₖ; aₖ, bₖ) = N(μₖ; mₖ, 1/(lₖ*τₖ)) Gamma(τₖ; aₖ, 1/bₖ).

Since the model is nonparametric, mixture components are added depending on the
birth threshold `comp_birth_thres` (higher means less frequen births) and
existing components are pruned depending on the death threshold `comp_death_thres`.

# Hyperparameters

DPMMs tend to be very sensitive to its hyperparameters. Therefore, it is important
to monitor the fitted result and tweak the hyperparameters accordingly. Here
are the implications of each hyperparameter:

- `comp_mu`: Prior mean of the components
- `comp_lambda`: Prior precision of the components. This affects the dispersion
                 of the components relative to the scale of each component.
                 (Smaller the more dispersed.) (`comp_lambda` > 0)
- `comp_alpha`: Gamma shape parameter of the scale (inverse of the variance) of
                each component. (`comp_alpha` > 0)
- `comp_beta`: Gamma scale parameter of the scale (inverse of the variance) of
               each component. (`comp_beta` > 0)
- `dirichlet_alpha`: Initial weight of a newly added component. Larger values
                     result in more components being created.
                     (`dirichlet_alpha` > 0)
- `comp_birth_thres`: Threshold for adding a new component (highly affected by
                      `dirichlet_alpha`)
- `comp_death_thres`: Threshold for prunning (or killing) an existing component.

A mechanical procedure for setting the component hyperparameters is to first set
`comp_alpha > 2`. This ensures the variance to be finite. Then, solve
`comp_beta` such that the Gamma distribution concentrates most of the
probability density on the expected range of `1/τₖ`, the variance of each
component. Finally, solve for `comp_lambda` such that the marginal density of
`μₖ`, which is a Student-T distribution

    p(μₖ | λ₀, α₀, β₀)
        = ∫ p(μₖ | τₖ, μ₀, λ₀) p(τₖ | α₀, β₀) dτₖ
        = ∫ N(μₖ; μ₀, 1/sqrt(λ₀*τₖ)) Gamma(τₖ; αₖ, βₖ) dτₖ
        = TDist( 2*α₀, μ₀, sqrt(β₀/(λ₀*α₀)),

has its probability density concentrated on the expected range of the component
means.

Below is a implementing the prior elicitation procedure described above:

```julia
using Roots

prob_τₖ = 0.8
τₖ_max  = 0.5
μ₀      = 0.0
α₀      = 2.1
prob_μₖ = 0.8
μₖ_min  = -2
μₖ_max  = 2

β₀ = find_zero(β₀ -> cdf(InverseGamma(α₀, β₀), τₖ_max) - prob_τₖ, (1e-4, Inf))
λ₀ = find_zero(λ₀ -> begin
    p_μ = TDist(2*α₀)*sqrt(β₀/(λ₀*α₀)) + μ₀
    cdf(p_μ, μₖ_max) - cdf(p_μ, μₖ_min) - prob_τₖ
end, (1e-4, 1e+2))
```

`prob_*` sets the amount of density on the desired range. `τₖ_max`, `μₖ_min`,
`μₖ_max` is the expected range of each parameters. Since we leave `1 - prob_*`
density on the tails, these are soft contraints.

Unfortunately, `dirichlet_alpha`, `comp_birth_thres`, `comp_death_thres`
can be tuned only through trial and error. However, `dirichlet_alpha` is best
set 0.5 ~ 1e-2 depending on the desired number of components.

# Example

```julia
n    = 1024
μ    = 0.0
λ    = 0.1
α    = 2.1
β    = 0.5
α_dp = 1.0
o    = DPMM(μ, λ, α, β, α_dp; comp_birth_thres=0.5,
            comp_death_thres=1e-2, n_comp_max=10)
p = MixtureModel([ Normal(-2.0, 0.5), Normal(3.0, 1.0) ], [0.7, 0.3])
o = fit!(o, rand(p, 1000))
```
"""
mutable struct DPMM{T <: Real} <: OnlineStat{Number}
    n::Int        # Number of observations
    K_max::Int
    α_dp::T       # Dirichlet prior hyperparameter
    ϵ_birth::T    # Component birth threshold
    ϵ_death::T    # Component death threshold
    η₁_prior::T   # Prior component natural parameter 1
    η₂_prior::T   # Prior component natural parameter 2
    η₃_prior::T   # Prior component natural parameter 3
    η₄_prior::T   # Prior component natural parameter 4
    w::Vector{T}  # Mixture component variational weight
    η₁::Vector{T} # Natural parameter 1
    η₂::Vector{T} # Natural parameter 2
    η₃::Vector{T} # Natural parameter 3
    η₄::Vector{T} # Natural parameter 4
    function DPMM(comp_mu::T,
                  comp_lambda::T,
                  comp_alpha::T,
                  comp_beta::T,
                  dirichlet_alpha::T;
                  comp_birth_thres=T(1e-2),
                  comp_death_thres=T(1e-2),
                  n_comp_max=10) where {T <: Real}
        @assert comp_lambda     > 0 "Component mean hyperparameter λ must be positive"
        @assert comp_alpha      > 0 "Component scale hyperparameter α must be positive"
        @assert comp_beta       > 0 "Component scale hyperparameter β must be positive"
        @assert dirichlet_alpha > 0 "Dirichlet process hyperparameter α must be positive"
        @assert n_comp_max      > 0 "DPMM does not make sense with 0 components"

        μ₀ = comp_mu
        λ₀ = comp_lambda
        α₀ = comp_alpha
        β₀ = comp_beta

        η₁_prior, η₂_prior, η₃_prior, η₄_prior = transformnatural(μ₀, λ₀, α₀, β₀)

        new{T}(0, n_comp_max, dirichlet_alpha,
               comp_birth_thres, comp_death_thres,
               η₁_prior, η₂_prior, η₃_prior, η₄_prior,
               Float64[], Float64[], Float64[], Float64[], Float64[])
    end
end
Base.length(o::DPMM) = length(o.w) # Number of mixture components
function _fit!(o::DPMM, x::Real)
    A(η₁, η₂, η₃, η₄) = begin
        loggamma(η₃ + 1/2) - log(-2*η₄)/2 - (η₃ + 1/2)*log(-η₂ + η₁^2/(4*η₄))
    end
    n = o.n + 1
    K = length(o.w)

    # Sufficient statistics
    T₁ = x
    T₂ = x^2/-2
    T₃ = 1/2
    T₄ = -1/2

    # Componentwise predictive likelihood
    h = map(1:K+1) do k
        η₁, η₂, η₃, η₄ = if k == K + 1
            o.η₁_prior, o.η₂_prior, o.η₃_prior, o.η₄_prior
        else
            o.η₁[k], o.η₂[k], o.η₃[k], o.η₄[k]
        end
        A(η₁ + T₁, η₂ + T₂, η₃ + T₃, η₄ + T₄) - A(η₁, η₂, η₃, η₄)
    end
    w_new  = vcat(o.w, o.α_dp)
    ℓwexph = log.(w_new) .+ h
    ρ      = exp.(ℓwexph .- logsumexp(ℓwexph))

    if ρ[end] <= o.ϵ_birth || K >= o.K_max
        # Ignore new component
        ρ = ρ[1:K]
        ρ = ρ / sum(ρ)
    else
        # Add new component
        K += 1
        o.w  = w_new
        o.η₁ = vcat(o.η₁, o.η₁_prior)
        o.η₂ = vcat(o.η₂, o.η₂_prior)
        o.η₃ = vcat(o.η₃, o.η₃_prior)
        o.η₄ = vcat(o.η₄, o.η₄_prior)
    end

    # Update variational parameters
    o.w  += ρ
    o.η₁ += ρ*T₁
    o.η₂ += ρ*T₂
    o.η₃ += ρ*T₃
    o.η₄ += ρ*T₄

    # Prune component with small contribution
    idx_keep = o.w .> o.ϵ_death
    o.w  = o.w[idx_keep]
    o.η₁ = o.η₁[idx_keep]
    o.η₂ = o.η₂[idx_keep]
    o.η₃ = o.η₃[idx_keep]
    o.η₄ = o.η₄[idx_keep]
    o.n  = n
end
"""
    sethyperparams!(o::DPMM; )

Reset the hyperparameters of an existing DPMM object. The state of the DPMM is
kept unchanged.
"""

function sethyperparams!(o::DPMM{T},
                         comp_mu::T,
                         comp_lambda::T,
                         comp_alpha::T,
                         comp_beta::T,
                         dirichlet_alpha::T;
                         comp_birth_thres=o.ϵ_birth,
                         comp_death_thres=o.ϵ_death,
                         n_comp_max=o.K_max) where {T <: Real}
    μ₀ = comp_mu
    λ₀ = comp_lambda
    α₀ = comp_alpha
    β₀ = comp_beta

    η₁_prior, η₂_prior, η₃_prior, η₄_prior = transformnatural(μ₀, λ₀, α₀, β₀)

    o.K_max    = n_comp_max
    o.α_dp     = comp_alpha
    o.ϵ_birth  = comp_birth_thres
    o.ϵ_death  = comp_death_thres
    o.η₁_prior = η₁_prior
    o.η₂_prior = η₂_prior
    o.η₃_prior = η₃_prior
    o.η₄_prior = η₄_prior
    o
end

"""
    value(o::DPMM)

Realize the mixture model where each component is the marginal predictive
distribution obtained as

    q(x; mₖ, lₖ, aₖ, bₖ)
        = ∫ N(x; μₖ, sqrt(1/τₖ)) q(μₖ | τₖ; mₖ, lₖ) q(τₖ; aₖ, bₖ) dμₖ dτₖ
        = ∫ N(x; mₖ, sqrt(1/τₖ + 1/(lₖ*τₖ))) Gamma(τₖ; aₖ, bₖ) dμₖ dτₖ
        = TDist( 2*aₖ, mₖ, sqrt(bₖ/aₖ*(lₖ+1)/lₖ) )
"""
function value(o::DPMM{T}) where {T <: Real}
    K = length(o.w)

    η₁, η₂, η₃, η₄, w = if K == 0
        T[o.η₁_prior], T[o.η₂_prior], T[o.η₃_prior], T[o.η₄_prior], T[1]
    else
        o.η₁, o.η₂, o.η₃, o.η₄, o.w
    end

    m, l, a, b = transformnatural⁻¹(η₁, η₂, η₃, η₄)

    μ = m
    ν = 2*a
    σ = sqrt.(b./a.*((l .+ 1)./l))
    w = w / sum(w)
    q = TDist.(ν).*σ + μ
    MixtureModel(q, w)
end

