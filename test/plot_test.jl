module PlotTest

using OnlineStats, FactCheck, Plots
gadfly()

facts("Plots") do
    o = StochasticModel(10)
    coefplot(o)

    tr = TracePlot(o)
    update!(o, randn(100, 10), randn(100))
end

end # module
