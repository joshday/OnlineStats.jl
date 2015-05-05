#--------------------------------------------------------------# means and stds
function means(m::MixtureModel{Univariate, Continuous, Normal})
    map(mean, components(m))
end

function stds(m::MixtureModel{Univariate, Continuous, Normal})
    map(std, components(m))
end


#---------------------------------------------------------------------# emstart
function emstart(p::Int, y::VecF;
                 algorithm::Symbol = :kmeans, verbose = false, tol = 1e-6, maxit = 100)
    if algorithm == :naive
        μ = quantile(y, [1:p] / (p + 1))
        σ = fill(std(y) / sqrt(p), p)
        π = ones(p) / p
    elseif algorithm == :kmeans
        clust = Clustering.kmeans(y', p)
        μ = vec(clust.centers)
        σ = fill(std(y) / sqrt(p), p)
#         π = clust.counts / sum(clust.counts)
        π = ones(p) / p
    else
        error("$algorithm is not recognized.  Choose :kmeans or :naive")
    end
    m = MixtureModel(map((u,v) -> Normal(u, v), μ, σ), π)
    m = em(m, y, tol = tol, maxit = maxit, verbose = verbose)
end


#--------------------------------------------------------------------------# em
function em(o::MixtureModel{Univariate, Continuous, Normal}, y::VecF;
            tol::Float64 = 1e-6,
            maxit::Int = 100,
            verbose::Bool = false)

    n::Int = length(y)
    nj::Int = length(o.components)  # number of components
    π::VecF = probs(o)
    μ::VecF = means(o)
    σ::VecF = stds(o)

    w::MatF = zeros(n, nj)
    wy::MatF = zeros(n, nj)
    s1::VecF = zeros(nj)
    s2::VecF = zeros(nj)
    s3::VecF = zeros(nj)

    tolerance::Float64 = 1.0
    loglik::Float64 = sum(logpdf(o, y))
    iters::Int64 = 0

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
           println("iteration: $iters, tolerance: $tolerance")
        end
    end
    if verbose
        println("iterations    = $iters")
        println("tolerance     = $tolerance")
        println("loglikelihood = $loglik")
    end
    return o
end


#-------------------------------------------------------------------------# cdf
function cdf{T<:Real}(
        o::MixtureModel{Univariate, Continuous}, x::T)
    π = probs(o)
    result = 0.0
    for j in 1:length(π)
        result += π[j] * cdf(components(o)[j], x)
    end
    return result
end



# Testing
if false
    trueModel = MixtureModel(Normal, [(0, 1), (10, 5)], [.5, .5])
    x = rand(trueModel, 10000)

    @time myfit1 = OnlineStats.emstart(2, x, algorithm = :naive, tol = 1e-10)
    @time myfit2 = OnlineStats.emstart(2, x, algorithm = :kmeans, tol = 1e-10)

    include("src/plotmethods.jl")
    Gadfly.plot(myfit, x)
    Gadfly.plot(myfit, -5, 25)
end
