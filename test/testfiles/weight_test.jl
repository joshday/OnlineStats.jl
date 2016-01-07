module WeightTest

using TestSetup, OnlineStats, FactCheck
O = OnlineStats

facts(@title "Weighting") do
    w = EqualWeight()
    @fact O.weight(w, 1, 0, 1) --> 1.0

    w = ExponentialWeight(.5)
    @fact O.weight(w, 1, 0, 1) --> 1.0
    @fact O.weight(w, 1, 100, 101) --> .5

    w = LearningRate(.6)
    @fact O.weight(w, 1, 0, 1) --> 1.0

    w = LearningRate2(10, 1)
    @fact O.weight(w, 1, 0, 1) --> w.γ0 / (1.0 + w.γ0)
end

end
