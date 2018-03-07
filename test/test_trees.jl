@testset "NodeStats" begin 
    data = (randn(1000, 10), rand(Bool, 1000))
    s = series(data, NodeStats(10, Bool))
end