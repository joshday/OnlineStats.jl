module TraceDataTest

using OnlineStats, FactCheck, Distributions, DataFrames

facts("tracedata()") do
    n = rand(10_000:100_000)
    x = rand(n)
    df = tracedata(Mean(ExponentialWeighting(1e-10)), 5, x)
    @fact df[end, 1] - mean(x) => roughly(0., 1e-9)
    @fact OnlineStats.getrows(x, 1) => x[1]
    @fact OnlineStats.getrows(x, 1:10) => x[1:10]

    df = tracedata(QuantileMM(), 1, x)
    @fact size(unpack_vectors(df), 1) => 3 * n

    df = tracedata(FitNormal(), 10, randn(100))
    @fact size(OnlineStats.unpack_distributions(df)) => (10, 3)
end
end #module
