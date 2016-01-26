module WeightTest

using TestSetup, OnlineStats, FactCheck
O = OnlineStats

facts(@title "Weighting") do
    w = EqualWeight()
    @fact O.weight!(w, 1) --> 1.0
    O.weight_noret!(w, 1)

    w = ExponentialWeight(.5)
    @fact O.weight!(w, 1) --> 1.0
    O.weight!(w, 10)
    O.weight_noret!(w, 1)


    w = LearningRate(.6)
    @fact O.weight!(w, 1) --> 1.0
    O.weight_noret!(w, 1)
    @fact O.nups(w) --> 2

    w = LearningRate2(10, 1)
    @fact O.weight!(w, 1) --> w.γ / (1.0 + w.γ)
    O.weight_noret!(w, 1)
end

end
