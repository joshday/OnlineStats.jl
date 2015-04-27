export Moments
#-------------------------------------------------------# Type and Constructors
type Moments <: ScalarStat
    m1m2::Var
    m3::Float64
    m4::Float64
    n::Int64
end

function Moments(y::Vector)
    m::Float64 = mean(y)
    Moments(Var(y), mean((y - m) .^ 3), mean((y - m) .^ 4), length(y))
end


#-----------------------------------------------------------------------# state
state_names(obj::Moments) = [:μ, :σ², :skewness, :kurtosis]

state(obj::Moments) = [mean(obj), var(obj), skewness(obj), kurtosis(obj)]


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

    c = 1 - γ * (1 - γ)
    m4 += γ * (m4_ - m4) + γ * (1 - γ) * δ *
        ((c * δ^3) + 6 * (m2_ + γ * (m2 - m2_))*δ  + 4 * (m3_ - m3))

    m3 += γ * (m3_ - m3) + γ * (1 - γ) * ((n1 - n2) / n) * δ ^ 3
    m3 += 3 * γ * ((1 - γ) * m2_ - γ * m2) * δ

    obj.m3 = m3
    obj.m4 = m4
    obj.n += n2
end

update!(obj::Moments, y::Real) = update!(obj, [y])


#------------------------------------------------------------------------# Base
Base.mean(m::Moments) = return m.m1m2.mean

Base.var(m::Moments) = return m.m1m2.var  * (m.n / (m.n - 1))

skewness(m::Moments) = return m.m3 / var(m)^1.5

kurtosis(m::Moments) = return m.m4 / var(m)^2 - 3.0

Base.copy(obj::Moments) = return Moments(obj.m1m2, obj.m3, obj.m4, obj.n)

function Base.merge(a::Moments, b::Moments)
    c = copy(a)
    merge!(c, b)
    return c
end

function Base.merge!(obj::Moments, obj2::Moments)
    m1, m2, m3, m4 = obj.m1m2.mean, obj.m1m2.var, obj.m3, obj.m4
    m1_, m2_, m3_, m4_ = obj2.m1m2.mean, obj2.m1m2.var, obj2.m3, obj2.m4
    n1 = obj.n
    n2 = obj2.n
    n = n1 + n2
    γ = n2 / n
    δ = m1_ - m1

    merge!(obj.m1m2, obj2.m1m2)

    m3 += γ * (m3_ - m3) + γ * (1 - γ) * ((n1 - n2) / n) * δ^3
    m3 += 3 * γ * ((1 - γ) * m2_ - γ * m2) * δ

    c = (1 - γ)^2 - γ*(1-γ) + γ^2
    m4 += γ * (m4_ - m4) + γ * (1 - γ) * δ *
        ((c * δ^3) + 6 * (m2_ + γ * (m2 - m2_))*δ  + 4 * (m3_ - m3))

    obj.m3 = m3
    obj.m4 = m4
    obj.n += n2
end
