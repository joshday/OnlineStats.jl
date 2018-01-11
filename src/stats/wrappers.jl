#-----------------------------------------------------------------------# Abstract type
abstract type WrappedStat{N} <: OnlineStat{N} end
stat(o::WrappedStat) = o.stat
default_weight(o::WrappedStat) = default_weight(stat(o))
value(o::WrappedStat) = value(stat(o))


#-----------------------------------------------------------------------# CallFun
"""
    CallFun(o::OnlineStat, f::Function)

Call `f(o)` every time the OnlineStat `o` gets updated.

# Example

    Series(randn(5), CallFun(Mean(), info))
"""
struct CallFun{N, O <: OnlineStat{N}, F <: Function} <: WrappedStat{N}
    stat::O
    f::F
end 
CallFun(o::OnlineStat{N}, f) where {N} = CallFun{N, typeof(o), typeof(f)}(o, f)
Base.show(io::IO, o::CallFun) = print(io, "CallFun: $(o.stat) |> $(o.f)")
fit!(o::CallFun, arg, γ::Float64)  = (fit!(o.stat, arg, γ); o.f(o.stat))

