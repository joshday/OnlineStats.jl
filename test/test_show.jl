#-----------------------------------------------------------------------# Show
info("Show")
for o = [
        AutoCov(5),
        Bootstrap(Mean()),
        CallFun(Mean(), info), 
        CountMap(Int),
        CovMatrix(5), 
        CStat(Mean()), 
        Diff(), 
        Extrema(), 
        FastNode(2, 5),
        FastTree(2, 5),
        FastForest(2, 5),
        Hist(5), 
        Hist(1:5),
        HyperLogLog(4), 
        LinReg(5), 
        LinRegBuilder(5), 
        Mean(), 
        Moments(), 
        Mosaic(Int, Int),
        MV(5, Mean()),
        OrderStats(10), 
        Partition(Mean(), 5),
        PQuantile(),
        ProbMap(Int),
        Quantile(), 
        ReservoirSample(10), 
        StatLearn(5), 
        Sum(), 
        Unique(Int),
        Variance(), 
        [Mean() Variance()], 
        OnlineStats.Part(Mean(), 1, 1),
        NBClassifier(5, Int),
        2Mean(),
        25Mean(),
        Series(Mean()),
        Series(Mean(), Variance()),
        series(Mean(), transform = abs)
    ]
    println(o)
end
coef(LinRegBuilder(5), verbose=true)
o = CallFun(Mean(), x -> println("this should print twice"))
Series(ones(2), o)
@test value(o) == 1.0