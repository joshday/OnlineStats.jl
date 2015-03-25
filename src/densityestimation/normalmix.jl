export OnlineNormalMix

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type OnlineNormalMix <: ContinuousUnivariateOnlineStat
    model::MixtureModel{Univariate, Continuous, Normal}    # MixtureModel
    s1::Vector{Float64}             # sum of weights
    s2::Vector{Float64}             # sum of (weights .* y)
    s3::Vector{Float64}             # sum of (weights .* y .* y)
    r:: Float64                     # learning rate
    n::Int64                        # number of observations
    nb::Int64                       # number of batches
end

function OnlineNormalMix(y::Vector{Float64},
                         obj::MixtureModel{Univariate, Continuous, Normal};
                         r=.51)
    n = length(y)
    nj = length(components(obj))
    π = probs(obj)
    w::Matrix{Float64} = zeros(n, nj)
    for i = 1:n, j = 1:nj
        w[i, j] = π[j] * pdf(components(obj)[j], y[i])
    end
    w ./= sum(w, 2)
    s1 = vec(sum(w, 1))
    s2 = vec(sum(w .* y, 1))
    s3 = vec(sum(w .* y .* y, 1))

    OnlineNormalMix(obj, s1, s2, s3, r, n, 1)
end

function OnlineNormalMix(y::Vector{Float64}; k = 2, r=.51,
                         obj::MixtureModel{Univariate, Continuous, Normal} =
                             MixtureModel(map((u, v) -> Normal(u, v),
                                              [quantile(y, [1:k]/(k+1))],
                                              var(y) / sqrt(k) * ones(k))))
    OnlineNormalMix(y, obj, r = r)
end




#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineNormalMix, y::Vector{Float64})
    n = length(y)
    nj = length(components(obj))
    π = probs(obj)
    w::Matrix{Float64} = zeros(n, nj)
    s1::Vector{Float64} = zeros(nj)
    s2::Vector{Float64} = zeros(nj)
    s3::Vector{Float64} = zeros(nj)
    for i = 1:n, j = 1:nj
        w[i, j] = π[j] * pdf(obj.model.components[j], y[i])
    end
    w ./= sum(w, 2)
    s1 = vec(sum(w, 1))
    s2 = vec(sum(w .* y, 1))
    s3 = vec(sum(w .* y .* y, 1))

    γ = obj.nb ^ -obj.r
    obj.s1 += γ * (s1 - obj.s1)
    obj.s2 += γ * (s2 - obj.s2)
    obj.s3 += γ * (s3 - obj.s3)

    π = obj.s1
    π ./= sum(π)
    μ = obj.s2 ./ obj.s1
    σ = (obj.s3 - (obj.s2 .* obj.s2 ./ obj.s1)) ./ obj.s1

    obj.model = MixtureModel(map((u,v) ->
                                 Normal(u, v), vec(μ), vec(sqrt(σ))), vec(π))
    obj.n += n
    obj.nb += 1
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineNormalMix)
    names = [:mean; :var]
    estimates = [mean(obj); var(obj)]
    for i in 1:length(components(obj.model))
        names = [names; "μ$i"; "σ$i"; "π$i"]
        estimates = [estimates; mean(components(obj.model)[i]);
                 std(components(obj.model)[i]); probs(obj.model)[i]]
    end
    names = [names; "nb"; "n"]
    estimates = [estimates; obj.nb; obj.n]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::OnlineNormalMix) = OnlineNormalMix(obj.model, obj.s1, obj.s2,
                                                  obj.s3, obj.n, obj.nb)

Base.mean(obj::OnlineNormalMix) = return mean(obj.model)

means(obj::OnlineNormalMix) = means(obj.model)

stds(obj::OnlineNormalMix) = stds(obj.model)

Distributions.pdf(obj::OnlineNormalMix, x) = pdf(obj.model, x)

Distributions.logpdf(obj::OnlineNormalMix, x) = logpdf(obj.model, x)

Distributions.components(obj::OnlineNormalMix) = components(obj.model)

Distributions.probs(obj::OnlineNormalMix) = probs(obj.model)

Distributions.var(obj::OnlineNormalMix) = var(obj.model)

function Base.show(io::IO, obj::OnlineNormalMix)
    println("OnlineNormalMix:")
    show(obj.model)
end







#### Testing
# True Components: N(0, 1), N(3, 2), N(10, 5)
# n = 1_000_000
# n = 999_900
# trueModel = MixtureModel(Normal, [(0, 1), (3, 2), (10, 5)], [.2, .3, .5])
# x = rand(trueModel, n)


# obj, results = OnlineStats.trace_df(OnlineStats.OnlineNormalMix, x, 100, x[1:100], k=3,
#                                     r = .50001)
# μresults = results[:, [1,4,7,10,11]]
# σresults = results[:, [2,5,8,10,11]]
# πresults = results[:, [3,6,9,10,11]]
# μresults_melt = melt(μresults, 4:5)
# σresults_melt = melt(σresults, 4:5)
# πresults_melt = melt(πresults, 4:5)

# plot(μresults_melt, x=:n, y=:value, color=:variable, Geom.line,
#      yintercept=[0, 3, 10], Geom.hline)

# plot(σresults_melt, x=:n, y=:value, color=:variable, Geom.line,
#      yintercept=[1, 2, 5], Geom.hline)

# plot(πresults_melt, x=:n, y=:value, color=:variable, Geom.line,
#      yintercept=[.2, .3, .5], Geom.hline)

