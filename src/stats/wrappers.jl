abstract type WrappedStat{N} <: OnlineStat{N} end
nobs(o::WrappedStat) = nobs(o.stat)
value(o::WrappedStat) = value(o.stat)

#-----------------------------------------------------------------------# CStat
"""
    CStat(stat)

Track a univariate OnlineStat for complex numbers.  A copy of `stat` is made to
separately track the real and imaginary parts.

# Example
    
    y = randn(100) + randn(100)im
    fit!(y, CStat(Mean()))
"""
struct CStat{O <: OnlineStat{0}} <: OnlineStat{0}
    re_stat::O
    im_stat::O
end
CStat(o::OnlineStat{0}) = CStat(o, copy(o))
Base.show(io::IO, o::CStat) = print(io, "CStat: re=$(o.re_stat), im=$(o.im_stat)")
value(o::CStat) = value(o.re_stat), value(o.im_stat)
_fit!(o::CStat, y::Real) = _fit!(o.re_stat, y)
_fit!(o::CStat, y::Complex) = (_fit!(o.re_stat, y.re); _fit!(o.im_stat, y.im))
function Base.merge!(o1::T, o2::T, γ::Float64) where {T<:CStat}
    merge!(o1.re_stat, o2.re_stat)
    merge!(o1.im_stat, o2.im_stat)
end



# #-----------------------------------------------------------------------# Abstract type
# abstract type WrappedStat{N} <: OnlineStat{N} end
# stat(o::WrappedStat) = o.stat
# default_weight(o::WrappedStat) = default_weight(stat(o))
# value(o::WrappedStat) = value(stat(o))


# #-----------------------------------------------------------------------# CallFun
# """
#     CallFun(o::OnlineStat, f::Function)

# Call `f(o)` every time the OnlineStat `o` gets updated.

# # Example

#     Series(randn(5), CallFun(Mean(), info))
# """
# struct CallFun{N, O <: OnlineStat{N}, F <: Function} <: WrappedStat{N}
#     stat::O
#     f::F
# end 
# CallFun(o::OnlineStat{N}, f) where {N} = CallFun{N, typeof(o), typeof(f)}(o, f)
# Base.show(io::IO, o::CallFun) = print(io, "CallFun: $(o.stat) |> $(o.f)")
# fit!(o::CallFun, arg, γ::Float64)  = (fit!(o.stat, arg, γ); o.f(o.stat))

# #-----------------------------------------------------------------------# Bootstrap
# """
#     Bootstrap(o::OnlineStat, nreps = 100, d = [0, 2])

# Online statistical bootstrap.  Create `nreps` replicates of `o`.  For each call to `fit!`,
# a replicate will be updated `rand(d)` times.

# # Example

#     o = Bootstrap(Variance())
#     Series(randn(1000), o)
#     confint(o)
# """
# struct Bootstrap{O <: OnlineStat, D} <: WrappedStat{0}
#     stat::O 
#     replicates::Vector{O}
#     rand_object::D
# end
# function Bootstrap(o::OnlineStat{0}, nreps::Integer = 100, d = [0, 2])
#     Bootstrap(o, [copy(o) for i in 1:nreps], d)
# end
# Base.show(io::IO, b::Bootstrap) = print(io, "Bootstrap($(length(b.replicates))): $(b.stat)")
# """
#     confint(b::Bootstrap, coverageprob = .95)

# Return a confidence interval for a Bootstrap `b`.
# """
# function confint(b::Bootstrap, coverageprob = 0.95)
#     states = value.(b.replicates)
#     α = 1 - coverageprob
#     return (quantile(states, α / 2), quantile(states, 1 - α / 2))
# end
# function fit_replicates!(b::Bootstrap, yi, γ)
#     for r in b.replicates
#         for _ in 1:rand(b.rand_object)
#             fit!(r, yi, γ)
#         end
#     end
# end
# function fit!(b::Bootstrap, y, γ::Float64)
#     fit!(b.stat, y, γ)
#     fit_replicates!(b, y, γ)
#     b
# end
