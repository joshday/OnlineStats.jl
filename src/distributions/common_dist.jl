# This breaks the v0.3 build
# """
# `distributionfit(Dist, y)`
#
# Create an OnlineStat object for parametric density estimation of the distribution `Dist`
# using data `y`
# """
# function distributionfit end
#------------------------------------------------------------# DistributionStat
function Base.show(io::IO, o::DistributionStat)
    println("Online " * string(typeof(o)) * ", nobs:" * string(nobs(o)))
    show(o.d)
end

statenames(o::DistributionStat) = [:dist, :nobs]
state(o::DistributionStat) = [o.d, o.n]

Distributions.params(o::DistributionStat) = params(o.d)
Distributions.succprob(o::DistributionStat) = succprob(o.d)
Distributions.failprob(o::DistributionStat) = failprob(o.d)
Distributions.scale(o::DistributionStat) = scale(o.d)
# location(o::DistributionStat) = location(o.d)  # doesn't apply to any distribution yet
Distributions.shape(o::DistributionStat) = shape(o.d)
Distributions.rate(o::DistributionStat) = rate(o.d)
Distributions.ncategories(o::DistributionStat) = ncategories(o.d)
Distributions.ntrials(o::DistributionStat) = ntrials(o.d)
# dof(o::DistributionStat) = dof(o.d)  # doesn't apply to any distribution yet

Base.mean(o::DistributionStat) = mean(o.d)
Base.var(o::DistributionStat) = var(o.d)
Base.std(o::DistributionStat) = std(o.d)
Base.median(o::DistributionStat) = median(o.d)

StatsBase.mode(o::DistributionStat) = mode(o.d)
StatsBase.modes(o::DistributionStat) = modes(o.d)
StatsBase.skewness(o::DistributionStat) = skewness(o.d)
StatsBase.kurtosis(o::DistributionStat) = kurtosis(o.d)
StatsBase.entropy(o::DistributionStat) = entropy(o.d)

Distributions.mgf(o::DistributionStat, x) = mgf(o.d, x)
Distributions.cf(o::DistributionStat, x) = cf(o.d, x)
Distributions.insupport(o::DistributionStat, x) = insupport(o.d, x)
Distributions.pdf(o::DistributionStat, x) = pdf(o.d, x)
Distributions.logpdf(o::DistributionStat, x) = logpdf(o.d, x)
Distributions.loglikelihood(o::DistributionStat, x) = loglikelihood(o.d, x)
Distributions.cdf(o::DistributionStat, x) = cdf(o.d, x)
Distributions.logcdf(o::DistributionStat, x) = logcdf(o.d, x)
Distributions.ccdf(o::DistributionStat, x) = ccdf(o.d, x)
Distributions.logccdf(o::DistributionStat, x) = logccdf(o.d, x)
Distributions.quantile(o::DistributionStat, τ) = quantile(o.d, τ)
Distributions.cquantile(o::DistributionStat, τ) = cquantile(o.d, τ)
Distributions.invlogcdf(o::DistributionStat, x) = invlogcdf(o.d, x)
Distributions.invlogccdf(o::DistributionStat, x) = invlogccdf(o.d, x)
Distributions.isplatykurtic(o::DistributionStat) = isplatykurtic(o.d)
Distributions.ismesokurtic(o::DistributionStat) = ismesokurtic(o.d)

Base.rand(o::DistributionStat) = rand(o.d)
Base.rand(o::DistributionStat, n_or_dims) = rand(o.d, n_or_dims)
Base.rand!(o::DistributionStat, arr) = rand!(o.d, arr)
