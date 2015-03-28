# Author: Josh Day <emailjoshday@gmail.com>

export OnlineFitBernoulli

#-----------------------------------------------------------------------------#
#-----------------------------------------------------# OnlineFitBernoulli Type
type OnlineFitBernoulli <: DiscreteUnivariateOnlineStat
    d::Distributions.Bernoulli
    n1::Int64
    n::Int64
    nb::Int64
end

function onlinefit(::Type{Bernoulli}, y::Vector{Int64})
    n::Int64 = length(y)
    OnlineFitBernoulli(fit(Bernoulli, y), sum(y), n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::OnlineFitBernoulli, newdata::Vector{Int64})
    obj.n1 += sum(newdata)
    obj.n += length(newdata)
    obj.d = Bernoulli(obj.n1 / obj.n)
    obj.nb += 1
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::OnlineFitBernoulli)
    names = [:p, :n, :nb]
    estimates = [obj.d.p, obj.n, obj.nb]
    return([names estimates])
end


#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
function Base.show(io::IO, obj::OnlineFitBernoulli)
    @printf(io, "OnlineFitBernoulli\n")
    @printf(io, " * p: %f\n", obj.d.p)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
x1 = rand(Bernoulli(.7), 100)
obj = OnlineStats.onlinefit(Bernoulli, x1)
OnlineStats.state(obj)

x2 = rand(Bernoulli(.7), 100)
OnlineStats.update!(obj, x2)
OnlineStats.state(obj)

