#-----------------------------------------------------------------------------#
#------------------------------------------------------------------# OnlineStat
abstract OnlineStat{
    F <: Distributions.VariateForm,
    S <: Distributions.ValueSupport
}

typealias DiscreteUnivariateOnlineStat OnlineStat{
    Distributions.Univariate,
    Distributions.Discrete
}

typealias ContinuousUnivariateOnlineStat OnlineStat{
    Distributions.Univariate,
    Distributions.Continuous
}

typealias DiscreteMultivariateOnlineStat OnlineStat{
    Distributions.Multivariate,
    Distributions.Discrete
}

typealias ContinuousMultivariateOnlineStat OnlineStat{
    Distributions.Multivariate,
    Distributions.Continuous
}


#-----------------------------------------------------------------------------#
#-------------------------------------------------------------------# Penalties
abstract Penalty
abstract Unpenalized <: Penalty
abstract Lasso <: Penalty
abstract Ridge <: Penalty
abstract ElasticNet <: Penalty
