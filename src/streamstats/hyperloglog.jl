# Mostly copy/pasted from StreamStats.jl
hash32(d::Any) = hash(d) % UInt32
maskadd32(x::UInt32, mask::UInt32, add::UInt32) = (x & mask) + add
ρ(s::UInt32) = UInt32(leading_zeros(s)) + 0x00000001
const toInt = Int
const toUInt = UInt

function α(m::UInt32)
    if m == 0x00000010
        return 0.673
    elseif m == 0x00000020
        return 0.697
    elseif m == 0x00000040
        return 0.709
    else # if m >= UInt32(128)
        return 0.7213 / (1 + 1.079 / m)
    end
end

"""
    HyperLogLog(b)

Approximate count of distinct elements
"""
mutable struct HyperLogLog <: OnlineStat{ScalarIn, ScalarOut}
    m::UInt32
    M::Vector{UInt32}
    mask::UInt32
    altmask::UInt32
    function HyperLogLog(b::Integer)
        if !(4 <= b <= 16)
            throw(ArgumentError("b must be an Integer between 4 and 16"))
        end
        m = 0x00000001 << b
        M = zeros(UInt32, m)
        mask = 0x00000000
        for i in 1:(b - 1)
            mask |= 0x00000001
            mask <<= 1
        end
        mask |= 0x00000001
        altmask = ~mask
        new(m, M, mask, altmask)
    end
end
function Base.show(io::IO, counter::HyperLogLog)
    @printf(io, "HyperLogLog(%d registers)", Int(counter.m))
    return
end

function fit!(o::HyperLogLog, v::Any, γ::Float64)
    x = hash32(v)
    j = maskadd32(x, o.mask, 0x00000001)
    w = x & o.altmask
    o.M[j] = max(o.M[j], ρ(w))
    o
end

function value(o::HyperLogLog)
    S = 0.0
    for j in 1:o.m
        S += 1 / (2 ^ o.M[j])
    end
    Z = 1 / S
    E = α(o.m) * toUInt(o.m) ^ 2 * Z
    if E <= 5//2 * o.m
        V = 0
        for j in 1:o.m
            V += toInt(o.M[j] == 0x00000000)
        end
        if V != 0
            E_star = o.m * log(o.m / V)
        else
            E_star = E
        end
    elseif E <= 1//30 * 2 ^ 32
        E_star = E
    else
        E_star = -2 ^ 32 * log(1 - E / (2 ^ 32))
    end
    return E_star
end
