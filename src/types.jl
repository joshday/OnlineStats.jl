#------------------------------------------------------------------# OnlineStat
abstract OnlineStat

# Possibly multiple parameters that are all scalars
abstract ScalarStat <: OnlineStat

# Estimation of parametric distribution
abstract DistributionStat <: OnlineStat
