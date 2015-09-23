
# This was copied nearly verbatim from StreamStats.jl... can we include the weighting?  what would the weight even mean?
# TODO: description of the algorithm, along with what the various args and sufficient stats represent


# the HyperLogLog algorithm is used to estimate the number of distict elements in a large data set,
# and avoids storage of bin counts in a hash or related structure
# see: Flajolet et al: "HyperLogLog: the analysis of a near-optimal cardinality estimation algorithm"
#      http://algo.inria.fr/flajolet/Publications/FlFuGaMe07.pdf
# John: do you have a better reference?  Is your algo based on this or something else?


#-------------------------------------------------------# Type and Constructors
@compat type HyperLogLog <: OnlineStat
    # TODO: better names and documentation
    m::UInt32
    M::Vector{UInt32}
    mask::UInt32
    altmask::UInt32
    est::Float64
    stale::Bool
    n::Int64
    # weighting::W  # NOTE: does it make sense to include a weighting? I'm not sure
end

# b is expected to be an integer between 4 and 16
# m = 2ᵇ
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

    HyperLogLog(m, M, mask, altmask, 0.0, true, 0)
end


name(o::HyperLogLog) = "HyperLogLog"


#-----------------------------------------------------------------------# state


# compute E := αₘ * m² / S
#   where S := Σⱼ(2⁻ᴹʲ)
#   and αₘ is defined below
function estimatedCardinality(o::HyperLogLog)

    if !o.stale
        return o.est
    end

    S = 0.0
    for j in 1:o.m
        S += 1 / (2^o.M[j])  # !!!!!!!!!! Is this correct? should it be (2 ^ (-o.M[j]))??
    end
    # Z = 1 / S
    E = α(o.m) * @compat UInt(o.m)^2 / S

    # note: I'm honestly not sure what this does
    if E <= 5//2 * o.m
        V = 0
        for j in 1:o.m
            V += Int(o.M[j] == 0x00000000)
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

    o.est = E_star
    o.stale = false
    E_star
end


statenames(o::HyperLogLog) = [:estimatedCardinality, :nobs]
state(o::HyperLogLog) = Any[estimatedCardinality(o), nobs(o)]



#---------------------------------------------------------------------# update!

if VERSION < v"0.4.0-"
    hash32(d::Any) = @compat UInt32(hash(d))
else
    hash32(d::Any) = hash(d) % @compat UInt32
end

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


function update!(o::HyperLogLog, v::Real)
    x = hash32(v)
    j = @compat UInt32((x & o.mask) + 0x00000001)
    w = x & o.altmask
    o.M[j] = max(o.M[j], ρ(w))

    o.stale = true
    o.n += 1
    return
end

function update!{T<:Real}(o::HyperLogLog, V::AVec{T})
    for v in V
        update!(o, v)
    end
end

# not sure what this is:
    # TODO: Figure out details here
    # function confint(o::HyperLogLog)
    #     e = estimate(o)
    #     delta = e * 1.04 / sqrt(o.m)
    #     return e - delta, e + delta
    # end

Base.copy(o::HyperLogLog) = HyperLogLog(o.m, copy(o.M), o.mask, o.altmask, o.n)

# TODO: Base.empty! and Base.merge!
