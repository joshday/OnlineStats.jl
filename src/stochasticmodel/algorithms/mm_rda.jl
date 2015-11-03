# EXPERIMENTAL
# Can we use second order information from MM gradient with RDA?

#--------------------------------------------------------------------------# MMRDA
"MM-RDA with ADAGRAD weights"
type MMRDA <: Algorithm
    G0::Float64     # sum of squared gradients for intercept
    G::VecF         # sum of squared gradients for everything else
    Ḡ0::Float64     # avg gradient for intercept
    Ḡ::VecF         # avg gradient for everything else
    η::Float64      # constant step size
    n_updates::Int  # number of updates (nobs(o), unless calling updatebatch!)
    function MMRDA(;η::Real = 1.0, δ::Real = 1e-8)
        @assert η > 0
        @assert δ > 0
        new(Float64(δ), zeros(2), 0.0, zeros(2), Float64(η), 0)
    end
end

Base.show(io::IO, o::MMRDA) = print(io, "MMRDA(η = $(o.η))")

function updateβ!(o::StochasticModel{MMRDA}, x::AVecF, y::Float64)
    if nobs(o) == 1
        alg(o).G = zeros(length(x)) + alg(o).G0
        alg(o).Ḡ = zeros(length(x)) + alg(o).G0
    end

    g = ∇f_mm(o.model, x, y, predict(o, x))

    w = 1 / nobs(o)
    if o.intercept
        alg(o).G0 += g^2
        alg(o).Ḡ0 += w * (g - alg(o).Ḡ0)
        o.β0 = -weight(o) * alg(o).Ḡ0
    end

    @inbounds for j in 1:length(x)
        gj = g * x[j]
        alg(o).G[j] += gj^2
        alg(o).Ḡ[j] += w * (gj - alg(o).Ḡ[j])
        rda_update!(o, j)
    end
    alg(o).n_updates += 1
end

function updatebatchβ!(o::StochasticModel{MMRDA}, x::AMatF, y::AVecF)
    if alg(o).G == zeros(2) # on first update, set the size of o.algorithm.G
        alg(o).G = zeros(size(x, 2)) + alg(o).G0
        alg(o).Ḡ = zeros(size(x, 2)) + alg(o).G0
    end

    n = length(y)
    ŷ = predict(o, x)

    alg(o).n_updates += 1
    w = 1 / n_updates(o)
    if o.intercept
        g = 0.0
        for i in 1:n
            g += ∇f_mm(o.model, row(x,i), y[i], ŷ[i])
        end
        g /= n
        alg(o).G0 += g ^ 2
        alg(o).Ḡ0 += w * (g - alg(o).Ḡ0)
        o.β0 = -weight(o) * alg(o).Ḡ0
    end

    for j in 1:size(x, 2)
        g = 0.0
        for i in 1:n
            g += x[i, j] * ∇f_mm(o.model, row(x,i), y[i], ŷ[i])
        end
        g /= n
        alg(o).G[j] += g ^ 2
        alg(o).Ḡ[j] += w * (g - alg(o).Ḡ[j])
        rda_update!(o, j)
    end
end


n_updates(o::StochasticModel{MMRDA}) = alg(o).n_updates
@inline weight(o::StochasticModel{MMRDA}, j::Int) = n_updates(o) * alg(o).η / sqrt(alg(o).G[j])

# NoPenalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{MMRDA,M,NoPenalty}, j::Int)
    o.β[j] = -weight(o, j) * alg(o).Ḡ[j]
end
# L2Penalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{MMRDA,M,L2Penalty}, j::Int)
    alg(o).Ḡ[j] += (1 / n_updates(o)) * pen(o).λ * o.β[j]
    o.β[j] = -weight(o, j) * alg(o).Ḡ[j]
end
# L1Penalty (http://www.magicbroom.info/Papers/DuchiHaSi10.pdf)
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{MMRDA,M,L1Penalty}, j::Int)
    if abs(alg(o).Ḡ[j]) < pen(o).λ
        o.β[j] = 0.0
    else
        ḡ = alg(o).Ḡ[j]
        o.β[j] = sign(-ḡ) * weight(o, j)  * (abs(ḡ) - pen(o).λ)
    end
end
# ElasticNetPenalty
@inline function rda_update!{M<:ModelDefinition}(o::StochasticModel{MMRDA,M,ElasticNetPenalty}, j::Int)
    alg(o).Ḡ[j] += (1 / n_updates(o)) * pen(o).λ * (1 - pen(o).λ) * o.β[j]
    λ = pen(o).λ * pen(o).α
    if abs(alg(o).Ḡ[j]) < λ
        o.β[j] = 0.0
    else
        ḡ = alg(o).Ḡ[j]
        o.β[j] = sign(-ḡ) * weight(o, j) * (abs(ḡ) - λ)
    end
end


# TEST
if false
    # srand(10)
    n, p = 1_000_000, 20
    x = randn(n, p)
    β = collect(linspace(0, 1, p))

    # y = x*β + randn(n)
    y = Float64[rand(Bernoulli(1 / (1 + exp(-xb)))) for xb in x*β]
    # y = Float64[rand(Poisson(exp(xb))) for xb in x*β]
    β = vcat(0.0, β)

    o = StochasticModel(p, algorithm = MMRDA(), model = LogisticRegression())
    @time update!(o, x, y, 1)
    show(o)
    o2 = StochasticModel(p, algorithm = RDA(), model = LogisticRegression())
    @time update!(o2, x, y, 1)
    show(o2)
    println("mm:  ", maxabs(coef(o) - β))
    println("sgd: ", maxabs(coef(o2) - β))

    # # l1reg
    # o = StochasticModel(p, algorithm = MMRDA(r = .5), model = L1Regression())
    # @time update!(o, x, y, 10)
    # show(o)
    # o = StochasticModel(p, algorithm = SGD(r = .5), model = L1Regression())
    # @time update!(o, x, y, 10)
    # show(o)

    # o = StochasticModel(p, algorithm = MMRDA(r = .6), model = LogisticRegression(), penalty = NoPenalty())
    # @time update!(o, x, y, 5)
    # show(o)
    #
    # o = StochasticModel(p, algorithm = SGD(r = .6), model = LogisticRegression(), penalty = NoPenalty())
    # @time update!(o, x, y, 5)
    # show(o)
    #
    # o = StochasticModel(p, algorithm = ProxGrad(), model = LogisticRegression(), penalty = NoPenalty())
    # @time update!(o, x, y, 5)
    # show(o)
    #
    # o = StochasticModel(p, algorithm = MMRDA(), model = LogisticRegression(), penalty = NoPenalty())
    # @time update!(o, x, y, 5)
    # show(o)
end
