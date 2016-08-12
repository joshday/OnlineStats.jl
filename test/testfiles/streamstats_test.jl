module StreamStatsTest
using OnlineStats, StatsBase, Base.Test

x = randn(500)
x1 = randn(500)
x2 = randn(501)
xs = hcat(x1, x)

@testset "StreamStats" begin
@testset "HyperLogLog" begin
    o = HyperLogLog(5)
    y = rand(Bool, 10000)
    for yi in y
        fit!(o, yi)
    end
    @test_approx_eq_eps value(o) 2 .5
end
@testset "Bootstrap" begin
    @testset "BernoulliBootstrap" begin
        o = Mean()
        o = BernoulliBootstrap(o, mean, 1000)
        fit!(o, rand(10000))
        cached_state(o)
        mean(o)
        std(o)
        var(o)
        confint(o)
        confint(o, .95, :normal)
        @test_throws Exception confint(o, .95, :fakemethod)
        replicates(o)
    end
    @testset "PoissonBootstrap" begin
        o = Mean()
        o = PoissonBootstrap(o, mean, 1000)
        fit!(o, rand(1000))
        cached_state(o)
        mean(o)
        std(o)
        var(o)
        confint(o)
        replicates(o)
        # vector input
        o = Means(2)
        o = PoissonBootstrap(o, mean, 1000)
        for i in 1:10 fit!(o, rand(2)) end
        cached_state(o)
        @test length(mean(o)) == 2
        std(o)
        var(o)
        #confint(o) not supported right now
        replicates(o)
    end
    @testset "FrozenBootstrap" begin
        o = Mean()
        o = BernoulliBootstrap(o, mean, 1000)

        o2 = Mean()
        o2 = BernoulliBootstrap(o2, mean, 1000)
        fit!(o, randn(100))
        fit!(o2, randn(100) + 3)
        d = o - o2
        mean(d)
        var(d)
        std(d)
        confint(d)
        replicates(o)
    end
end # bootstrap
end # streamstats
end # module
