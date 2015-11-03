module OnlineStats

import Distributions
import Distributions:
    Bernoulli, Beta, Binomial, Cauchy, Dirichlet, Exponential, Gamma, LogNormal,
    Multinomial, MvNormal, Normal, MixtureModel, Poisson, FDist, TDist,
    fit_dirichlet!, Univariate, Continuous, UnivariateDistribution,
    probs, components, logpdf, pdf, cdf, skewness, kurtosis, loglikelihood
import Base: copy, merge, merge!, show, quantile, maximum, minimum, push!, mean, var, std
import StatsBase
import StatsBase: nobs, coef, coeftable, CoefTable, confint, predict, stderr, vcov, fit
import MultivariateStats
import ArrayViews: view, rowvec_view



#-----------------------------------------------------------------------------#
# Exports
#-----------------------------------------------------------------------------#
export
    # common types
    OnlineStat,
    # weighting
    Weighting, EqualWeighting, ExponentialWeighting, LearningRate, StochasticWeighting,
    # ported from streamstats
    BernoulliBootstrap, PoissonBootstrap, HyperLogLog,
    # summary
    Mean, Variance, Moments, Extrema, Summary, QuantileMM, QuantileSGD, FiveNumberSummary, Diff, QuantileSort,
    # multivariate
    CovarianceMatrix, Means, Variances, Diffs,
    # DistributionStat
    NormalMix, FitBernoulli, FitBeta, FitBinomial, FitCauchy, FitDirichlet, FitExponential,
    FitGamma, FitLogNormal, FitMultinomial, FitMvNormal, FitNormal, FitPoisson,
    # matrix
    ShermanMorrisonInverse, OnlineCholesky,
    # linearmodel
    OnlineFLS, LinReg, QuantRegMM, LogRegMM, LogRegSGD2, SparseReg, StepwiseReg,
    OnlineGLM,

    # stochasticmodel
    StochasticModel, StochasticModelCV,
    L2Regression, L1Regression, LogisticRegression, QuantileRegression,
    HuberRegression, SVMLike, PoissonRegression,
    SGD, SGDSparse, ProxGrad, RDA, SAG,
    Penalty, NoPenalty, L1Penalty, L2Penalty, ElasticNetPenalty, SCADPenalty,

    # functions

    nobs, coef, coeftable, predict, vcov, stderr, pca, # rather than using reexport
    update!,                # update one observation at a time using Weighting scheme
    distributionfit,        # easy constructor syntax for FitDist types
    state,                  # get state of object, typically Any[value, nobs(o)]
    statenames,             # corresponding names to state()
    weighting,              # get the Weighting of an object
    em,                     # Offline EM algorithm for Normal Mixtures
    sweep!,                 # Symmetric sweep operator
    estimatedCardinality,
    pca,                    # Get top d principal components from CovarianceMatrix
    replicates              # Get vector of replicates from <: Bootstrap


#-----------------------------------------------------------------------------#
# Source files
#-----------------------------------------------------------------------------#

include("log.jl")

# Common Types
include("types.jl")
include("weighting.jl")

# Other
include("common.jl")

# StochasticModel
include("stochasticmodel/stochasticmodel.jl")
include("stochasticmodel/penalty.jl")

include("stochasticmodel/algorithms/sgd.jl")
include("stochasticmodel/algorithms/prox_adagrad.jl")
include("stochasticmodel/algorithms/rda_adagrad.jl")
include("stochasticmodel/algorithms/mm_grad.jl")
include("stochasticmodel/algorithms/mm_rda.jl")

include("stochasticmodel/sparse.jl")
include("stochasticmodel/crossvalidate.jl")

# Summary Statistics
include("summary/mean.jl")
include("summary/var.jl")
include("summary/extrema.jl")
include("summary/summary.jl")
include("summary/moments.jl")
include("summary/quantilesgd.jl")
include("summary/quantilemm.jl")
include("summary/fivenumber.jl")
include("summary/diff.jl")

# Multivariate
include("multivariate/covmatrix.jl")
include("multivariate/means.jl")
include("summary/quantilesort.jl")
include("multivariate/vars.jl")
include("multivariate/diffs.jl")

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

# Matrix
include("matrix/sherman_morrison.jl")
include("matrix/cholesky.jl")

# Linear Model
include("linearmodel/sweep.jl")
include("linearmodel/linreg.jl")
include("linearmodel/sparsereg.jl")
include("linearmodel/stepwise.jl")
include("linearmodel/ofls.jl")
include("linearmodel/opca.jl")
include("linearmodel/opls.jl")

# GLM
include("glm/logisticregsgd2.jl")
include("glm/logisticregmm.jl")
# include("glm/canonical_link.jl")

# Quantile Regression
include("quantileregression/quantregmm.jl")

# ported from StreamStats
include("streamstats/hyperloglog.jl")
include("streamstats/bootstrap.jl")


export
    BiasVector,
    BiasMatrix
include("multivariate/bias.jl")

export
    @stream,
    update_get!
include("react.jl")

# using QuickStructs
# export
#     Window,
#     lags,
#     isfull,
#     capacity
# include("window.jl")


end # module


# include("stochasticmodel/testcode.jl")
