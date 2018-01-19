#-----------------------------------------------------------------------# Show
info("Show")
for o = [
        Mean(), 
        Variance(), 
        CStat(Mean()), 
        CovMatrix(5), 
        Diff(), 
        Extrema(), 
        HyperLogLog(4), 
        Moments(), 
        OrderStats(10), 
        Quantile(), 
        PQuantile(),
        ReservoirSample(10), 
        Sum(), 
        StatLearn(5), 
        Hist(5), 
        Hist(1:5),
        LinRegBuilder(5), 
        LinReg(5), 
        CallFun(Mean(), info), 
        Bootstrap(Mean()),
        [Mean() Variance()], 
        Partition(Mean(), 5),
        2Mean(),
        25Mean(),
        Series(Mean()),
        Series(Mean(), Variance()),
        series(Mean(), transform = abs)
    ]
    println(o)
end

Series(randn(2), CallFun(Mean(), x -> println("this should print twice")))

println("\n\n")