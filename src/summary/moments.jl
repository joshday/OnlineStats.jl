export Moments

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type Moments <: ContinuousUnivariateOnlineStat
    m1m2::Var
    m3::Float64
    m4::Float64
    n::Int64
end

function Moments(y::Vector)
    m::Float64 = mean(y)
    Moments(Var(y), mean((y - m) .^ 3), mean((y - m) .^ 4), length(y))
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::Moments, y::Vector)
    vary = Var(y)
    m1, m2, m3, m4 = obj.m1m2.mean, obj.m1m2.var, obj.m3, obj.m4
    m1_, m2_ = vary.mean, vary.var
    m3_, m4_ = mean((y - m1_) .^ 3), mean((y - m1_) .^ 4)
    n1 = obj.n
    n2 = vary.n
    n = n1 + n2
    γ = n2 / n
    δ = m1_ - m1

    update!(obj.m1m2, y)

    m3 += γ * (m3_ - m3) + γ * (1 - γ) * ((n1 - n2) / n) * δ^3
    m3 += 3 * γ * ((1 - γ) * m2_ - γ * m2) * δ

    c = (1 - γ)^2 - γ*(1-γ) + γ^2
    m4 += γ * (m4_ - m4) + γ * (1 - γ) * δ *
        ((c * δ^3) + 6 * (m2_ + γ * (m2 - m2_))*δ  + 4 * (m3_ - m3))

    obj.m3 = m3
    obj.m4 = m4
    obj.n += n2
end

update!(obj::Moments, y::Real) = update!(obj, [y])


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::Moments)
    n::Int64 = obj.n
    m1::Float64 = obj.m1m2.mean
    ubvar::Float64 = obj.m1m2.var * (n / (n-1))
    m3::Float64 = obj.m3
    m4::Float64 = obj.m4

    names = [:mean, :var, :skewness, :kurtosis, :n]
    estimates = [m1,
                 ubvar,
                 m3 / ubvar ^ 1.5,
                 m4/ ubvar ^ 2 - 3.0, n]

    return([names estimates])
end


#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.mean(obj::Moments) = return obj.m1m2.mean

Base.var(obj::Moments) = return obj.m1m2  * (obj.n / (obj.n - 1))

function StatsBase.skewness(obj::Moments)
    return obj.m3 / var(obj)^1.5
end

function StatsBase.kurtosis(obj::Moments)
    return obj.m4 / var(obj)^2 - 3.0
end

Base.copy(obj::Moments) = Var(obj.m1m2, obj.m3, obj.m4, obj.n)

function Base.show(io::IO, obj::Moments)
    @printf(io, "Online Moments\n")
    @printf(io, " * Mean:     %f\n", mean(obj))
    @printf(io, " * Variance: %f\n", var(obj))
    @printf(io, " * M3:       %f\n", obj.m3)
    @printf(io, " * M4:       %f\n", obj.m4)
    @printf(io, " * N:        %d\n", obj.n)
    return
end


#------------------------------------------------------------------------------#
#----------------------------------------------------------# Interactive Testing
y1 = randn(1000)
y2 = randn(101)
y = [y1;y2]

m = OnlineStats.Moments(y1)
OnlineStats.update!(m, y2)

y3 = randn(120)
OnlineStats.update!(m, y3)
OnlineStats.update!(m, .5)

y = [y1, y2, y3, .5]

display(OnlineStats.state(m))

# println("")
# println(mean((y - mean(y)) .^ 2))
# println(mean((y - mean(y)) .^ 3))
# println(mean((y - mean(y)) .^ 4))
# println("")
# println(mean(y))
# println(skewness(y))
# println(kurtosis(y))

