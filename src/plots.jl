import Plots

export coefplot, TracePlot


"""
For any OnlineStat that has a `coef` method, display a graphical representation of
the coefficient vector.
"""
function coefplot(o::OnlineStat)
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
type TracePlot
    o::OnlineStat
    p::Plots.Plot
    f::Function
end

function TracePlot(o::OnlineStat, f::Function = x -> state(x)[1])
    p = Plots.plot([nobs(o)], collect(f(o))')
    TracePlot(o, p, f)
end

function update!(tr::TracePlot, args...)
    update!(tr.o, args...)
    push!(tr.p, nobs(tr.o), collect(tr.f(tr.o)))
end


#-------------------------------------------------------------# CompareTracePlot
# type CompareTracePlot
#     os::Vector{OnlineStats}
#     p::Plots.Plot
#     f::Vector{Function}
# end
#
# function TracePlot(os::Vector{OnlineStat}, fs::Vector{Function})
#     nvals = length(os) * length(fs)
#     x = zeros(nvals)
#     i = 1:length(os)
#     while maximum(i) <= nvals
#         x[i] = nobs
#     end
# end



############################################################## TEST
# module Test
# using OnlineStats
# using OnlineStatsPlots
# using Plots
# pyplot()
#
# n, p = 10_000, 10
# β = collect(1.:p)
# x = randn(n, p)
# y = x*β + randn(n)
#
# myloss(o) = OnlineStats.loss(o, x, y)
# o = StochasticModel(p)
# tr = TracePlot(o, myloss)
#
# b = 1:100
# for i in 1:10
#     update!(tr, OnlineStats.rows(x, b), OnlineStats.rows(y, b))
#     b = b + 100
# end
# # plot!(tr.p, ylims = (0,10))
#
# println(coef(tr.o))
# end
