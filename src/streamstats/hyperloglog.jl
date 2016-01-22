# Mostly Copy/pasted from StreamStats.jl PR (https://github.com/tawheeler/StreamStats.jl/blob/5e804140aa6099c1ff3bb7182ef6d36dc37595eb/src/hyper_log_log.jl)

ρ(s::UInt32) = UInt32(UInt32(leading_zeros(s)) + 0x00000001)

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

type HyperLogLog <: OnlineStat
    m::UInt32
    M::Vector{UInt32}
    mask::UInt32
    altmask::UInt32
    n::Int
end

function HyperLogLog(b::Integer)
    if !(4 <= b <= 16)
        throw(ArgumentError("b must be an integer between 4 and 16"))
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

function Base.show(io::IO, o::HyperLogLog)
    @printf(io, "A HyperLogLog counter w/ %d registers", convert(Int, o.m))
    return
end

function fit!(o::HyperLogLog, v::Any)
    n!(o)
    x = hash32(v)  # This is deprecated?
    j = UInt32((x & o.mask) + 0x00000001)
    w = x & o.altmask
    o.M[j] = max(o.M[j], ρ(w))
    return
end

function state(o::HyperLogLog)
    S = 0.0

    for j in 1:o.m
        S += 1 / (2^o.M[j])
    end

    Z = 1 / S

    E = α(o.m) * convert(UInt, o.m)^2 * Z

    if E <= 5//2 * o.m
        V = 0
        for j in 1:o.m
            V += convert(Int, (o.M[j] == 0x00000000))
        end
        if V != 0
            E_star = o.m * log(o.m / V)
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

function Base.copy(o::HyperLogLog)
    return HyperLogLog(
        o.m,
        copy(o.M),
        o.mask,
        o.altmask,
    )
end
