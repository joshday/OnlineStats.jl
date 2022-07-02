@testset "DPMM parameter constraints test" begin
    μ       = 0.0
    λ       = 1e-3
    α       = 1.1
    β       = 1e-3
    α_dp    = 1.0
    K_max   = 5
    ϵ_birth = 0.5
    ϵ_death = 0.5

    o = DPMM(μ, λ, α, β, α_dp;
             n_comp_max=K_max,
             comp_birth_thres=ϵ_birth,
             comp_death_thres=ϵ_death)

    fit!(o, randn(128))

    @test o.K_max   == K_max
    @test o.ϵ_death ≈ ϵ_death
    @test o.ϵ_birth ≈ ϵ_birth
    @test o.α_dp    ≈ α_dp

    @test o.η₁_prior ≈ λ*μ
    @test o.η₂_prior ≈ -β - λ.*μ.^2/2
    @test o.η₃_prior ≈ α - 1/2
    @test o.η₄_prior ≈ λ/-2

    @test_throws AssertionError DPMM(μ, 0., α, β, α_dp)
    @test_throws AssertionError DPMM(μ, λ, 0., β, α_dp)
    @test_throws AssertionError DPMM(μ, λ, α, 0., α_dp)
    @test_throws AssertionError DPMM(μ, λ, α, β, 0.)
end

@testset "DPMM size test" begin
    μ    = 0.0
    λ    = 1e-3
    α    = 1.1
    β    = 1e-3
    α_dp = 1.0
    o    = DPMM(μ, λ, α, β, α_dp; comp_birth_thres=0.5,
                comp_death_thres=1e-2, n_comp_max=10)   
    fit!(o, [-100, 100])
    @test nobs(o)   == 2
    @test length(o) == 2
end

@testset "DPMM type test" begin
    for T ∈ [Float32, Float64]
        μ    = 0.0  |> T
        λ    = 1e-3 |> T
        α    = 1.1  |> T
        β    = 1e-3 |> T
        α_dp = 1.0  |> T
        o    = DPMM(μ, λ, α, β, α_dp)   
        fit!(o, 1)
        fit!(o, 1.)
        fit!(o, 1f0)
        @test eltype(o.α_dp) == T
        @test eltype(o.ϵ_birth) == T
        @test eltype(o.ϵ_death) == T
        @test eltype(o.η₁_prior) == T
        @test eltype(o.η₂_prior) == T
        @test eltype(o.η₃_prior) == T
        @test eltype(o.η₄_prior) == T
        @test eltype(o.w) == T
        @test eltype(o.η₁) == T
        @test eltype(o.η₂) == T
        @test eltype(o.η₃) == T
        @test eltype(o.η₄) == T
    end
end

@testset "DPMM max number of components test" begin
    μ    = 0.0
    λ    = 1e-5
    α    = 2.0
    β    = 1e-5
    α_dp = 1.0
    o    = DPMM(μ, λ, α, β, α_dp; comp_birth_thres=0.01,
                comp_death_thres=1e-10, n_comp_max=5)   
    fit!(o, -100:1:100)
    @test length(o) == 5
    q = value(o)
    @test length(Distributions.components(q)) == 5
end
