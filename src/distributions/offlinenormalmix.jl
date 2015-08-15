#--------------------------------------------------------------# means and stds
function means(m::MixtureModel{Univariate, Continuous, Normal})
    map(mean, components(m))
end

function stds(m::MixtureModel{Univariate, Continuous, Normal})
    map(std, components(m))
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
    m = MixtureModel(map((u,v) -> Normal(u, v), μ, σ), π)
    m = em(m, y, tol = tol, maxit = maxit, verbose = verbose)
end


#--------------------------------------------------------------------------# em
function em(o::MixtureModel{Univariate, Continuous, Normal}, y::AVecF;
            tol::Float64 = 1e-6,
            maxit::Int = 100,
            verbose::Bool = false)

    n = length(y)
    nj = length(o.components)  # number of components
    π::VecF = probs(o)
    μ::VecF = means(o)
    σ::VecF = stds(o)

    w = zeros(n, nj)
    wy = zeros(n, nj)
    s1 = zeros(nj)
    s2 = zeros(nj)
    s3 = zeros(nj)

    tolerance = 1.0
    loglik = sum(logpdf(o, y))
    iters = 0

    for i in 1:maxit
        iters += 1
        for j = 1:nj, i = 1:n
            w[i, j] = π[j] * pdf(o.components[j], y[i])
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
        o = MixtureModel(map((u,v) -> Normal(u, v), vec(μ), vec(sqrt(σ))), vec(π))

        # Check tolerance
        loglik_old = loglik
        loglik = loglikelihood(o, y)
        num = abs(loglik - loglik_old)
        denom = (abs(loglik_old) + 1)
        num > tol * denom  || break

        if verbose
            tolerance = num / denom
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


#-------------------------------------------------------------------------# cdf
# NOTE: cdf/pdf method for MixtureModel was added to Distributions on 5/7/2015
# function cdf(o::MixtureModel{Univariate, Continuous, Normal}, x::Float64)
#     π = probs(o)
#     result = 0.0
#     for j in 1:length(π)
#         result += π[j] * cdf(components(o)[j], x)
#     end
#     return result
# end
