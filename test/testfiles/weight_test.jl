module WeightTest

using TestSetup, OnlineStats, FactCheck
O = OnlineStats

facts(@title "Weighting") do
    w = EqualWeight()
    @fact O.weight!(w, 1) --> 1.0

    w = ExponentialWeight(.5)
    @fact O.weight!(w, 1) --> 1.0
    O.weight!(w, 10)
    @fact O.weight!(w, 1) --> .5

    w = LearningRate(.6)
    @fact O.weight!(w, 1) --> 1.0

    w = LearningRate2(10, 1)
    @fact O.weight!(w, 1) --> w.γ / (1.0 + w.γ)
end

end
