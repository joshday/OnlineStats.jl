module PlotTest

using OnlineStats, FactCheck, Plots
plotlyjs()

facts("Plots") do
    o = StatLearn(10)
    coefplot(o)

    tr = TracePlot(o)
    fit!(tr, randn(100, 10), randn(100))

    o.β[2] = 0.0
    coefplot(o)

    o1 = StatLearn(10, algorithm = SGD())
    o2 = StatLearn(10, algorithm = RDA())
    tr = CompareTracePlot(OnlineStat[o1, o2], x -> maxabs(coef(x)))
    fit!(tr, randn(100,10), randn(100))
end

end # module
