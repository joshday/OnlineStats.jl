using OnlineStats
using Base.Test
println("* sweep_test.jl")

for i in 1:10
    n = rand(1:10_000, 1)[1]
    p = rand(1:min(n-1, 1000), 1)[1]
    A = rand(n, p)

    A = A' * A
    B = copy(A)
    sweep!(A, 1:p-1)
    sweep!(A, 1:p-1, true)

    for i in 1:p
        for j in 1:i
            @test_approx_eq_eps(A[i, j], B[i, j], 1e-6)
        end
    end
end


# clean up
A = 0
