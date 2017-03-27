module SummaryTest

using OnlineStats, StatsBase, Base.Test

y1 = randn(500)
y2 = randn(501)
y = vcat(y1, y2)

@testset "Summary" begin
@testset "Mean" begin
    o = fit(Mean(), y1)
    @test value(o, 1) ≈ mean(y1)
    @test nobs(o) == 500

    o2 = Series(y2, Mean())
    @test value(o2, 1) ≈ mean(y2)

    o3 = merge(o, o2)
    @test value(o3, 1) ≈ mean(y)
end
@testset "Variance" begin
    o = fit(Variance(), y1)
    @test value(o, 1) ≈ var(y1)
end
@testset "Extrema" begin
    o = fit(Extrema(), y1)
    @test value(o, 1) == extrema(y1)
end
@testset "QuantileMM/QuantileSGD" begin
    o = Series(y1, QuantileMM(), QuantileSGD(); weight = LearningRate())
end
@testset "Moments" begin
    x = randn(10_000)
    o = fit(Moments(), x)
end
# @testset "Moments" begin
#     o = Moments(x1)
#     @test mean(o) ≈ mean(x1)
#     @test var(o) ≈ var(x1)
#     @test std(o) ≈ std(x1)
#     @test skewness(o) ≈ skewness(x1) atol=.01
#     @test kurtosis(o) ≈ kurtosis(x1) atol=.1
# end
# @testset "Diff / Diffs" begin
#     Diff()
#     Diff(Float64)
#     Diff(Float32)
#     Diff(Int64)
#     Diff(Int32)
#     y = randn(100)
#     o = Diff(y)
#     @test typeof(o) == Diff{Float64}
#     @test last(o) == y[end]
#     @test diff(o) == y[end] - y[end-1]
#     @test value(o) == diff(o)
#     y = rand(Int, 100)
#     o = Diff(y)
#     @test typeof(o) == Diff{Int64}
#     @test last(o) == y[end]
#     @test diff(o) == y[end] - y[end-1]
#
#     Diffs(10)
#     Diffs(Int32, 10)
#     y = randn(100, 10)
#     o = Diffs(y)
#     @test last(o) == vec(y[end, :])
#     @test diff(o) == vec(y[end, :] - y[end-1, :])
#     @test value(o) == diff(o)
# end
# @testset "Sum / Sums" begin
#     Sum()
#     Sum(Float64)
#     Sum(Float32)
#     Sum(Int64)
#     Sum(Int32)
#     y = randn(100)
#     o = Sum(y)
#     @test typeof(o) == Sum{Float64}
#     @test sum(o) ≈ sum(y)
#     @test value(o) == sum(o)
#     y = rand(Int, 100)
#     o = Sum(y)
#     @test typeof(o) == Sum{Int64}
#     @test sum(o) ≈ sum(y)
#
#     Sums(10)
#     Sums(Int32, 10)
#     y = randn(100, 10)
#     o = Sums(y)
#     @test sum(o) ≈ vec(sum(y,1))
#     @test value(o) == sum(o)
# end
end # summary
end #module
