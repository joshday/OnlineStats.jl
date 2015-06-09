module PlotMethodsTest

using OnlineStats, FactCheck, Gadfly, Distributions

include(Pkg.dir("OnlineStats", "src", "plotmethods.jl"))

facts("Plot Methods") do
    o = FiveNumberSummary(rand(100))
    plot(o)

    d = MixtureModel(Normal, [(0, 1), (10, 5)], [.5, .5])
    plot(d, -10, 20)

    x = rand(d, 10_000)
    plot(d, x)
end # facts
end # module
