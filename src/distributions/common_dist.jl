import Clustering  # Used in offline em algorithm for normal mixture
import Distributions:
    # Distributions
    Bernoulli, Beta, Binomial, Cauchy, Dirichlet, Exponential, Gamma, Multinomial,
    MvNormal, Normal, MixtureModel, Poisson, FDist, TDist,

    # Other
    fit_dirichlet!, Univariate, Continuous, UnivariateDistribution,

    # Methods for DistributionStat
    pdf, cdf, logpdf, loglikelihood, probs, components, params, succprob,
    failprob, scale, location, shape, rate, ncategories, ntrials, dof,
    mode, modes, skewness, kurtosis, isplatykurtic, ismesokurtic,
    entropy, mgf, cf, insupport, logcdf, ccdf,
    logccdf, quantile, cquantile, invlogcdf, invlogccdf, rand, rand!, median

#------------------------------------------------------------# DistributionStat
function Base.show(io::IO, o::DistributionStat)
    println("Online " * string(typeof(o)) * ", nobs:" * string(nobs(o)))
    show(o.d)
end

statenames(o::DistributionStat) = [:dist, :nobs]
state(o::DistributionStat) = [o.d, o.n]

params(o::DistributionStat) = params(o.d)
succprob(o::DistributionStat) = succprob(o.d)
failprob(o::DistributionStat) = failprob(o.d)
scale(o::DistributionStat) = scale(o.d)
# location(o::DistributionStat) = location(o.d)  # doesn't apply to any distribution yet
shape(o::DistributionStat) = shape(o.d)
rate(o::DistributionStat) = rate(o.d)
ncategories(o::DistributionStat) = ncategories(o.d)
ntrials(o::DistributionStat) = ntrials(o.d)
# dof(o::DistributionStat) = dof(o.d)  # doesn't apply to any distribution yet

mean(o::DistributionStat) = mean(o.d)
var(o::DistributionStat) = var(o.d)
std(o::DistributionStat) = std(o.d)
median(o::DistributionStat) = median(o.d)
mode(o::DistributionStat) = mode(o.d)
modes(o::DistributionStat) = modes(o.d)
skewness(o::DistributionStat) = skewness(o.d)
kurtosis(o::DistributionStat) = kurtosis(o.d)
isplatykurtic(o::DistributionStat) = isplatykurtic(o.d)
ismesokurtic(o::DistributionStat) = ismesokurtic(o.d)
entropy(o::DistributionStat) = entropy(o.d)

mgf(o::DistributionStat, x) = mgf(o.d, x)
cf(o::DistributionStat, x) = cf(o.d, x)
insupport(o::DistributionStat, x) = insupport(o.d, x)
pdf(o::DistributionStat, x) = pdf(o.d, x)
logpdf(o::DistributionStat, x) = logpdf(o.d, x)
loglikelihood(o::DistributionStat, x) = loglikelihood(o.d, x)
cdf(o::DistributionStat, x) = cdf(o.d, x)
logcdf(o::DistributionStat, x) = logcdf(o.d, x)
ccdf(o::DistributionStat, x) = ccdf(o.d, x)
logccdf(o::DistributionStat, x) = logccdf(o.d, x)
quantile(o::DistributionStat, τ) = quantile(o.d, τ)
cquantile(o::DistributionStat, τ) = cquantile(o.d, τ)
invlogcdf(o::DistributionStat, x) = invlogcdf(o.d, x)
invlogccdf(o::DistributionStat, x) = invlogccdf(o.d, x)

rand(o::DistributionStat) = rand(o.d)
rand(o::DistributionStat, n_or_dims) = rand(o.d, n_or_dims)
rand!(o::DistributionStat, arr) = rand!(o.d, arr)
