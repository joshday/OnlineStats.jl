module SummaryTest

using OnlineStats, StatsBase, Base.Test

x = randn(500)
x1 = randn(500)
x2 = randn(501)
xs = hcat(x1, x)

@testset "Summary" begin
@testset "Mean / Means" begin
    o = Mean()
    fit!(o, x1, 5)
    @test mean(o) ≈ mean(x1)
    @test nobs(o) == 500
    o = Mean(x2)
    @test mean(o) ≈ mean(x2)
    @test mean(o) == value(o)
    @test center(o, x[1]) == x[1] - mean(o)

    o = Means(2)
    fit!(o, xs, 5)
    @test mean(o) ≈ vec(mean(xs, 1))
    fit!(o, xs, 1)
    o = Means(xs)
    o2 = Means(2)
    fit!(o2, xs)
    @test mean(o) ≈ mean(o2)
    @test center(o, vec(xs[1, :])) == vec(xs[1, :]) - mean(o)
end
@testset "Variance / Variances" begin
    o = Variance(x1)
    @test var(o) ≈ var(x1)
    o = Variance()
    fit!(o, x1)
    @test var(o)            ≈ var(x1)
    @test std(o)            ≈ std(x1)
    @test mean(o)           ≈ mean(x1)
    @test var(o)            == value(o)
    @test center(o, x[1])   == x[1] - mean(o)
    @test zscore(o, x[1])   == (x[1] - mean(o)) / std(o)

    o = Variances(xs)
    @test var(o) ≈ vec(var(xs, 1))
    @test mean(o) ≈ vec(mean(xs, 1))
    @test std(o) ≈ vec(std(xs, 1))
    @test var(o) == value(o)
    o2 = Variances(2)
    fit!(o2, xs)
    @test var(o) ≈ var(o2)
    @test center(o, vec(xs[1, :])) == vec(xs[1, :]) - mean(o)
    @test zscore(o, vec(xs[1, :])) == (vec(xs[1, :]) - mean(o)) ./ std(o)
    @test zscore(Variances(5), ones(5)) == ones(5)
end
@testset "CovMatrix" begin
    o = CovMatrix(xs)
    @test cov(o) ≈ cov(xs)
    @test cor(o) ≈ cor(xs)

    o2 = CovMatrix(2)
    fit!(o2, xs)
    @test cov(o) ≈ cov(o2)
    @test cor(o) ≈ cor(o2)
    @test value(o) ≈ value(o2)
    @test mean(o) ≈ mean(o2)
    @test mean(o2) ≈ vec(mean(xs, 1))
    @test var(o) ≈ vec(var(xs, 1))
    @test std(o) ≈ vec(std(xs, 1))
    fit!(o2, xs, 1)
end
@testset "Extrema" begin
    o = Extrema(x1)
    @test extrema(o) == extrema(x1)
    o2 = Extrema()
    fit!(o2, x1)
    @test extrema(o) == extrema(o2)
end
@testset "QuantileSGD / QuantileMM" begin
    o = QuantileSGD(x1)
    fit!(o, x2, 2)

    o = QuantileMM(x1)
    fit!(o, x2, 2)
end
@testset "Moments" begin
    o = Moments(x1)
    @test mean(o) ≈ mean(x1)
    @test var(o) ≈ var(x1)
    @test std(o) ≈ std(x1)
    @test_approx_eq_eps skewness(o) skewness(x1) .01
    @test_approx_eq_eps kurtosis(o) kurtosis(x1) .1
end
@testset "Diff / Diffs" begin
    Diff()
    Diff(Float64)
    Diff(Float32)
    Diff(Int64)
    Diff(Int32)
    y = randn(100)
    o = Diff(y)
    @test typeof(o) == Diff{Float64}
    @test last(o) == y[end]
    @test diff(o) == y[end] - y[end-1]
    @test value(o) == diff(o)
    y = rand(Int, 100)
    o = Diff(y)
    @test typeof(o) == Diff{Int64}
    @test last(o) == y[end]
    @test diff(o) == y[end] - y[end-1]

    Diffs(10)
    Diffs(Int32, 10)
    y = randn(100, 10)
    o = Diffs(y)
    @test last(o) == vec(y[end, :])
    @test diff(o) == vec(y[end, :] - y[end-1, :])
    @test value(o) == diff(o)
end
@testset "Sum / Sums" begin
    Sum()
    Sum(Float64)
    Sum(Float32)
    Sum(Int64)
    Sum(Int32)
    y = randn(100)
    o = Sum(y)
    @test typeof(o) == Sum{Float64}
    @test sum(o) ≈ sum(y)
    @test value(o) == sum(o)
    y = rand(Int, 100)
    o = Sum(y)
    @test typeof(o) == Sum{Int64}
    @test sum(o) ≈ sum(y)

    Sums(10)
    Sums(Int32, 10)
    y = randn(100, 10)
    o = Sums(y)
    @test sum(o) ≈ vec(sum(y,1))
    @test value(o) == sum(o)
end
end # summary
end #module
