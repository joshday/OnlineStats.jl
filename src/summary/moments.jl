# Author: Josh Day <emailjoshday@gmail.com>

export Moments

#------------------------------------------------------------------------------#
#----------------------------------------------------------------# Moments Type
type Moments <: ContinuousUnivariateOnlineStat
    m1::Float64
    m2::Float64
    m3::Float64
    m4::Float64

    n::Int64
    nb::Int64
end

@doc* doc"""
    Usage: `Moments(y::Vector)`

    | Field         |  Description                 |
    |:--------------|:-----------------------------|
    | `m1::Float64` | $ \mu_1 $                    |
    | `m2::Float64` | $ \mu_2 $                    |
    | `m3::Float64` | $ \mu_3 $                    |
    | `m4::Float64` | $ \mu_4 $                    |
    | `n::Int64`    | number of observations used  |
    | `nb::Int64`   | number of batches used       |
    """ ->
function Moments(y::Vector)
    n::Int64 = length(y)
    m::Float64 = mean(y)
    Moments(m, var(y), mean((y - m) .^ 3), mean((y - m) .^ 4), length(y), 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::Moments, newdata::Vector)
    n1::Int64 = obj.n
    n2::Int64 = length(newdata)
    n::Int64 = n1 + n2

    m1::Float64 = obj.m1
    m2::Float64 = obj.m2
    m3::Float64 = obj.m3
    m4::Float64 = obj.m4

    ym1::Float64 = mean(newdata)
    ss2::Float64 = sum((newdata - ym1) .^ 2)
    ss3::Float64 = sum((newdata - ym1) .^ 3)
    ss4::Float64 = sum((newdata - ym1) .^ 4)

    δ::Float64 = ym1 - m1
    δ_n::Float64 = δ / n
    n1n2_n::Float64 = (n1 * n2) / n

    m1 += n2 * δ_n
    m4 = (n1*m4 + ss4 + n1 * n2 * (n1^2 - n1 * n2 + n2^2) * δ * δ_n^3 +
         6 * (n1^2 * ss2 + n2^2 * (n1-1) * m2) * δ_n^2 +
         4 * (n1 * ss3 - n2 * n1*m3 * δ_n)) / n

    m4 = m4 / n

    m3 = (n1 * m3 + ss3 + n1n2_n * (n1 - n2) / n * δ^3 +
        3 / n * (n1 * ss2 - n2 * (n1-1)*m2) * δ) / n

    m2 = ((n1-1) * m2 + ss2 + n1n2_n * δ^2) / (n - 1)

    obj.m1= m1
    obj.m2 = m2
    obj.m3 = m3
    obj.m4 = m4
    obj.n = n
    obj.nb += 1
end

#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::Moments)
    m1::Float64 = obj.m1
    m2::Float64 = obj.m2
    m3::Float64 = obj.m3
    m4::Float64 = obj.m4
    n::Int64 = obj.n

    println("*Central Moments:")
    println(join(("m1 = ", m1)))
    println(join(("m2 = ", m2)))
    println(join(("m3 = ", m3)))
    println(join(("m4 = ", m4)))
    println("")
    println("*Statistics:")
    println(join(("skewness = ", m3 / m2 ^ 1.5)))
    println(join(("kurtosis = ", m4 / m2 ^ 2 - 3.0)))
    println(join(("n = ", obj.n[end])))
    println(join(("nb = ", obj.nb[end])))
end


#------------------------------------------------------------------------------#
#----------------------------------------------------------# Interactive Testing
y1 = rand(100)
y2 = rand(101)
y3 = rand(120)

y = [y1, y2, y3]

obj = OnlineStats.Moments(y1)
OnlineStats.update!(obj, y2)
OnlineStats.update!(obj, y3)

OnlineStats.state(obj)

println("")
println(mean((y - mean(y)) .^ 2))
println(mean((y - mean(y)) .^ 3))
println(mean((y - mean(y)) .^ 4))
println("")
println(skewness(y))
println(kurtosis(y))


