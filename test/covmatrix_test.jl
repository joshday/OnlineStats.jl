using OnlineStats
using Base.Test

n1, n2, n3, n4 = rand(1:1_000_000, 4)
x1 = rand(n1, 10)
x2 = rand(n2, 10)
x3 = rand(n3, 10)
x4 = rand(n4, 10)

obj = OnlineStats.CovarianceMatrix(x1)
OnlineStats.update!(obj, x2)
OnlineStats.update!(obj, x3)
OnlineStats.update!(obj, x4)

c = cov([x1,x2,x3,x4])
for i in 1:10
    for j in 1:i
        @test_approx_eq_eps(c[i,j],
                            OnlineStats.state(obj)[i,j],
                            1e-10)
    end
end

obj1 = OnlineStats.CovarianceMatrix(x1)
obj2 = OnlineStats.CovarianceMatrix(x2)
obj3 = OnlineStats.CovarianceMatrix(x3)
obj4 = OnlineStats.CovarianceMatrix(x4)

obj3 = merge(obj3, obj4)
merge!(obj2, obj3)
obj5 = merge(obj1, obj2)
merge!(obj1, obj2)
@test obj1.n == obj.n
for i in 1:10
    for j in 1:i
        @test_approx_eq obj1.A[i, j] obj.A[i, j]
            end
end
@test_approx_eq obj1.B obj.B
@test obj5.n == obj.n
@test_approx_eq obj5.A obj.A
@test_approx_eq obj5.B obj.B

# Remove large matrices
x1, x2, x3, x4 = zeros(4)

