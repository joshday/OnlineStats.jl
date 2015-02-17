# Author: Josh Day <emailjoshday@gmail.com>

#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# NewType
type FiveNumberSummary
    min::Float64
    quantile::QuantileSGD
    max::Float64
    n::Int64
    nb::Int64
end

# default constructor(s)
function FiveNumberSummary(y::Vector, r=.7)
    FiveNumberSummary(minimum(y), QuantileSGD(y, r = r), maximum(y),
                      length(y), 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::FiveNumberSummary, newdata::Vector)
    n2 = length(newdata)
    for i in 1:n2
        update!(obj.quantile, [newdata[i]])
    end
    obj.min = minimum([obj.min, newdata])
    obj.max = maximum([obj.max, newdata])
    obj.n += n2
    obj.nb += 1
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::FiveNumberSummary)
    names = [:min, :q25, :q50, :q75, :max, :n, :nb]
    estimates = [obj.min, obj.quantile.est, obj.max, obj.n, obj.nb]
    return([names estimates])
end




#-----------------------------------------------------------------------------#
#--------------------------------------------------------# Interactive testing

y1 = rand(1000)
obj = OnlineStats.FiveNumberSummary(y1)
display(OnlineStats.state(obj))

y2 = rand(1000)
OnlineStats.update!(obj, y2)
display(OnlineStats.state(obj))

