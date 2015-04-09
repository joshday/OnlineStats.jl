export OnlineFitMultinomial

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type OnlineFitMultinomial <: DiscreteMultivariateOnlineStat
    d::Distributions.Multinomial
    means::Vector{Float64}
    n::Int64
    nb::Int64
end

function onlinefit(::Type{Multinomial}, x::Matrix)
    n::Int64 = size(x, 2)
    OnlineFitMultinomial(fit(Multinomial, x), vec(mean(x, 2)), n, 1)
end



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineFitMultinomial, x::Matrix)
    p, n = size(x)
    obj.n += n
    obj.means += (n / obj.n) * (vec(mean(x, 2)) - obj.means)
    obj.d = Multinomial(obj.d.n, obj.means / obj.d.n)
    obj.nb += 1
end

#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitMultinomial)
    names = [:ntrials,[symbol("p$i") for i=1:length(obj.d.p)],  :n, :nb]
    estimates = [obj.d.n, obj.d.p, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::OnlineFitMultinomial) =
    OnlineFitMultinomial(obj.d, obj.means, obj.n, obj.nb)

function Base.show(io::IO, obj::OnlineFitMultinomial)
    @printf(io, "OnlineFit (nobs = %i)\n", obj.n)
    show(obj.d)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
x1 = rand(Multinomial(20, [.2, .3, .5]), 100)
obj1 = OnlineStats.onlinefit(Multinomial, x1)
OnlineStats.state(obj1)

x2 = rand(Multinomial(20, [.2, .3, .5]), 103)
obj2 = OnlineStats.onlinefit(Multinomial, x2)
OnlineStats.state(obj2)

for i in 1:1000
    x3 = rand(Multinomial(20, [.2, .3, .5]), 103)
    OnlineStats.update!(obj1, x3)
end


