
# Implements the single-pass nonparametric mixture model learning algorithm in:
# Dahua Lin, "Online Learning of Nonparametric Mixture Models via Sequential
# Variational Approximation." Advances in Neural Information Processing Systems
# 26, 2013.
# Only univariate mixtures are currently supported.

"""
    DDPM(comp_mu::Real,
         comp_lambda::Real,
         comp_alpha::Real,
         comp_beta::Real,
         dirichlet_alpha::Real;
         comp_birth_thres=1e-2,
         comp_death_thres=1e-2,
         n_comp_max=10)

Online univariate dirichlet process Gaussian mixture model algorithm.
The model is described as
    
    G ~ DP(dirchlet_alpha, normal-gamma)
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

# Example

"""
mutable struct DPMM{T <: Real} <: OnlineStat{T}
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
    ∑ρ::Vector{T} # Mixture component running likelihood
    function DPMM(comp_mu::T,
                  comp_lambda::T,
                  comp_alpha::T,
                  comp_beta::T,
                  dirichlet_alpha::T;
                  comp_birth_thres=1e-2,
                  comp_death_thres=1e-2,
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
        η₁_prior = λ₀*μ₀
        η₂_prior = -β₀ - λ₀.*μ₀.^2/2
        η₃_prior = α₀ - 1/2
        η₄_prior = λ₀/-2
        new{T}(0, n_comp_max, dirichlet_alpha, comp_birth_thres, comp_death_thres,
               η₁_prior, η₂_prior, η₃_prior, η₄_prior,
               Float64[], Float64[], Float64[], Float64[], Float64[], Float64[])
    end
end
Base.length(o::CCIPCA) = length(w) # Number of mixture components
function _fit!(o::DPMM{T}, x::T) where {T <: Real}
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
        o.∑ρ = vcat(o.∑ρ, 0.0)
    end

    # Update variational parameters
    o.w  += ρ
    o.η₁ += ρ*T₁
    o.η₂ += ρ*T₂
    o.η₃ += ρ*T₃
    o.η₄ += ρ*T₄
    o.∑ρ += ρ

    # Prune component with small contribution
    w_prune  = o.∑ρ / sum(o.∑ρ)
    idx_keep = w_prune .> o.ϵ_death

    o.w  = o.w[idx_keep]
    o.η₁ = o.η₁[idx_keep]
    o.η₂ = o.η₂[idx_keep]
    o.η₃ = o.η₃[idx_keep]
    o.η₄ = o.η₄[idx_keep]
    o.∑ρ = o.∑ρ[idx_keep]

    o.n = n
end
"""
    marginalmixture(o::CCIPCA)

Realize the mixture model where each component is the marginal predictive
distribution obtained as

    q(x; mₖ, lₖ, aₖ, bₖ)
        = ∫ N(x; μₖ, sqrt(1/τₖ)) q(μₖ | τₖ; mₖ, lₖ) q(τₖ; aₖ, bₖ) dμₖ dτₖ
        = ∫ N(x; mₖ, sqrt(1/τₖ + 1/(lₖ*τₖ))) G(τₖ; aₖ, bₖ) dμₖ dτₖ
        = TDist( 2*aₖ, mₖ, sqrt(bₖ/aₖ*(lₖ+1)/lₖ) )  dμₖ dτₖ

"""
function marginalmixture(o::DPMM)
    K = length(o.w)

    η₁, η₂, η₃, η₄ = if K == 0
        o.η₁_prior, o.η₂_prior, o.η₃_prior, o.η₄_prior
    else
        o.η₁, o.η₂, o.η₃, o.η₄
    end

    l = η₄*-2
    m = η₁ ./ (η₄*-2)
    a = η₃ .+ 1/2
    b = -η₂ + (η₁.^2 ./ (4*η₄))

    μ_marg = m
    ν_marg = 2*a
    σ_marg = sqrt.(b./a.*((l .+ 1)./l))
    w_norm = o.w / sum(o.w)
    qₖ     = TDist.(ν_marg) .* σ_marg .+ μ_marg
    MixtureModel(qₖ, w_norm)
end

