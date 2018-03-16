module OnlineStatsTests 

using OnlineStats, Test
import StatsBase: countmap
import DataStructures: SortedDict

#-----------------------------------------------------------------------# test utils
const y = randn(1000)
const y2 = randn(1000)
const x = randn(1000, 5)
const x2 = randn(1000, 5)

function test_merge(o, y1, y2, compare = ≈)
    o2 = copy(o)
    fit!(o, y1)
    fit!(o2, y2)
    merge!(o, o2)
    fit!(o2, y1)
    for (v1, v2) in zip(value(o), value(o2))
        @test compare(v1, v2)
    end
end

function test_exact(o, y, fo, fy, compare = ≈)
    fit!(o, y)
    for (v1, v2) in zip(fo(o), fy(y))
        @test compare(v1, v2)
    end
end

#-----------------------------------------------------------------------# includes 
include("test_stats.jl")

end #module

# module OnlineStatsTest

# using OnlineStats, StatsBase, QuadGK, Base.Test
# import OnlineStatsBase

# #-----------------------------------------------------------------------# helpers
# function merge_vs_fit(o, y1, y2; kw...)
#     s1 = series(y1, o; kw...)
#     s2 = series(y2, copy(o); kw...)
#     merge!(s1, s2)
#     fit!(s2, y1)
#     @test nobs(s1) == nobs(s2)
#     first(stats(s1)), first(stats(s2))
# end

# # test: merge is same as fit!
# function test_merge(o, y1, y2, compare = ≈)
#     o1, o2 = merge_vs_fit(o, y1, y2)
#     @test all(compare.(value(o1), value(o2)))
# end

# # test: fo(o) == fy(y)
# function test_exact(o, y, fo, fy, compare = ≈)
#     s = Series(y, o)
#     @test all(compare.(fo(o), fy(y)))
# end


# #-----------------------------------------------------------------------# Data
# const y = randn(100)
# const y2 = randn(100)
# const x = randn(100, 5)
# const x2 = randn(100, 5)

# #-----------------------------------------------------------------------# test files
# include("test_show.jl")
# include("test_series.jl")

# println()
# println()
# info("Testing Stats:")
# include("test_trees.jl")
# include("test_stats.jl")
# include("test_visualizations.jl")

# println()
# println()
# info("Testing Everything else")
# #-----------------------------------------------------------------------# BiasVec
# @testset "BiasVec" begin 
#     v = rand(5)
#     b = OnlineStats.BiasVec(v, 1.0)
#     @test length(b) == 6 
#     @test b == vcat(v, 1.0)
#     @test size(b) == (6,)
#     @test all(OnlineStats.BiasVec(v, 1.0) .== OnlineStats.BiasVec(v, 1))
#     @test all(OnlineStats.BiasVec(v, 1.0) .== OnlineStats.BiasVec(v))
# end
# #-----------------------------------------------------------------------# mapblocks
# @testset "mapblocks" begin 
#     data = randn(10, 5)
#     o = CovMatrix(5)
#     s = Series(o)
#     mapblocks(3, data, Rows()) do xi
#         fit!(s, xi)
#     end
#     i = 0
#     mapblocks(2, data, Cols()) do xi 
#         i += 1
#     end
#     @test i == 3
#     @test cov(o) ≈ cov(data)
#     i = 0
#     mapblocks(3, rand(5)) do xi
#         i += 1
#     end
#     @test i == 2
#     s = Series(LinReg(5))
#     mapblocks(11, (x, y)) do xy
#         fit!(s, xy)
#     end
#     @test value(s)[1] ≈ x\y
#     @test_throws Exception mapblocks(info, (randn(100,5), randn(3)))
#     @test_throws Exception OnlineStats._nobs((randn(100,5), randn(3)), Cols())
# end
# @testset "Utils" begin 
#     @test merge([Mean(), Mean(), Mean()]) == Mean()
# end
# end #module
