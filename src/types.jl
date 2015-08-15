#------------------------------------------------------------------# OnlineStat
abstract OnlineStat

abstract DistributionStat <: OnlineStat

abstract StochasticGradientStat <: OnlineStat



typealias VecF Vector{Float64}
typealias MatF Matrix{Float64}

# add some aliases for abstract arrays
typealias AVec{T} AbstractVector{T}
typealias AMat{T} AbstractMatrix{T}
typealias AVecF AVec{Float64}
typealias AMatF AMat{Float64}
