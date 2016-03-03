module SummaryTest

using TestSetup, OnlineStats, FactCheck

x = randn(500)
x1 = randn(500)
x2 = randn(501)
xs = hcat(x1, x)

facts(@title "Mean / Means") do
    o = Mean()
    fit!(o, x1, 5)
    @fact mean(o) --> roughly(mean(x1))
    @fact nobs(o) --> 500
    o = Mean(x2)
    @fact mean(o) --> roughly(mean(x2))
    @fact mean(o) --> value(o)
    @fact center(o, x[1]) --> x[1] - mean(o)

    o = Means(2)
    fit!(o, xs, 5)
    @fact mean(o) --> roughly(vec(mean(xs, 1)))
    fit!(o, xs, 1)
    o = Means(xs)
    o2 = Means(2)
    fit!(o2, xs)
    @fact mean(o) --> roughly(mean(o2))
    @fact center(o, vec(xs[1, :])) --> vec(xs[1, :]) - mean(o)
end

facts(@title "Variance / Variances") do
    o = Variance(x1)
    @fact var(o) --> roughly(var(x1))
    o = Variance()
    fit!(o, x1, 5)
    @fact var(o) --> roughly(var(x1))
    @fact std(o) --> roughly(std(x1))
    @fact mean(o) --> roughly(mean(x1))
    @fact var(o) --> value(o)
    @fact center(o, x[1]) --> x[1] - mean(o)
    @fact standardize(o, x[1]) --> (x[1] - mean(o)) / std(o)

    o = Variances(xs)
    @fact var(o) --> roughly(vec(var(xs, 1)))
    @fact mean(o) --> roughly(vec(mean(xs, 1)))
    @fact std(o) --> roughly(vec(std(xs, 1)))
    @fact var(o) --> value(o)
    o2 = Variances(2)
    fit!(o2, xs)
    @fact var(o) --> roughly(var(o2))
    @fact center(o, vec(xs[1, :])) --> vec(xs[1, :]) - mean(o)
    @fact standardize(o, vec(xs[1, :])) --> (vec(xs[1, :]) - mean(o)) ./ std(o)
end

facts(@title "CovMatrix") do
    o = CovMatrix(xs)
    @fact cov(o) --> roughly(cov(xs))
    @fact cor(o) --> roughly(cor(xs))

    o2 = CovMatrix(2)
    fit!(o2, xs)
    @fact cov(o) --> roughly(cov(o2))
    @fact cor(o) --> roughly(cor(o2))
    @fact value(o) --> roughly(value(o2))
    @fact mean(o) --> roughly(mean(o2))
    @fact mean(o2) --> roughly(vec(mean(xs, 1)))
    @fact var(o) --> roughly(vec(var(xs, 1)))
    @fact std(o) --> roughly(vec(std(xs, 1)))
    fit!(o2, xs, 1)
end

facts(@title "Extrema") do
    o = Extrema(x1)
    @fact extrema(o) --> extrema(x1)

    o2 = Extrema()
    fit!(o2, x1)
    @fact extrema(o) --> extrema(o2)
end

facts(@title "QuantileSGD / QuantileMM") do
    o = QuantileSGD(x1)
    fit!(o, x2, 2)

    o = QuantileMM(x1)
    fit!(o, x2, 2)
end

facts(@title "Moments") do
    o = Moments(x1)
    @fact mean(o) --> roughly(mean(x1))
    @fact var(o) --> roughly(var(x1))
    @fact std(o) --> roughly(std(x1))
    @fact skewness(o) --> roughly(skewness(x1), .01)
    @fact kurtosis(o) --> roughly(kurtosis(x1), .1)
end

facts(@title "Diff / Diffs") do
    Diff()
    Diff(Float64)
    Diff(Float32)
    Diff(Int64)
    Diff(Int32)
    y = randn(100)
    o = Diff(y)
    @fact typeof(o) --> Diff{Float64}
    @fact last(o) --> y[end]
    @fact diff(o) --> y[end] - y[end-1]
    @fact value(o) --> diff(o)
    y = rand(Int, 100)
    o = Diff(y)
    @fact typeof(o) --> Diff{Int64}
    @fact last(o) --> y[end]
    @fact diff(o) --> y[end] - y[end-1]

    Diffs(10)
    Diffs(Int32, 10)
    y = randn(100, 10)
    o = Diffs(y)
    @fact last(o) --> vec(y[end, :])
    @fact diff(o) --> vec(y[end, :] - y[end-1, :])
    @fact value(o) --> diff(o)
end


facts(@title "Sum / Sums") do
    Sum()
    Sum(Float64)
    Sum(Float32)
    Sum(Int64)
    Sum(Int32)
    y = randn(100)
    o = Sum(y)
    @fact typeof(o) --> Sum{Float64}
    @fact sum(o) --> sum(y)
    @fact value(o) --> sum(o)
    y = rand(Int, 100)
    o = Sum(y)
    @fact typeof(o) --> Sum{Int64}
    @fact sum(o) --> sum(y)

    Sums(10)
    Sums(Int32, 10)
    y = randn(100, 10)
    o = Sums(y)
    @fact sum(o) --> vec(sum(y,1))
    @fact value(o) --> sum(o)
end



end #module
