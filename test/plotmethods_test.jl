module PlotMethodsTest

using OnlineStats, FactCheck, Gadfly

facts("Plot Methods") do
    o = FiveNumberSummary(rand(100))
    plot(o)
end # facts
end # module
