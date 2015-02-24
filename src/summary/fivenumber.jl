# Author: Josh Day <emailjoshday@gmail.com>

export FiveNumberSummary

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
    update!(obj.quantile, newdata)
    obj.min = minimum([obj.min, newdata])
    obj.max = maximum([obj.max, newdata])
    obj.n += n2
    obj.nb += 1
end

update(obj::FiveNumberSummary, x::Real) = update!(obj, [x])


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::FiveNumberSummary)
    names = [:min, :q25, :q50, :q75, :max, :n, :nb]
    estimates = [obj.min, obj.quantile.est, obj.max, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#--------------------------------------------------------------------# Boxplot
function state(obj::FiveNumberSummary)
    names = [:min, :q25, :q50, :q75, :max, :n, :nb]
    estimates = [obj.min, obj.quantile.est, obj.max, obj.n, obj.nb]
    return([names estimates])
end


function Gadfly.plot(obj::FiveNumberSummary)
    s = state(obj)[1:5, 2]
    iqr = obj.quantile.est[3] - obj.quantile.est[1]
   Gadfly.plot(lower_fence = [maximum((s[2] - 1.5 * iqr, s[1]))],
               lower_hinge = [s[2]],
               middle = [s[3]],
               upper_hinge = [s[4]],
               upper_fence = [minimum((s[4] + 1.5 * iqr, s[5]))],
               # outliers = [s[1], s[5]],
               x = ["Data"], Gadfly.Geom.boxplot)
end


#-----------------------------------------------------------------------------#
#--------------------------------------------------------# Interactive testing

# y1 = randn(1000)*2 + 5
# obj = OnlineStats.FiveNumberSummary(y1)
# display(OnlineStats.state(obj))

# y2 = randn(1000)*2+ 5
# OnlineStats.update!(obj, y2)
# display(OnlineStats.state(obj))

# y3 = randn(1)*2 + 5
# OnlineStats.update!(obj, y3)
# display(OnlineStats.state(obj))
# Gadfly.plot(obj)

# obj.min
# obj.max

