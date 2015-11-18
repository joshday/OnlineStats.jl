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

    o1 = StochasticModel(10, algorithm = SGD(r = 1.))
    o2 = StochasticModel(10, algorithm = SGD(r = .6))
    tr = CompareTracePlot(OnlineStat[o1, o2], x -> maxabs(coef(x)))
    update!(tr, randn(100,10), randn(100))
end

end # module
