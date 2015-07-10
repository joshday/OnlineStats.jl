module OnlineStats

# using things that are rarely used or very clear where functions come from
using Docile
@document
using Reexport.@reexport
@reexport using StatsBase
using Requires.@require
using Compat

import MultivariateStats: PCA
import Base: copy, merge, merge!, show, quantile, maximum, minimum
import StatsBase: nobs, coef, coeftable, CoefTable, confint, predict, stderr, vcov, fit
import ArrayViews: view, rowvec_view

# import MathProgBase: AbstractMathProgSolver
# import Convex, SCS

#-----------------------------------------------------------------------------#
# Exports
#-----------------------------------------------------------------------------#
export
    # common types
    OnlineStat,
    ScalarOnlineStat,
    Weighting,
    EqualWeighting,
    ExponentialWeighting,
    StochasticWeighting,

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
    state,                 # get state of object, typically Any[value, nobs(o)]
    statenames,            # corresponding names to state()
    weighting,             # get the Weighting of an object
    onlinefit,             # higher-level syntax for constructors
    em,                    # Offline EM algorithm for Normal Mixtures
    sweep!,                # Symmetric sweep operator
    estimatedCardinality,
    pca                    # Get top d principal components from CovarianceMatrix


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
@require Distributions begin
    include(Pkg.dir("OnlineStats", "src", "distributions/common_dist.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/bernoulli.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/beta.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/binomial.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/cauchy.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/dirichlet.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/exponential.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/gamma.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/multinomial.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/mvnormal.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/normal.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/offlinenormalmix.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/normalmix.jl"))
    include(Pkg.dir("OnlineStats", "src", "distributions/poisson.jl"))
end

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



end # module
