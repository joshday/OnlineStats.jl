#--------------------------------------------------------------# means and stds
function means(m::Dist.MixtureModel{Dist.Univariate, Dist.Continuous, Dist.Normal})
    map(mean, Distributions.components(m))
end

function stds(m::Dist.MixtureModel{Dist.Univariate, Dist.Continuous, Dist.Normal})
    map(std, Distributions.components(m))
end


#---------------------------------------------------------------------# emstart
function emstart(p::Integer, y::AVecF;
                 algorithm::Symbol = :naive, verbose = false, tol = 1e-6, maxit = 100)
    if algorithm == :naive
        μ = quantile(y, collect(1:p) / (p + 1))
        σ = fill(std(y) / sqrt(p), p)
        π = ones(p) / p
    else
        error("$algorithm is not recognized.  Currently, the only option is :naive")
    end
    m = Dist.MixtureModel(map((u,v) -> Dist.Normal(u, v), μ, σ), π)
    m = em(m, y, tol = tol, maxit = maxit, verbose = verbose)
end


#--------------------------------------------------------------------------# em
function em(o::Dist.MixtureModel{Dist.Univariate, Dist.Continuous, Dist.Normal}, y::AVecF;
            tol::Float64 = 1e-6,
            maxit::Int = 100,
            verbose::Bool = false)

    n = length(y)
    nj = length(o.components)  # number of components
    π = Dist.probs(o)
    μ = means(o)
    σ = stds(o)

    w = zeros(n, nj)
    wy = zeros(n, nj)
    s1 = zeros(nj)
    s2 = zeros(nj)
    s3 = zeros(nj)

    tolerance = 1.0
    loglik = sum(Distributions.logpdf(o, y))
    iters = 0

    for i in 1:maxit
        iters += 1
        for j = 1:nj, i = 1:n
            w[i, j] = π[j] * Distributions.pdf(o.components[j], y[i])
        end
        w ./= sum(w, 2)
        copy!(wy, w .* y)
        copy!(s1, vec(sum(w, 1)))
        copy!(s2, vec(sum(wy, 1)))
        copy!(s3, vec(sum(wy .* y, 1)))

        π = s1
        π ./= sum(π)
        μ = s2 ./ s1
        σ = (s3 - (s2 .* s2 ./ s1)) ./ s1
        if any(σ .<= 0)
            σ = ones(nj)
        end
        o = Dist.MixtureModel(map((u,v) -> Dist.Normal(u, v), vec(μ), vec(sqrt(σ))), vec(π))

        # Check tolerance
        loglik_old = loglik
        loglik = Distributions.loglikelihood(o, y)
        numerator = abs(loglik - loglik_old)
        denom = (abs(loglik_old) + 1)
        numerator > tol * denom  || break

        if verbose
            tolerance = numerator / denom
           LOG("iteration: $iters, tolerance: $tolerance")
        end
    end
    if verbose
        LOG("iterations    = $iters")
        LOG("tolerance     = $tolerance")
        LOG("loglikelihood = $loglik")
    end
    return o
end
