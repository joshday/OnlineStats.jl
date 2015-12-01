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
    println("Online " * string(typeof(o)) * ", nobs:" * string(StatsBase.nobs(o)))
    show(o.d)
end

statenames(o::DistributionStat) = [:dist, :nobs]
state(o::DistributionStat) = [o.d, o.n]

Distributions.params(o::DistributionStat) = Distributions.params(o.d)
Distributions.succprob(o::DistributionStat) = Distributions.succprob(o.d)
Distributions.failprob(o::DistributionStat) = Distributions.failprob(o.d)
Distributions.scale(o::DistributionStat) = Distributions.scale(o.d)
# location(o::DistributionStat) = location(o.d)  # doesn't apply to any distribution yet
Distributions.shape(o::DistributionStat) = Distributions.shape(o.d)
Distributions.rate(o::DistributionStat) = Distributions.rate(o.d)
Distributions.ncategories(o::DistributionStat) = Distributions.ncategories(o.d)
Distributions.ntrials(o::DistributionStat) = Distributions.ntrials(o.d)
# dof(o::DistributionStat) = dof(o.d)  # doesn't apply to any distribution yet

Base.mean(o::DistributionStat) = mean(o.d)
Base.var(o::DistributionStat) = var(o.d)
Base.std(o::DistributionStat) = std(o.d)
Base.median(o::DistributionStat) = median(o.d)

StatsBase.mode(o::DistributionStat) = StatsBase.mode(o.d)
StatsBase.modes(o::DistributionStat) = StatsBase.modes(o.d)
StatsBase.skewness(o::DistributionStat) = StatsBase.skewness(o.d)
StatsBase.kurtosis(o::DistributionStat) = StatsBase.kurtosis(o.d)
StatsBase.entropy(o::DistributionStat) = StatsBase.entropy(o.d)

Distributions.mgf(o::DistributionStat, x) = Distributions.mgf(o.d, x)
Distributions.cf(o::DistributionStat, x) = Distributions.cf(o.d, x)
Distributions.insupport(o::DistributionStat, x) = Distributions.insupport(o.d, x)
Distributions.pdf(o::DistributionStat, x) = Distributions.pdf(o.d, x)
Distributions.logpdf(o::DistributionStat, x) = Distributions.logpdf(o.d, x)
Distributions.loglikelihood(o::DistributionStat, x) = Distributions.loglikelihood(o.d, x)
Distributions.cdf(o::DistributionStat, x) = Distributions.cdf(o.d, x)
Distributions.logcdf(o::DistributionStat, x) = Distributions.logcdf(o.d, x)
Distributions.ccdf(o::DistributionStat, x) = Distributions.ccdf(o.d, x)
Distributions.logccdf(o::DistributionStat, x) = Distributions.logccdf(o.d, x)
Distributions.quantile(o::DistributionStat, τ) = quantile(o.d, τ)
Distributions.cquantile(o::DistributionStat, τ) = Distributions.cquantile(o.d, τ)
Distributions.invlogcdf(o::DistributionStat, x) = Distributions.invlogcdf(o.d, x)
Distributions.invlogccdf(o::DistributionStat, x) = Distributions.invlogccdf(o.d, x)
Distributions.isplatykurtic(o::DistributionStat) = Distributions.isplatykurtic(o.d)
Distributions.ismesokurtic(o::DistributionStat) = Distributions.ismesokurtic(o.d)

Base.rand(o::DistributionStat) = Distributions.rand(o.d)
Base.rand(o::DistributionStat, n_or_dims) = Distributions.rand(o.d, n_or_dims)
Base.rand!(o::DistributionStat, arr) = Distributions.rand!(o.d, arr)
