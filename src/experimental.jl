struct CallFun{O, F} <: OnlineStat{0, EqualWeight}
    o::O
    f::F
end 

Base.show(io::IO, o::CallFun) = print(io, "CallFun: $(o.o)")

value(o::CallFun) = value(o.o)

function fit!(o::CallFun, args...) 
    fit!(o.o, args...)
    o.f(o.o)
end