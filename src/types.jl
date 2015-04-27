#------------------------------------------------------------------# OnlineStat
abstract OnlineStat

# summary/
abstract ScalarStat <: OnlineStat

# parametricdensity/
abstract UnivariateFitDistribution <: ScalarStat

