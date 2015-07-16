module Sweep_test

using OnlineStats
using FactCheck

facts("sweep!()") do
    for rep in 1:5
        n = rand(1:10_000, 1)[1]
        p = rand(1:min(n-1, 1000), 1)[1]
        A = rand(n, p)

        A = A' * A
        B = copy(A)
        sweep!(A, 1:p-1)
        sweep!(A, 1:p-1, true)
        sweep!(A, 1:p-1)
        sweep!(A, 1:p-1, true)


        @fact A => roughly(B)

        x = randn(n , p)
        y = vec(sum(x, 2)) + randn(n)
        xy = hcat(x, y)
        A = xy' * xy
        sweep!(A, 1:p)
        β = vec(A[end, 1:p])
        @fact β => roughly(vec(inv(x'x) * x'y))
    end
end

end  # module



