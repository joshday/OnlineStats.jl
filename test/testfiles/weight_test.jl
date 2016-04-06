module WeightTest

using TestSetup, OnlineStats, FactCheck
O = OnlineStats

facts(@title "Weighting") do
    context(@subtitle "EqualWeight") do
        w = EqualWeight()
        O.updatecounter!(w)
        @fact O.weight(w) --> 1.0
        O.updatecounter!(w, 5)
        @fact O.weight(w, 5) --> 5 / 6
    end
    context(@subtitle "ExponentialWeight") do
        w = ExponentialWeight(.5)
        O.updatecounter!(w)
        @fact O.weight(w) --> 0.5
        O.updatecounter!(w, 5)
        @fact O.weight(w) --> 0.5
        @fact ExponentialWeight(5).λ --> ExponentialWeight(1/3).λ
    end
    context(@subtitle "BoundedEqualWeight") do
        w = BoundedEqualWeight(.1)
        O.updatecounter!(w)
        @fact O.weight(w, 1) --> 1.0
        O.updatecounter!(w, 100)
        @fact O.weight(w) --> 0.1
        @fact BoundedEqualWeight(5).λ --> BoundedEqualWeight(1/3).λ
    end
    context(@subtitle "LearningRate") do
        w = LearningRate(.6)
        O.updatecounter!(w)
        @fact O.weight(w) --> 1.0
        O.updatecounter!(w, 5)
        @fact O.weight(w, 5) --> 2 ^ -.6
        @fact O.nups(w) --> 2
    end
    context(@subtitle "LearningRate2") do
        w = LearningRate2(0.5)
        O.updatecounter!(w)
        @fact O.weight(w) --> 1.0
        O.updatecounter!(w, 5)
        @fact O.weight(w, 5) --> 1 / (1 + .5)
    end
end  # facts
end  # module
