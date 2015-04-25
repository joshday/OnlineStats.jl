#-----------------------------------------------------------------------------#
#------------------------------------------------------------------# OnlineStat
abstract OnlineStat{F <: Distributions.VariateForm}

# VariateForm defines the dimensions of the parameter of interest
typealias UnivariateOnlineStat    OnlineStat{Distributions.Univariate}
typealias MultivariateOnlineStat  OnlineStat{Distributions.Multivariate}
typealias MatrixvariateOnlineStat OnlineStat{Distributions.Matrixvariate}


#-----------------------------------------------------------------------------#
#-------------------------------------------------------------------# Penalties
abstract Penalty
abstract Unpenalized <: Penalty
abstract Lasso <: Penalty
abstract Ridge <: Penalty
abstract ElasticNet <: Penalty
abstract Stepwise <: Penalty
