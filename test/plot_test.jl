module PlotTest

using OnlineStats, FactCheck, Plots
gadfly()

facts("Plots") do
    o = StochasticModel(10)
    coefplot(o)

    tr = TracePlot(o)
    update!(tr, randn(100, 10), randn(100))

    o.β[2] = 0.0
    coefplot(o)
end

end # module
