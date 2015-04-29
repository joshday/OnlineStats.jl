module OnlineStats

using Docile
@document

import Compat: @compat
import Distributions:
    Continuous, Discrete, Univariate, Multivariate,
    Bernoulli, Beta, Binomial, Dirichlet, Exponential, Gamma, Multinomial,
    MvNormal, Normal,
    fit_dirichlet!,
    MixtureModel,
    pdf, cdf, logpdf, loglikelihood, probs, components
# import PDMats  # Why is this needed?
import DataFrames: DataFrame, names!
import Base: copy, merge, merge!, show, quantile
import StatsBase: nobs, skewness, kurtosis


#-----------------------------------------------------------------------------#
# Exports
#-----------------------------------------------------------------------------#
export
    # abstract types
    OnlineStat,
    ScalarOnlineStat,
    Weighting,
    EqualWeighting,
    ExponentialWeighting,

    # concrete types
    Mean,
    Var,
    Extrema,
    Summary,
    QuantileMM,
    QuantileSGD,
    FiveNumberSummary,
    CovarianceMatrix,
    FitBernoulli,
    FitBeta,
    FitBinomial,
    FitDirichlet,
    FitExponential,
    FitGamma,
    FitMultinomial,
    FitMvNormal,

    # functions
    nobs,
    update!,
    state,
    statenames,
    onlinefit,
    tracedata,
    em, # offline EM algorithm for Normal mixture
    smooth,
    weighting


#-----------------------------------------------------------------------------#
# Source files
#-----------------------------------------------------------------------------#
# Abstract Types
include("types.jl")
include("weighting.jl")

include("weighting.jl")

# Other
# include("tracedata.jl")
include("common.jl")

# Summary Statistics
include("summary/mean.jl")
include("summary/var.jl")
# include("summary/extrema.jl")
# include("summary/summary.jl")
# include("summary/moments.jl")
# include("summary/quantilesgd.jl")
# include("summary/quantilemm.jl")
# include("summary/fivenumber.jl")

# Parametric Density
include("distributions/bernoulli.jl")
include("distributions/beta.jl")
include("distributions/binomial.jl")
include("distributions/dirichlet.jl")
include("distributions/exponential.jl")
include("distributions/gamma.jl")
include("distributions/multinomial.jl")
# include("distributions/mvnormal.jl")
# include("distributions/normal.jl")

# Density Estimation
# include("densityestimation/offlinenormalmix.jl")
# include("densityestimation/normalmix.jl")

# Linear Model
# include("linearmodel/sweep.jl")
# include("linearmodel/linreg.jl")
# include("linearmodel/sparsereg.jl")
# include("linearmodel/ridge.jl")

# GLM
# include("glm/logisticregsgd.jl")
# include("glm/logisticregmm.jl")
# include("glm/logisticregsn.jl")

# Quantile Regression
# include("quantileregression/quantregsgd.jl")
# include("quantileregression/quantregmm.jl")

# Multivariate
include("multivariate/covmatrix.jl")

end # module
