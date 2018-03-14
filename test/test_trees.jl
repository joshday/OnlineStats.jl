@testset "FastTree" begin 
    data = rand(10^4, 5), rand(1:4, 10^4)
    @testset "FastNode" begin 
        o = FastNode(5, 4)
        series(data, o)
        @test nobs(o) == 10^4
        @test OnlineStats.nkeys(o) == 4 
        @test OnlineStats.nvars(o) == 5
        c = data[2]
        trueprobs = [sum(c .== 1), sum(c .== 2), sum(c .== 3), sum(c .== 4)] ./ length(c)
        @test probs(o) == trueprobs
        @test classify(o) == findmax(probs(o))[2]
    end
    o = FastTree(5, 4; splitsize=500)
    s = series(data, o)
    yhat = classify(o, data[1])
    @test mean(yhat .== data[2]) > .25
    @test yhat' == classify(o, data[1]', Cols())
end