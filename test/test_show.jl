#-----------------------------------------------------------------------# Show
info("Show")
for o = [
        AutoCov(5),
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

o = CallFun(Mean(), x -> println("this should print twice"))
Series(ones(2), o)
@test value(o) == 1.0

println("\n\n")