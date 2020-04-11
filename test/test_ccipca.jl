@testset "CCIPCA basic tests" begin
    o = CCIPCA(4, 2)
    @test OnlineStats.outdim(o) == 2
    @test OnlineStats.indim(o)  == 4
    @test size(o)               == (4, 2)
    @test length(o) == lastindex(o) == 2
    
    # eigen-vectors and eigen-values are 0 before we fit any values:
    @test o[1] == zeros(Float64, 4)
    @test o[2] == zeros(Float64, 4)
    @test OnlineStats.eigenvalue(o, 1) == 0.0
    @test OnlineStats.eigenvalue(o, 2) == 0.0

    # variation is also a vector of zeros before we fit any values:
    @test OnlineStats.variation(o) == zeros(Float64, 2)

    # first vector added goes straight into the projection matrix:
    u1 = rand(4)
    fit!(o, u1)
    @test o[1] == u1/norm(u1)
    @test o[2] == zeros(Float64, 4)

    # We can get eigen-values individually or in array:
    @test length(OnlineStats.eigenvalues(o)) == 2
    @test OnlineStats.eigenvalues(o)[1] == OnlineStats.eigenvalue(o, 1)
    @test OnlineStats.eigenvalues(o)[2] == OnlineStats.eigenvalue(o, 2)

    # errors if asking for eigen-values or vectors outside of outdim range:
    @test_throws AssertionError OnlineStats.eigenvalue(o,  3)
    @test_throws AssertionError OnlineStats.eigenvalue(o,  0)
    @test_throws AssertionError OnlineStats.eigenvalue(o, -1)

    # errors if trying to fit vector of wrong length:
    @test_throws AssertionError fit!(o, rand(3))
    @test_throws AssertionError fit!(o, rand(5))
end # @testset "CCIPCA basic tests" begin

@testset "Differential test #1 with onlinePCA R package" begin
    # Differential testing with onlinePCA package in R:
    #   lambda <- c(0.0, 0.0)
    #   U <- matrix(rep.int(0, 2*4), nrow = 4, ncol = 2)
    #   library(onlinePCA)
    o = CCIPCA(4, 2)

    #   u1 <- c(1.0, 2.0, 3.0, 4.0)
    u1 = [1.0, 2.0, 3.0, 4.0]
    #   r1 <- ccipca(lambda, U, u1, 0, q=2, l=0);
    fit!(o, u1)
    #   r1$values[1]  # => 5.477226
    @test OnlineStats.eigenvalues(o)[1] ≈ 5.477225575
    ev1 = OnlineStats.eigenvector(o, 1)
    #   r1$vectors[1] # => 0.1825742
    @test isapprox(ev1[1], 0.1825742; atol = 1e-7)
    #   r1$vectors[2] # => 0.3651484
    @test isapprox(ev1[2], 0.3651484; atol = 1e-7)
    #   r1$vectors[3] # => 0.5477226
    @test isapprox(ev1[3], 0.5477226; atol = 1e-7)
    #   r1$vectors[4] # => 0.7302967
    @test isapprox(ev1[4], 0.7302967; atol = 1e-7)
    # Since we have only added one value so far, the 2nd eigenvector is 0
    @test OnlineStats.eigenvector(o, 2) == zeros(Float64, 4)

    #   u2 <- c(3.1, 2.7, 5.6, 3.0)
    u2 = [3.1, 2.7, 5.6, 3.0]
    #   xbar <- (u1 + u2)/2
    #   r2 <- ccipca(r1$values, r1$vectors, u2, 1, q=2, l=0, center = xbar);
    fit!(o, u2)
    #   r2$values[1]  # => 3.011238
    @test isapprox(OnlineStats.eigenvalues(o)[1], 3.011238; atol = 1e-6)
    ev1 = OnlineStats.eigenvector(o, 1)
    #   r2$vectors[1,1] # => 0.2822287
    @test isapprox(ev1[1], 0.2822287; atol = 1e-6)
    #   r2$vectors[2,1] # => 0.3708174
    @test isapprox(ev1[2], 0.3708174; atol = 1e-6)
    #   r1$vectors[3,1] # => 0.6419809
    @test isapprox(ev1[3], 0.6419809; atol = 1e-6)
    #   r1$vectors[4,1] # => 0.6088530
    @test isapprox(ev1[4], 0.6088530; atol = 1e-6)

    #   r2$values[2]  # => 1.500179
    @test isapprox(OnlineStats.eigenvalues(o)[2], 1.500179; atol = 1e-6)
    ev2 = OnlineStats.eigenvector(o, 2)
    #   r2$vectors[1,2] # => 0.520012308
    @test isapprox(ev2[1], 0.520012308; atol = 1e-6)
    #   r2$vectors[2,2] # => -0.003068536
    @test isapprox(ev2[2], -0.003068536; atol = 1e-6)
    #   r1$vectors[3,2] # => 0.457338448
    @test isapprox(ev2[3], 0.457338448; atol = 1e-6)
    #   r1$vectors[4,2] # => -0.721400948
    @test isapprox(ev2[4], -0.721400948; atol = 1e-6)
