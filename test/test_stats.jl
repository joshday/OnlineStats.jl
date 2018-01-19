println()
println()
info("Testing Stats:")
#-----------------------------------------------------------------------# Count 
@testset "Count" begin 
    for n in rand(10:50, 20)
        o = Count()
        s = Series(rand(n), o)
        @test value(o) == nobs(s)
    end
    test_merge(Count(), Count(), rand(100), rand(100))
end