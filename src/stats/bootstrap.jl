"""
    Bootstrap(o::OnlineStat, nreps = 100, d = [0, 2])

Online statistical bootstrap.  Create `nreps` replicates of `o`.  For each call to `fit!`,
a replicate will be updated `rand(d)` times.

# Example

    o = Bootstrap(Variance())
    Series(randn(1000), o)
    confint(o)
"""
struct Bootstrap{O <: OnlineStat, D} <: OnlineStat{0}
    o::O 
    replicates::Vector{O}
    rand_object::D
end
function Bootstrap(o::OnlineStat{0}, nreps::Integer = 100, d = [0, 2])
    Bootstrap(o, [copy(o) for i in 1:nreps], d)
end
Base.show(io::IO, b::Bootstrap) = print(io, "Bootstrap($(length(b.replicates))): $(b.o)")
value(b::Bootstrap) = value.(b.replicates)
default_weight(b::Bootstrap) = default_weight(b.o)


"""
    confint(b::Bootstrap, coverageprob = .95)

Return a confidence interval for a Bootstrap `b`.
"""
function confint(b::Bootstrap, coverageprob = 0.95)
    states = value(b)
    if any(isnan, states)
        return (NaN, NaN)
    else
        α = 1 - coverageprob
        return (quantile(states, α / 2), quantile(states, 1 - α / 2))
    end
end

#-----------------------------------------------------------------------# fit!
function fit_replicates!(b::Bootstrap, yi, γ)
    for r in b.replicates
        for _ in 1:rand(b.rand_object)
            fit!(r, yi, γ)
        end
    end
end
#-----------------------------------------------------------------------# Input: 0
function fit!(b::Bootstrap, y::ScalarOb, γ::Float64)
    fit!(b.o, y, γ)
    fit_replicates!(b, y, γ)
    b
end
