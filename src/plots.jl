import Plots

export coefplot, TracePlot, CompareTracePlot


"""
For any OnlineStat that has a `coef` method, display a graphical representation of
the coefficient vector.
"""
function coefplot(o::OnlineStats.OnlineStat)
    x = 1:length(coef(o))
    if o.intercept
        x -= 1
    end
    nonzero = collect(coef(o) .== 0)
    if length(unique(nonzero)) > 1
        mylegend = true
    else
        mylegend = false
    end
    Plots.scatter(x, coef(o), group = nonzero, legend = mylegend, xlabel = "β", ylabel = "value",
    xlims = extrema(x), yticks = [0], lab = ["nonzero" "zero"])
end




#--------------------------------------------------------------------# TracePlot
"""
`TracePlot(o)`

`TracePlot(o, f)`

Create a traceplot from an `OnlineStat`.  The value(s) to be plotted are `f(o)`, which defaults to the first element of `state(o)`.  Each time a `TracePlot` is updated, the corresponding `OnlineStat` will be updated and new value(s) will be added to the plot.
"""
type TracePlot
    o::OnlineStat
    p::Plots.Plot
    f::Function
end

function TracePlot(o::OnlineStats.OnlineStat, f::Function = x -> state(x)[1]; kw...)
    p = Plots.plot([nobs(o)], collect(f(o))'; kw...)
    TracePlot(o, p, f)
end

function update!(tr::TracePlot, args...)
    update!(tr.o, args...)
    push!(tr.p, nobs(tr.o), collect(tr.f(tr.o)))
end


#-------------------------------------------------------------# CompareTracePlot
"""
Compare the values of multiple OnlineStats.

Example:
```
o1 = StochasticModel(size(x, 2), algorithm = MMGrad())
o2 = StochasticModel(size(x, 2), algorithm = SGD())
myloss(o) = loss(o, xtest, ytest)
comp = CompareTracePlot([o1, o2])

update!(comp, x1, y1)
update!(comp, x2, y2)
...
```
"""
type CompareTracePlot
    os::Vector{OnlineStats.OnlineStat}
    p::Plots.Plot
    f::Function  # Use a function that returns a scalar
end

function CompareTracePlot{T<:OnlineStats.OnlineStat}(os::Vector{T}, f::Function; kw...)
    p = Plots.plot([nobs(oi) for oi in os]', [f(oi) for oi in os]';
        ylabel = "value of function $f", xlabel = "nobs", kw...
    )
    #
    # for i in 2:length(os)
    #     Plots.plot!(p, [nobs(os[i])], [f(os[i])])
    # end
    # Plots.plot!(p, legend=true, xlabel = "nobs", ylabel = "value of function $f")
    CompareTracePlot(os, p, f)
end

function update!(c::CompareTracePlot, args...)
    for o in c.os
        update!(o, args...)
    end
    for i in 1:length(c.os)
        push!(c.p, i, nobs(c.os[i]), c.f(c.os[i]))
    end
end
