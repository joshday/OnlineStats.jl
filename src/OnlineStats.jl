module OnlineStats

using Docile
@document

import Distributions:
    Continuous, Discrete, Univariate, Multivariate,
    Bernoulli, Beta, Binomial, Dirichlet, Exponential, Gamma, Multinomial,
    MvNormal, Normal,
    MixtureModel,
    pdf, cdf, logpdf, loglikelihood, probs, components
# import PDMats  # Why is this needed?
import DataFrames: DataFrame
import Base: copy, merge, merge!, show, quantile
import StatsBase: nobs, skewness, kurtosis


#-----------------------------------------------------------------------------#
# Exports
#-----------------------------------------------------------------------------#
export
    # abstract types
    OnlineStat,
    ScalarOnlineStat,

    # concrete types
    Mean,
    Var,
    Extrema,
    Summary,
    QuantileMM,
    QuantileSGD,
    FiveNumberSummary,

    # functions
    nobs,
    update!,
    state,
    statenames,
    onlinefit,
    tracedata,
    em                  # offline EM algorithm for Normal mixture


#-----------------------------------------------------------------------------#
# Source files
#-----------------------------------------------------------------------------#
# Abstract Types
include("types.jl")

include("weighting.jl")

# Other
# include("tracedata.jl")
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

# Parametric Density
# include("parametricdensity/bernoulli.jl")
# include("parametricdensity/beta.jl")
# include("parametricdensity/binomial.jl")
# include("parametricdensity/dirichlet.jl")
# include("parametricdensity/exponential.jl")
# include("parametricdensity/gamma.jl")
# include("parametricdensity/multinomial.jl")
# include("parametricdensity/mvnormal.jl")
# include("parametricdensity/normal.jl")

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
# include("multivariate/covmatrix.jl")

end # module
