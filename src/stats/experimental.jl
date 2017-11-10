"""
    CallFun(o::OnlineStat{0}, f::Function)

Call `f(o)` every time the OnlineStat `o` gets updated.

# Example

    Series(randn(5), CallFun(Mean(), info))
"""
struct CallFun{O, F} <: OnlineStat{0}
    o::O
    f::F
end 
default_weight(o::CallFun) = default_weight(o.o)

Base.show(io::IO, o::CallFun) = print(io, "CallFun: $(o.o) |> $(o.f)")

_value(o::CallFun) = value(o.o)

function fit!(o::CallFun, arg, γ::Float64) 
    fit!(o.o, arg, γ)
    o.f(o.o)
end