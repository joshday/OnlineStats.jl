module MomentsTest
using OnlineStats, Distributions, FactCheck

facts("Moments") do
    d = Uniform()
    y = rand(100000)
    o = Moments()
    update!(o, y)
    o2 = Moments(y)
    @fact nobs(o) => nobs(o2)
    @fact nobs(o) => 100000

    state(o)
    @fact statenames(o) => [:μ, :σ², :skewness, :kurtosis, :nobs]
    @fact mean(o) => roughly(mean(o), .001)
    @fact var(o) => roughly(var(y), .001)
    @fact std(o) => roughly(std(y), .001)
    @fact skewness(o) => roughly(skewness(y), .05)
    @fact kurtosis(o) => roughly(kurtosis(y), .05)
end

end
