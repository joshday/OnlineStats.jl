module OnlineStatsTest

using OnlineStats, Base.Test
import OnlineStatsBase
using StatsBase

#-----------------------------------------------------------------------# helpers
function merge_vs_fit(o, y1, y2; kw...)
    s1 = series(y1, o; kw...)
    s2 = series(y2, copy(o); kw...)
    merge!(s1, s2)
    fit!(s2, y1)
    @test nobs(s1) == nobs(s2)
    first(stats(s1)), first(stats(s2))
end

# test: merge is same as fit!
function test_merge(o, y1, y2, compare = ≈)
    o1, o2 = merge_vs_fit(o, y1, y2)
    @test all(compare.(value(o1), value(o2)))
end

# test: fo(o) == fy(y)
function test_exact(o, y, fo, fy, compare = ≈)
    s = Series(y, o)
    @test all(compare.(fo(o), fy(y)))
end


#-----------------------------------------------------------------------# Data
const y = randn(100)
const y2 = randn(100)
const x = randn(100, 5)
const x2 = randn(100, 5)

#-----------------------------------------------------------------------# test files
include("test_show.jl")
include("test_series.jl")
include("test_stats.jl")

println()
println()
info("Testing Everything else")
#-----------------------------------------------------------------------# OnlineStatsBase 
mutable struct Counter <: OnlineStatsBase.ExactStat{0}
    value::Int
    Counter() = new(0)
end
OnlineStatsBase._fit!(o::Counter, y::Real, w::Float64) = (o.value += 1)
@testset "OnlineStatsBase" begin 
    test_exact(Counter(), y, value, length)
end

#-----------------------------------------------------------------------# other
@testset "BiasVec" begin 
    v = rand(5)
    b = OnlineStats.BiasVec(v, 1.0)
    @test length(b) == 6 
    @test b == vcat(v, 1.0)
    @test size(b) == (6,)
    @test all(OnlineStats.BiasVec(v, 1.0) .== OnlineStats.BiasVec(v, 1))
end

#-----------------------------------------------------------------------# mapblocks
@testset "mapblocks" begin 
    data = randn(10, 5)
    o = CovMatrix(5)
    s = Series(o)
    mapblocks(3, data, Rows()) do xi
        fit!(s, xi)
    end
    i = 0
    mapblocks(2, data, Cols()) do xi 
        i += 1
    end
    @test i == 3
    @test cov(o) ≈ cov(data)
    i = 0
    mapblocks(3, rand(5)) do xi
        i += 1
    end
    @test i == 2
    s = Series(LinReg(5))
    mapblocks(11, (x, y)) do xy
        fit!(s, xy)
    end
    @test value(s)[1] ≈ x\y
    @test_throws Exception mapblocks(info, (randn(100,5), randn(3)))
    @test_throws Exception OnlineStats._nobs((randn(100,5), randn(3)), Cols())
end

# #-----------------------------------------------------------------------# BiasVec


# #-----------------------------------------------------------------------# Group 
# @testset "Group" begin 
#     g = [Mean() Variance()]
#     data = randn(100, 2)
#     Series(data, g)
#     @test mean(g.stats[1]) ≈ mean(data[:, 1])
#     @test var(g.stats[2]) ≈ var(data[:, 2])
    
#     # merge 
#     x = [randn(100) rand(1:5, 100)]
#     x2 = [randn(100) rand(1:5, 100)]
#     s1 = Series(x, [Mean() CountMap(Float64)])
#     s2 = Series(x2, [Mean() CountMap(Float64)])
#     merge!(s1, s2)
#     fit!(s2, x)
#     @test value(s1)[1][1] ≈ value(s2)[1][1]   # Mean
#     @test value(s1)[1][2] == value(s2)[1][2]  # CountMap
# end

# #-----------------------------------------------------------------------# Partition
# @testset "Partition" begin 
#     o = Partition(Variance(), 5)
#     s = Series(o)
#     for i in 1:20
#         fit!(s, rand())
#         @test length(o.parts) <= 10
#     end
    
#     # merge 
#     o = Partition(Mean())
#     y = randn(100)
#     Series(y, o)
#     @test value(merge(o)) ≈ mean(y)

#     # merge! 
#     o1, o2 = Partition(Mean()), Partition(Mean())
#     y1, y2 = randn(100), randn(100)
#     s1, s2 = Series(y1, o1), Series(y2, o2)
#     merge!(s1, s2)
#     @test length(o1.parts) <= o1.b
#     @test value(merge(o1)) ≈ mean(vcat(y1, y2))
#     @test nobs(o2) == 100 
#     @test nobs(o1) == 200

