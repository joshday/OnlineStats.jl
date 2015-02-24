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
    Moments(m, var(y), mean((y - m) .^ 3), mean((y - m) .^ 4), n, 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::Moments, x::Real)
    obj.n += 1

    n = obj.n

    δ = x - obj.m1
    δ_n = δ / n
    δ_n_sq = δ_n * δ_n
    term1 = δ * δ_n * (n - 1)

    obj.m1 += δ_n

    obj.m4 = ((n-1)*obj.m4 + term1 * δ_n_sq * (n * n - 3 * n + 3) +
               6 * δ_n_sq * obj.m2 - 4 * δ_n * obj.m3) / n

    obj.m3 = ((n-1)*obj.m3 + term1 * δ_n * (n - 2) - 3 * δ_n * obj.m2) / n

    obj.m2 = ((n-2) * obj.m2 +term1) / (n-1)
end

function update!(obj::Moments, newdata::Vector)
    for i in length(newdata)
        update!(obj, newdata[i])
    end
end


#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::Moments)
    m1::Float64 = obj.m1
    m2::Float64 = obj.m2
    m3::Float64 = obj.m3
    m4::Float64 = obj.m4
    n::Int64 = obj.n

    names = [:m1, :m2, :m3, :m4, :skewness, :kurtosis, :n, :nb]
    estimates = [m1, m2, m3, m4, m3 / m2 ^ 1.5, m4/ m2 ^ 2 - 3.0, obj.n, obj.nb]

    return([names estimates])
end


#------------------------------------------------------------------------------#
#----------------------------------------------------------# Interactive Testing
# y1 = rand(1000)
# y2 = rand(101)



# obj = OnlineStats.Moments(y1)
# OnlineStats.update!(obj, y2)

# y3 = rand(120)
# OnlineStats.update!(obj, y3)

# y = [y1, y2, y3]

# display(OnlineStats.state(obj))

# println("")
# println(mean((y - mean(y)) .^ 2))
# println(mean((y - mean(y)) .^ 3))
# println(mean((y - mean(y)) .^ 4))
# println("")
# println(mean(y))
# println(skewness(y))
# println(kurtosis(y))

