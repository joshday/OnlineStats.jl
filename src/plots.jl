import Plots

export coefplot, TracePlot, CompareTracePlot


"""
For any OnlineStat that has a `coef` method, display a graphical representation of
the coefficient vector.
"""
function coefplot(o::OnlineStats.OnlineStat{XYInput})
    β = coef(o)
    x = 1:length(β)
    try
        if o.intercept
            x -= 1
        end
    end
    coefplot(β, x)
end

function coefplot(β::VecF, x = 1:length(β))
    nonzero = collect(β.== 0)
    mylegend = length(unique(nonzero)) > 1
    Plots.scatter(x, β, group = nonzero, legend = mylegend, xlabel = "Coefficient Vector",
    ylabel = "value", lab = ["nonzero" "zero"], xlims = (minimum(x)-1, maximum(x)+1))
end




#--------------------------------------------------------------------# TracePlot
"""
`TracePlot(o)`

`TracePlot(o, f)`
"""
type TracePlot <: OnlineStat
    o::OnlineStat
    p::Plots.Plot
    f::Function
end

function TracePlot(o::OnlineStats.OnlineStat, f::Function = value; kw...)
    p = Plots.plot([nobs(o)], collect(f(o))';
        xlabel = "nobs",
        ylabel = "value of function $f",
        kw...)
    TracePlot(o, p, f)
end

function fit!(tr::TracePlot, args...)
    fit!(tr.o, args...)
    push!(tr.p, nobs(tr.o), collect(tr.f(tr.o)))
end

Plots.plot(tr::TracePlot) = tr.p
nobs(tr::TracePlot) = nobs(tr.o)
value(tr::TracePlot) = value(tr.o)

#-------------------------------------------------------------# CompareTracePlot
"""
Compare the values of multiple OnlineStats.
"""
type CompareTracePlot
    os::Vector
    p::Plots.Plot
    f::Function  # Use a function that returns a scalar
end

function CompareTracePlot(os::Vector, f::Function; kw...)
    p = Plots.plot(
        Float64[nobs(oi) for oi in os]',   # x
        Float64[f(oi) for oi in os]';      # y
        ylabel = "value of function $f", xlabel = "nobs", kw...
    )
    CompareTracePlot(os, p, f)
end

function fit!(c::CompareTracePlot, args...)
    for o in c.os
        fit!(o, args...)
    end
    for i in 1:length(c.os)
        push!(c.p, i, nobs(c.os[i]), c.f(c.os[i]))
    end
end

Plots.plot(c::CompareTracePlot) = c.p