end # @testset "Differential test with onlinePCA R package" begin

function setup_ccipca_randomly(indimrange = 4:100, maxn = 200; 
    scalerange = 0.01:0.001:42.42, fit = true)
    indim = rand(indimrange)
    outdim = rand(1:min(5, indim-1))
    o = CCIPCA(indim, outdim)
    us = Vector{Float64}[]
    for _ in 1:rand(1:maxn)
        u = rand(scalerange, indim)
        push!(us, u)
        if fit
            fit!(o, u)
        end
    end
    return o, us
end

@testset "fit!+transform == fittransform! and callable (random testing)" begin
    function test_f!tr_equals_ft!r(o1, o2, u)
        fit!(o1, u)
        uproj1 = OnlineStats.transform(o1, u)
        urec1  = OnlineStats.reconstruct(o1, uproj1)
        uproj2 = OnlineStats.fittransform!(o2, u)
        urec2 = OnlineStats.reconstruct(o2, uproj2)

        @test uproj1 == uproj2
        @test urec1 == urec2

        # calling the ccipca object is same as transform
        uproj1b = o1(u)
        @test uproj1b == uproj1 
    end

    # Random testing with different indims and outdims
    for _ in 1:10
        o1, us = setup_ccipca_randomly(4:100, 30; fit = false)
        o2 = CCIPCA(OnlineStats.indim(o1), OnlineStats.outdim(o1))
        for u in us
            test_f!tr_equals_ft!r(o1, o2, u)
        end
    end
end

@testset "sort! and variation (random testing)" begin
    for _ in 1:10
        o, us = setup_ccipca_randomly(4:42, 25)
        lambdapre = deepcopy(o.lambda)
        Upre = deepcopy(o.U)
        sort!(o)

        # Ensure eigen-values and -vectors are correctly sorted:
        for i in 1:(OnlineStats.outdim(o)-1)
            evi = OnlineStats.eigenvalue(o, i)
            # earlier eigenvalues are larger than equal later ones
            @test evi >= OnlineStats.eigenvalue(o, i+1)
            # current eigenvector is same as where current eigenvalue was previously
            idx = findfirst(ev -> ev == evi, lambdapre)
            @test OnlineStats.eigenvector(o, i) == Upre[:, idx]
        end

        # Ensure variation is also sorted and has valid ranges
        v = OnlineStats.variation(o)
        @test length(v) == OnlineStats.outdim(o)
        @test isapprox(sum(v), 1.0; atol=1e-4)
        for i in 1:(OnlineStats.outdim(o)-1)
            @test v[i] >= v[i+1]
            @test 0.0 <= v[i] <= 1.0
        end
    end
end