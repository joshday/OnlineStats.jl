export OnlineFitDirichlet

#------------------------------------------------------------------------------#
#-----------------------------------------------------# OnlineFitDirichlet Type
type OnlineFitDirichlet <: ContinuousUnivariateOnlineStat
    d::Distributions.Dirichlet
    slogp::Vector{Float64}
    n::Int64
    nb::Int64
end

function onlinefit{T<:Real}(::Type{Dirichlet}, y::Matrix{T})
    n::Int64 = size(y, 2)
    OnlineFitDirichlet(fit(Dirichlet, y), suffstats(Dirichlet, y).slogp / n, n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::OnlineFitDirichlet, newdata::Matrix{T})
    n2 = size(newdata, 2)
    slogp = suffstats(Dirichlet, newdata).slogp / n2
    obj.n += n2
    obj.slogp += (n2 / obj.n) * (slogp - obj.slogp)
    α = obj.d.alpha
    obj.d = Distributions.fit_dirichlet!(obj.slogp, α)
    obj.nb += 1
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitDirichlet)
    names = [[symbol("α$i") for i in 1:length(obj.d.alpha)], :n, :nb]
    estimates = [obj.d.alpha, obj.n, obj.nb]
    return([names estimates])
end



#----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# Base
Base.copy(obj::OnlineFitDirichlet) =
    OnlineFitDirichlet(obj.d, obj.slogp, obj.n, obj.nb)

function Base.show(io::IO, obj::OnlineFitDirichlet)
    @printf(io, "OnlineFit (nobs = %i)\n", obj.n)
    show(obj.d)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive testing
α = [1, 10, 4, 8, 2]
x1 = rand(Dirichlet(α), 100)
obj = OnlineStats.onlinefit(Dirichlet, x1)
OnlineStats.state(obj)

for i in 1:10000
    x2 = rand(Dirichlet(α), 100)
    OnlineStats.update!(obj, x2)
end

OnlineStats.state(obj)

# obj = OnlineStats.onlinefit(Normal, [x1, x2])
# OnlineStats.state(obj)

