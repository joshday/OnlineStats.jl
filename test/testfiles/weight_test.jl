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
end

end
