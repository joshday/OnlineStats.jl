#------------------------------------------------------# Type and Constructors
type FitDirichlet <: MultivariateFitDistribution
    d::Distributions.Dirichlet
    slogp::Vector{Float64}
    n::Int64
end

# First batch may give incorrect estimates (issue with fit(Dirichlet, y)).
# Since suffstats are correct, second batch estimates looks good.
function onlinefit{T <: Real}(::Type{Dirichlet}, y::Matrix{T})
    n::Int64 = size(y, 2)
    FitDirichlet(fit(Dirichlet, y), suffstats(Dirichlet, y).slogp / n, n)
end

FitDirichlet{T <: Real}(y::Matrix{T}) = onlinefit(Dirichlet, y)


#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::FitDirichlet, newdata::Matrix{T})
    n2 = size(newdata, 2)
    slogp = suffstats(Dirichlet, newdata).slogp / n2
    obj.n += n2
    obj.slogp += (n2 / obj.n) * (slogp - obj.slogp)
    α = obj.d.alpha
    obj.d = Distributions.fit_dirichlet!(obj.slogp, α)
end


#-----------------------------------------------------------------------# Base
Base.copy(obj::FitDirichlet) = FitDirichlet(obj.d, obj.slogp, obj.n)

