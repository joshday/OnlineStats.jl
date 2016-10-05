# abstract methods for OnlineStat{XYInput}
# Something being a subtype of OnlineStat{XYInput} is a contract that it has fields:
#   - β0        (intercept/bias)
#   - β         (coefficients)
#   - model     (<: Model)


function Base.show(io::IO, o::OnlineStat{XYInput})
    printheader(io, name(o))
    o.intercept && print_item(io, "β0", o.β0)
    print_item(io, "β", o.β)
    print_item(io, "weight", o.weight)
    print_item(io, "nobs", nobs(o))
end

value(o::OnlineStat{XYInput}) = coef(o)
coef(o::OnlineStat{XYInput}) = o.β0, o.β
xβ(o::OnlineStat{XYInput}, x::AVec) = o.β0 + dot(x, o.β)
xβ(o::OnlineStat{XYInput}, x::AMat) = o.β0 + x * o.β
predict(o::OnlineStat{XYInput}, x) = predict(o.model, xβ(o, x))
loss(o::OnlineStat{XYInput}, x, y) = loss(o.model, y, xβ(o, x))
