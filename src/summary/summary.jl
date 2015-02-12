# Author: Josh Day <emailjoshday@gmail.com>

export Summary


#------------------------------------------------------------------------------#
#----------------------------------------------------------------# Summary Type
type Summary <: ContinuousUnivariateOnlineStat
    mean::Float64
    var::Float64
    max::Float64
    min::Float64

    n::Int64
    nb::Int64
end


@doc doc"""
Create Summary object

fields: `mean`, `var`, `max`, `min`, `n`, `nb`
""" ->
function Summary(y::Vector)
    Summary(mean(y), var(y), maximum(y), minimum(y), length(y), 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::Summary, newdata::Vector)
    n1::Int = obj.n
    n2::Int = length(newdata)
    n::Int = n1 + n2
    μ1::Float64 = obj.mean
    μ2::Float64 = mean(newdata)
    δ::Float64 = μ2 - μ1
    ss1::Float64 = (n1 - 1) * obj.var
    ss2::Float64 = vecnorm(newdata - μ2) ^ 2

    obj.n = n
    obj.nb = obj.nb + 1
    obj.mean = μ1 + n2 / n * δ
    obj.var = (ss1 + ss2 + n1 * n2 / n * δ^2) / (n - 1)
    obj.max = maximum([obj.max, newdata])
    obj.min = minimum([obj.min, newdata])

    return obj
end


function update!(obj1::Summary, obj2::Summary)
    n1::Int = obj1.n
    n2::Int = obj2.n
    n::Int = n1 + n2
    μ1::Float64 = obj1.mean
    μ2::Float64 = obj2.mean
    δ::Float64 = μ2 - μ1
    ss1::Float64 = (n1 - 1) * obj1.var
    ss2::Float64 = (n2 - 1) * obj2.var

    obj1.n = n
    obj1.nb += obj2.nb
    obj1.mean += n2 /n * δ
    obj1.var = (ss1 + ss2 + n1 * n2 / n * δ^2) / (n - 1)
    obj1.max = maximum([obj1.max, obj2.max])
    obj1.min = minimum([obj1.min, obj2.min])
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function state(obj::Summary)
    println("mean = " * string(obj.mean))
    println(" var = " * string(obj.var))
    println(" max = " * string(obj.max))
    println(" min = " * string(obj.min))
    println("   n = " * string(obj.n))
    println("  nb = " * string(obj.nb))
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# x1 = rand(100)
# x2 = rand(112)
# x3 = rand(103)

# obj = OnlineStats.Summary(x1)
# OnlineStats.update!(obj, x2)
# OnlineStats.update!(obj, x3)

# OnlineStats.state(obj)

# obj2 = OnlineStats.Summary(rand(1000))
# update!(obj2, rand(11))
# update!(obj, obj2)

# OnlineStats.state(obj)
