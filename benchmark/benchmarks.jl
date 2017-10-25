module OnlineStatsBenchmarks
using PkgBenchmark, BenchmarkTools, OnlineStats

y = randn(1_000_000)
x = randn(1_000_000, 10)


@benchgroup "Series{0}" begin
    @bench "Mean" Series(y, Mean())
    @bench "Variance" Series(y, Variance())
    @bench "CStat{Mean}" Series(y .* im, CStat(Mean()))
end
@benchgroup "Series{1}" begin
    @bench "CovMatrix" Series(x, CovMatrix(10))
    @bench "KMeans" Series(x, KMeans(10, 5))
end
@benchgroup "Series{(1, 0)}" begin
    @bench "LinReg" Series((x,y), LinReg(10))
    @bench "StatLearn SGD" Series((x,y), StatLearn(10, SGD()))
end

end #module
