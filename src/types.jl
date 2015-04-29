#------------------------------------------------------------------# OnlineStat
abstract OnlineStat

# Possibly multiple parameters that are all scalars
abstract ScalarStat <: OnlineStat

# may include scalar and vector parameters
abstract VectorStat <: OnlineStat

# at least one parameter is a matrix
abstract MatrixStat <: OnlineStat

# For Base.show(), DataFrame(), tracedata()
NonMatrixStat = Union(ScalarStat, VectorStat)


typealias VecF Vector{Float64}
typealias MatF Matrix{Float64}
