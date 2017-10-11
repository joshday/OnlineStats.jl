"""
    Bootstrap(o::OnlineStat, nreps = 100, d = [0, 2], f = value)

Online Statistical Bootstrapping.  Create `nreps` replicates of the OnlineStat `o`.
When `fit!` is called, each of the replicates will be updated `rand(d)` times.
`value(b::Bootstrap)` returns `f` mapped to the replicates.

    b = Bootstrap(Mean())
    fit!(b, randn(1000))
    value(b)        # `f` mapped to replicates
    mean(value(b))  # mean
"""
struct Bootstrap{I, O<:OnlineStat{I}, S<:Series{I, Tuple{O}}, D, F<:Function}
    series::S
    replicates::Vector{O}
    d::D
    f::F
end

function Bootstrap{I}(wt::Weight, o::OnlineStat{I}, nreps::Integer = 100, d = [0, 2],
        f::Function = value)
    s = Series(wt, o)
    Bootstrap{I, typeof(o), typeof(s), typeof(d), typeof(f)}(s, [copy(o) for i in 1:nreps], d, f)
end

Bootstrap(o::OnlineStat, args...) = Bootstrap(default_weight(o), o, args...)

function Base.show(io::IO, b::Bootstrap)
    OnlineStatsBase.header(io, OnlineStatsBase.name(b))
    println(io, "    > n replicates : $(length(b.replicates))")
    println(io, "    > function     : $(b.f)")
    println(io, "    > rand object  : $(b.d)")
    println(io, "    > weight       : $(b.series.weight)")
    print(io,   "    > stat         : $(first(stats(b.series)))")
end

value(b::Bootstrap) = map(b.f, b.replicates)

"""
    replicates(b)
Return the vector of replicates from Bootstrap `b`
"""
replicates(b::Bootstrap) = b.replicates


"""
    confint(b, coverageprob = .95)
Return a confidence interval for a Bootstrap `b`.
"""
function confint(b::Bootstrap, coverageprob = 0.95, method = :quantile)
    states = value(b)
    if any(isnan, states)
        return (NaN, NaN)
    else
        α = 1 - coverageprob
        return (quantile(states, α / 2), quantile(states, 1 - α / 2))
    end
end

#-----------------------------------------------------------------------# fit!
function fit_replicates!(b::Bootstrap, yi)
    γ = OnlineStatsBase.weight(b.series)
    for r in b.replicates
        for _ in 1:rand(b.d)
            fit!(r, yi, γ)
        end
    end
end
#-----------------------------------------------------------------------# Input: 0
function fit!(b::Bootstrap{0}, y::Real)
    fit!(b.series, y)
    fit_replicates!(b, y)
    b
end
function fit!(b::Bootstrap{0}, y::AVec)
    for yi in y
        fit!(b, yi)
    end
    b
end
#-----------------------------------------------------------------------# Input: 1
function fit!(b::Bootstrap{1}, y::AVec)
    fit!(b.series, y)
    fit_replicates!(b, y)
end
function fit!(b::Bootstrap{1}, y::AMat)
    for i in 1:size(y, 1)
        fit!(b, view(y, i, :))
    end
    b
end
