# Not sure how to use Weighting with central moments yet.
# This implementation uses noncentral moments.

#-------------------------------------------------------# Type and Constructors
type Moments{W <: Weighting} <: OnlineStat
    m1::Float64
    m2::Float64
    m3::Float64
    m4::Float64
    n::Int64
    weighting::W
end

function Moments(y::Vector, wgt::Weighting = default(Weighting))
    o = Moments(wgt)
    update!(o, y)
    o
end

Moments(wgt::Weighting = default(Weighting)) = Moments(0., 0., 0., 0., 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::Moments) = [:μ, :σ², :skewness, :kurtosis, :nobs]
state(o::Moments) = Any[mean(o), var(o), skewness(o), kurtosis(o), nobs(o)]

mean(o::Moments) = o.m1
var(o::Moments) = (o.m2 - o.m1 ^2) * (o.n / (o.n - 1))
std(o::Moments) = sqrt(var(o))
skewness(o::Moments) = (o.m3  - 3 * o.m1 * var(o) - o.m1 ^ 3) / var(o) ^ 1.5
kurtosis(o::Moments) = (o.m4 - 4 * o.m1 * o.m3 + 6 * o.m1 ^2 * o.m2 - 3 * o.m1 ^ 4) / var(o)^2 - 3.0


#---------------------------------------------------------------------# update!
# For central moments without Weighting
# function updatebatch!(o::Moments, y::Vector)
#     vary = Var(y)
#     m1, m2, m3, m4 = o.m1m2.mean, o.m1m2.var, o.m3, o.m4
#     m1_, m2_ = vary.mean, vary.var
#     m3_, m4_ = mean((y - m1_) .^ 3), mean((y - m1_) .^ 4)
#     n1 = o.n
#     n2 = vary.n
#     n = n1 + n2
#     γ = n2 / n
#     δ = m1_ - m1

#     update!(o.m1m2, y)

#     c = 1 - γ * (1 - γ)
#     m4 += γ * (m4_ - m4) + γ * (1 - γ) * δ *
#         ((c * δ^3) + 6 * (m2_ + γ * (m2 - m2_))*δ  + 4 * (m3_ - m3))

#     m3 += γ * (m3_ - m3) + γ * (1 - γ) * ((n1 - n2) / n) * δ ^ 3
#     m3 += 3 * γ * ((1 - γ) * m2_ - γ * m2) * δ

#     o.m3 = m3
#     o.m4 = m4
#     o.n += n2
# end

function update!(o::Moments, y::Float64)
    o.n += 1
    γ = weight(o)
    o.m1 = smooth(o.m1, y, γ)
    o.m2 = smooth(o.m2, y * y, γ)
    o.m3 = smooth(o.m3, y * y * y, γ)
    o.m4 = smooth(o.m4, y * y * y * y, γ)
    return
end


#------------------------------------------------------------------------# Base
# function Base.merge!(o::Moments, o2::Moments)
#     m1, m2, m3, m4 = o.m1m2.mean, o.m1m2.var, o.m3, o.m4
#     m1_, m2_, m3_, m4_ = o2.m1m2.mean, o2.m1m2.var, o2.m3, o2.m4
#     n1 = o.n
#     n2 = o2.n
#     n = n1 + n2
#     γ = n2 / n
#     δ = m1_ - m1

#     merge!(o.m1m2, o2.m1m2)

#     m3 += γ * (m3_ - m3) + γ * (1 - γ) * ((n1 - n2) / n) * δ^3
#     m3 += 3 * γ * ((1 - γ) * m2_ - γ * m2) * δ

#     c = 1 - γ * (1 - γ)
#     m4 += γ * (m4_ - m4) + γ * (1 - γ) * δ *
#         ((c * δ^3) + 6 * (m2_ + γ * (m2 - m2_))*δ  + 4 * (m3_ - m3))

#     o.m3 = m3
#     o.m4 = m4
#     o.n += n2
# end
