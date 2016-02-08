# Mostly copy/pasted from StreamStats.jl

# v0.4 updates from
# https://github.com/PalladiumConsulting/StreamStats.jl/blob/master/src/hyper_log_log.jl


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

type HyperLogLog
    m::UInt32
    M::Vector{UInt32}
    mask::UInt32
    altmask::UInt32
end

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

    return HyperLogLog(m, M, mask, altmask)
end

function Base.show(io::IO, counter::HyperLogLog)
    @printf(io, "A HyperLogLog counter w/ %d registers", Int(counter.m))
    return
end

function fit!(counter::HyperLogLog, v::Any)
    x = hash32(v)
    j = maskadd32(x, counter.mask, 0x00000001)
    w = x & counter.altmask
    counter.M[j] = max(counter.M[j], ρ(w))
    return
end

function value(counter::HyperLogLog)
    S = 0.0

    for j in 1:counter.m
        S += 1 / (2^counter.M[j])
    end

    Z = 1 / S

    E = α(counter.m) * toUInt(counter.m)^2 * Z

    if E <= 5//2 * counter.m
        V = 0
        for j in 1:counter.m
            V += toInt(counter.M[j] == 0x00000000)
        end
        if V != 0
            E_star = counter.m * log(counter.m / V)
        else
            E_star = E
        end
    elseif E <= 1//30 * 2^32
        E_star = E
    else
        E_star = -2^32 * log(1 - E / (2^32))
    end

    return E_star
end

# TODO: Figure out details here
# function confint(counter::HyperLogLog)
#     e = estimate(counter)
#     delta = e * 1.04 / sqrt(counter.m)
#     return e - delta, e + delta
# end
