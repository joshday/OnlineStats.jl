
#-----------------------------------------------------------------------# Kahan Sum
"""
    KahanSum(T::Type = Float64)

Track the overall sum.

# Example

    fit!(KahanSum(Float64), fill(1, 100))
"""
mutable struct KahanSum{T<:Number} <: OnlineStat{Number}
    sum::T
    c::T
    n::Int
end
KahanSum(T::Type = Float64) = KahanSum(T(0), T(0), 0)
Base.sum(o::KahanSum) = o.sum
function _fit!(o::KahanSum{T}, x::Number) where {T<:Number}
    y = convert(T, x) - o.c
    t = o.sum + y
    o.c = (t - o.sum) - y
    o.sum = t
    o.n += 1
end
_merge!(o::T, o2::T) where {T <: KahanSum} = (o.sum += o2.sum; o.c += o2.c; o.n += o2.n; o)
