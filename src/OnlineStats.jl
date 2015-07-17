module OnlineStats

using Docile.@document
@document
using Reexport.@reexport
@reexport using StatsBase
using Compat


import Clustering  # Used in offline em algorithm for normal mixture
import Distributions
import Distributions:
    # Distributions
    Bernoulli, Beta, Binomial, Cauchy, Dirichlet, Exponential, Gamma, LogNormal, Multinomial,
    MvNormal, Normal, MixtureModel, Poisson, FDist, TDist,

    # Other
    fit_dirichlet!, Univariate, Continuous, UnivariateDistribution,

    # Methods for DistributionStat
    pdf, cdf, logpdf, loglikelihood, probs, components, params, succprob,
    failprob, scale, location, shape, rate, ncategories, ntrials, dof,
    mode, modes, skewness, kurtosis, isplatykurtic, ismesokurtic,
    entropy, mgf, cf, insupport, logcdf, ccdf,
    logccdf, quantile, cquantile, invlogcdf, invlogccdf, rand, rand!, median
import Base: copy, merge, merge!, show, quantile, maximum, minimum, push!, mean, var, std
import StatsBase: nobs, coef, coeftable, CoefTable, confint, predict, stderr, vcov, fit
import MultivariateStats
import ArrayViews: view, rowvec_view

# import MathProgBase: AbstractMathProgSolver
# import Convex, SCS

#-----------------------------------------------------------------------------#
# Exports
#-----------------------------------------------------------------------------#
export
    # common types
    OnlineStat,
    Weighting,
    EqualWeighting,
    ExponentialWeighting,
    StochasticWeighting,
    BernoulliBootstrap,
    PoissonBootstrap,

    # <: OnlineStat
    Mean,
    Variance,
    Moments,
    Extrema,
    Summary,
    QuantileMM,
    QuantileSGD,
    FiveNumberSummary,

    CovarianceMatrix,
    Means,
    Variances,
    AnalyticalPCA,

    NormalMix,
    FitBernoulli,
    FitBeta,
    FitBinomial,
    FitCauchy,
    FitDirichlet,
    FitExponential,
    FitGamma,
    FitLogNormal,
    FitMultinomial,
    FitMvNormal,
    FitNormal,
    FitPoisson,

    OnlineFLS,
    LinReg,
    LinRegSGD,
    QuantRegSGD,
    QuantRegMM,
    LogRegMM,
    LogRegSGD,
    LogRegSGD2,  # Second-order SGD: This is the "winner" compared to the other two
    SparseReg,
    StepwiseReg,

    HyperLogLog,
    Adagrad,
    SquareLoss,
    LogisticLoss,
    L1Reg,
    L2Reg,
    LogisticLink,

    # functions
    update!,               # update one observation at a time using Weighting scheme
    updatebatch!,          # update by batch, giving each observation equal weight
    onlinefit!,            # run through data updating with mini batches
    tracefit!,             # return vector, each element is OnlineStat after updating with minibatch
    state,                 # get state of object, typically Any[value, nobs(o)]
    statenames,            # corresponding names to state()
    weighting,             # get the Weighting of an object
    onlinefit,             # higher-level syntax for constructors
    em,                    # Offline EM algorithm for Normal Mixtures
    sweep!,                # Symmetric sweep operator
    estimatedCardinality,
    pca,                   # Get top d principal components from CovarianceMatrix
    replicates             # Get vector of replicates from <: Bootstrap


#-----------------------------------------------------------------------------#
# Source files
#-----------------------------------------------------------------------------#

include("log.jl")

# Common Types
include("types.jl")
include("weighting.jl")

# Other
include("common.jl")

# Summary Statistics
include("summary/mean.jl")
include("summary/var.jl")
include("summary/extrema.jl")
include("summary/summary.jl")
include("summary/moments.jl")
include("summary/quantilesgd.jl")
include("summary/quantilemm.jl")
include("summary/fivenumber.jl")

# Multivariate
include("multivariate/covmatrix.jl")
include("multivariate/means.jl")
include("multivariate/vars.jl")
include("multivariate/analyticalpca.jl")

# Parametric Density
include("distributions/common_dist.jl")
include("distributions/bernoulli.jl")
include("distributions/beta.jl")
include("distributions/binomial.jl")
include("distributions/cauchy.jl")
include("distributions/dirichlet.jl")
include("distributions/exponential.jl")
include("distributions/gamma.jl")
include("distributions/lognormal.jl")
include("distributions/multinomial.jl")
include("distributions/mvnormal.jl")
include("distributions/normal.jl")
include("distributions/offlinenormalmix.jl")
include("distributions/normalmix.jl")
include("distributions/poisson.jl")


# Linear Model
include("linearmodel/sweep.jl")
include("linearmodel/linregsgd.jl")
include("linearmodel/linreg.jl")
include("linearmodel/sparsereg.jl")
include("linearmodel/stepwise.jl")
include("linearmodel/ofls.jl")
include("linearmodel/opca.jl")
include("linearmodel/opls.jl")

# GLM
include("glm/logisticregsgd.jl")
include("glm/logisticregsgd2.jl")
include("glm/logisticregmm.jl")

# Quantile Regression
include("quantileregression/quantregsgd.jl")
include("quantileregression/quantregmm.jl")

# ported from StreamStats
include("streamstats/hyperloglog.jl")
include("streamstats/adagrad.jl")
include("streamstats/bootstrap.jl")

export BiasVector, BiasMatrix
include("multivariate/bias.jl")



end # module
