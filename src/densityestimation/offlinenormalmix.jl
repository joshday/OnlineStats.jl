#--------------------------------------------------------------# means and stds
function means(mm::MixtureModel{Univariate, Continuous, Normal})
    result = []
    for j in 1:length(components(mm))
        result = [result; mean(components(mm)[j])]
    end
    return result
end

function stds(mm::MixtureModel{Univariate, Continuous, Normal})
    result = []
    for j in 1:length(components(mm))
        result = [result; std(components(mm)[j])]
    end
    return result
end

#--------------------------------------------------------------------------# em
function em(obj::MixtureModel{Univariate, Continuous, Normal},
             y::Vector{Float64}; tol::Float64 = 1e-6, maxit::Int64 = 100,
            verbose::Bool = false)
    n::Int64 = length(y)
    nj::Int64 = length(obj.components)
    π::Vector{Float64} = probs(obj)
    μ::Vector{Float64} = means(obj)
    σ::Vector{Float64} = stds(obj)

    w::Matrix{Float64} = zeros(n, nj)
    s1::Vector{Float64} = zeros(nj)
    s2::Vector{Float64} = zeros(nj)
    s3::Vector{Float64} = zeros(nj)

    tolerance::Float64 = 1.0
    loglik::Float64 = sum(logpdf(obj, y))
    iters::Int64 = 0

    for i in 1:maxit
        iters += 1
        for i = 1:n, j = 1:nj
            w[i, j] = π[j] * pdf(obj.components[j], y[i])
        end
        w ./= sum(w, 2)
        s1 = vec(sum(w, 1))
        s2 = vec(sum(w .* y, 1))
        s3 = vec(sum(w .* y .* y, 1))

        π = s1
        π ./= sum(π)
        μ = s2 ./ s1
        σ = (s3 - (s2 .* s2 ./ s1)) ./ s1
        obj = MixtureModel(map((u,v) -> Normal(u, v), vec(μ), vec(sqrt(σ))), vec(π))

        loglik_old = loglik
        loglik = loglikelihood(obj, y)

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
    return obj
end


#-------------------------------------------------------------------------# cdf
function cdf{T<:Real}(
        obj::MixtureModel{Univariate, Continuous, Normal}, x::T)
    π = probs(obj)
    result = 0.0
    for j in 1:length(π)
        result += π[j] * cdf(components(obj)[j], x)
    end
    return result
end



# Testing
trueModel = MixtureModel(Normal, [(0, 1), (3, 2), (10, 5)], [.2, .3, .5])
x = rand(trueModel, 10000)

fit = MixtureModel(Normal, [(0, 1), (2, 1), (4, 1)])
@time fit = OnlineStats.em(fit, x, tol=1e-7, maxit=500, verbose=true)
# Gadfly.plot(fit, x)
# Gadfly.plot(fit, -5, 25)

