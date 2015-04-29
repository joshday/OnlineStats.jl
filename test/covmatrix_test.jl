using OnlineStats
using Base.Test
println("* covmatrix_test.jl")

# create 4 batches
n1, n2, n3, n4 = rand(1:1_000_000, 4)
x1 = rand(n1, 10)
x2 = rand(n2, 10)
x3 = rand(n3, 10)
x4 = rand(n4, 10)

# update!
obj = OnlineStats.CovarianceMatrix(x1)
@test statenames(obj) == [:μ, :Σ, :nobs]
@test state(obj) == Any[mean(obj), cov(obj), nobs(obj)]
OnlineStats.update!(obj, x2)
OnlineStats.update!(obj, x3)
OnlineStats.update!(obj, x4)

# Check that covariance matrix is approximately equal to truth
c = cov([x1,x2,x3,x4])
cobj = OnlineStats.cov(obj)
for i in 1:10
    for j in 1:i
        @test_approx_eq_eps(c[i,j], cobj[i,j], 1e-10)
    end
end

# build matrix
obj1 = OnlineStats.CovarianceMatrix(x1)
obj2 = OnlineStats.CovarianceMatrix(x2)
obj3 = OnlineStats.CovarianceMatrix(x3)
obj4 = OnlineStats.CovarianceMatrix(x4)

# merge and merge!
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

for i in 1:10
    @test_approx_eq obj1.B[i] obj.B[i]
    @test_approx_eq obj5.B[i] obj.B[i]
    for j in 1:i
       @test_approx_eq obj5.A[i, j] obj.A[i, j]
    end
end

@test obj5.n == obj.n

# Remove large matrices
x1 = x2 = x3 = x4 = 0;

