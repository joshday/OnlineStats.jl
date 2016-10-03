# abstract methods for OnlineStat{XYInput}


function Base.show(io::IO, o::OnlineStat{XYInput})
    printheader(io, name(o))
    print_item(io, "β0", o.β0)
    print_item(io, "β", o.β)
    print_item(io, "nobs", nobs(o))
end

value(o::OnlineStat{XYInput}) = coef(o)
coef(o::OnlineStat{XYInput}) = o.β0, o.β
