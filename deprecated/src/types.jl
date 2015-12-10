#------------------------------------------------------------------# OnlineStat
abstract OnlineStat

abstract DistributionStat <: OnlineStat
abstract StochasticGradientStat <: OnlineStat

abstract Penalty
abstract ModelDefinition
abstract SGAlgorithm



typealias VecF Vector{Float64}
typealias MatF Matrix{Float64}
typealias AVec{T} AbstractVector{T}
typealias AMat{T} AbstractMatrix{T}
typealias AVecF AVec{Float64}
typealias AMatF AMat{Float64}
