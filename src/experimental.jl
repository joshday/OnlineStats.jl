"""
    CallFun(o::OnlineStat, f::Function)

Call `f(o)` every time the OnlineStat `o` gets updated.

# Example

    Series(randn(5), CallFun(Mean(), info))
"""
struct CallFun{O, F} <: OnlineStat{Any, Any}
    o::O
    f::F
end 
default_weight(o::CallFun) = default_weight(o.o)
input_ndims(o::CallFun) = input_ndims(o.o)

Base.show(io::IO, o::CallFun) = print(io, "CallFun: $(o.o) |> $(o.f)")

value(o::CallFun) = value(o.o)

function fit!(o::CallFun, args...) 
    fit!(o.o, args...)
    o.f(o.o)
end