#     o1, o2 = Partition(Mean()), Partition(Mean())
#     y1, y2 = randn(101), randn(202)
#     s1, s2 = Series(y1, o1), Series(y2, o2)
#     merge!(s1, s2)
#     @test value(merge(o1)) ≈ mean(vcat(y1, y2))
# end



# #-----------------------------------------------------------------------# NBClassifier
# @testset "NBClassifier" begin 
#     n, p = 10000, 5
#     x = randn(n, p)
#     y = x * linspace(-1, 1, p) .> 0
#     o = NBClassifier(p, Bool, 100)
#     Series((x,y), o)
#     # @show predict(o, [0,0,0,0,1])
#     @test classify(o, [0,0,0,0,1])
# end

# #-----------------------------------------------------------------------# Lag 
# @testset "Lag" begin 
#     y = randn(100)
#     o = Lag(10)
#     s = Series(y, o)
#     @test reverse(value(o)) == y[end-9:end]

#     data = rand(Bool, 100)
#     o = Lag(5, Bool)
#     s = Series(data, o)
#     @test reverse(value(o)) == data[96:100]
# end





# #-----------------------------------------------------------------------# Tests



# @testset "LinRegBuilder" begin
#     n, p = 100, 10
#     x = randn(n, p)
#     o = LinRegBuilder(p)
#     Series(x, o)
#     for k in 1:p
#         @test coef(o; y=k, verbose=false) ≈ [x[:, setdiff(1:p, k)] ones(n)] \ x[:, k]
#     end
#     @test coef(o; y=3, x=[1, 2], verbose=false, bias=false) ≈ x[:, [1, 2]] \ x[:, 3]
#     @test coef(o; y=3, x=[2, 1], verbose=false, bias=false) ≈ x[:, [2, 1]] \ x[:, 3]
#     @test coef(o) == value(o)
# end


# @testset "LinReg" begin 
#     o = LinReg(5)
#     @test nobs(o) == 0
#     x, y = randn(100,5), randn(100)
#     s = Series((x,y), o)
#     @test nobs(o) == 100
#     @test coef(o) ≈ x\y
#     @test predict(o, x) ≈ x * (x\y)
#     @test predict(o, x', Cols()) ≈ x * (x\y)
#     o2 = LinReg(5)
#     s2 = Series((x,y), o2)
#     @test LinReg(5, .1) == LinReg(5, fill(.1, 5))
#     @test predict(o2, zeros(5)) == 0.0
#     # check both fit! methods
#     o = LinReg(5)
#     fit!(o, (randn(5), randn()), .1)
#     fit!(o, randn(5), randn(), .1)
# end
# @testset "Hist" begin 
#     y = rand(1000)

#     # Adaptive Bins
#     o = Hist(100)
#     Series(y, o)
#     for val in value(o)[1]
#         @test 0 < val < 1
#     end
#     @test sum(value(o)[2]) == 1000

#     # Both
#     o2 = Hist(50)
#     o3 = Hist(-5:.01:5)
#     Series(randn(1000), o2, o3)
#     merge!(o, o2, .1)

#     @testset "summary stats" begin
#         y = randn(1000)
#         o = Hist(50)
#         o2 = Hist(-5:.01:5)
#         Series(y, o, o2)
#         for o in [o, o2]
#             @test sum(value(o)[2]) == 1000
#             @test median(o) ≈ median(y) atol = .1
#             @test var(o)    ≈ var(y)    atol = .1
#             @test std(o)    ≈ std(y)    atol = .1
#             @test mean(o)   ≈ mean(y)   atol = .1
#         end
#         o = Hist(AdaptiveBins(Int, 25))
#         y = 1:25 
#         Series(y, o)
#         @test extrema(o) == extrema(y)
#         @test quantile(o) ≈ quantile(y)
#     end
# end
# @testset "Other" begin 
#     o = Variance()
#     @test nobs(o) == 0
#     Series(y, o)
#     @test nobs(o) == length(y)
#     @test length(5Mean()) == 5
#     @test sum(Sum()) == 0
# end
# @testset "Diff" begin 
#     o = Diff(Int)
#     Series([1,2], o)
#     @test diff(o) == 1
#     @test last(o) == 2
#     o = Diff(Float64)
#     Series([1,2], o)
#     @test diff(o) == 1
#     @test last(o) == 2
# end
# @testset "ReservoirSample" begin 
#     y = randn(100)
#     o = ReservoirSample(100)
#     Series(y, o)
#     @test value(o) == y
#     o = ReservoirSample(10)
#     Series(y, o)
#     for yi in value(o)
#         @test yi in y 
#     end
# end

# @testset "KMeans" begin 
#     o = KMeans(5, 4)
#     Series(randn(100, 5), o)
#     @test size(value(o)) == (5, 4)
# end
end #module
