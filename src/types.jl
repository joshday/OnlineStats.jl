#-----------------------------------------------------------------------------#
#-------------------------------------------------------------# OnlineAlgorithm
abstract OnlineAlgorithm
abstract Analytical <: OnlineAlgorithm  # Analytical update
abstract SGD <: OnlineAlgorithm         # Stochastic gradient descent
abstract SGD2 <: OnlineAlgorithm        # 2nd order SGD
abstract OEM <: OnlineAlgorithm         # Online EM algorithm
abstract OMM <: OnlineAlgorithm         # Online MM algorithm


#-----------------------------------------------------------------------------#
#------------------------------------------------------------------# OnlineStat
abstract OnlineStat{
    A <: OnlineAlgorithm,
    F <: Distributions.VariateForm,
    S <: Distributions.ValueSupport
}

typealias DiscreteUnivariateOnlineStat{A <: OnlineAlgorithm} OnlineStat{
    A,
    Distributions.Univariate,
    Distributions.Discrete
}

typealias ContinuousUnivariateOnlineStat{A <: OnlineAlgorithm} OnlineStat{
    A,
    Distributions.Univariate,
    Distributions.Continuous
}

typealias DiscreteMultivariateOnlineStat{A <: OnlineAlgorithm} OnlineStat{
    A,
    Distributions.Multivariate,
    Distributions.Discrete
}

typealias ContinuousMultivariateOnlineStat{A <: OnlineAlgorithm} OnlineStat{
    A,
    Distributions.Multivariate,
    Distributions.Continuous
}

typealias DiscreteMatrixOnlineStat{A <: OnlineAlgorithm} OnlineStat{
    A,
    Distributions.Matrixvariate,
    Distributions.Discrete
}

typealias ContinuousMatrixOnlineStat{A <: OnlineAlgorithm} OnlineStat{
    A,
    Distributions.Matrixvariate,
    Distributions.Continuous
}


#-----------------------------------------------------------------------------#
#-------------------------------------------------------------------# Penalties
abstract Penalty
abstract Unpenalized <: Penalty
abstract Lasso <: Penalty
abstract Ridge <: Penalty
abstract ElasticNet <: Penalty
abstract Stepwise <: Penalty
