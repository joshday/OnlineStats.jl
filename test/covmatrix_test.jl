using OnlineStats
using Base.Test

# Generate Data
n1, n2, n3, n4 = rand(1:1_000_000, 4)
x1 = rand(n1, 10)
x2 = rand(n2, 10)
x3 = rand(n3, 10)
x4 = rand(n4, 10)

# Create update with 4 batches
obj = OnlineStats.CovarianceMatrix(x1)
OnlineStats.update!(obj, x2)
OnlineStats.update!(obj, x3)
OnlineStats.update!(obj, x4)

# Test that the covariance matrix is correct after 4 batches
for i in 1:10
    for j in 1:i
        @test_approx_eq_eps(cov([x1,x2,x3,x4])[i,j],
                            OnlineStats.state(obj)[i,j],
                            1e-10)
    end
end

# Remove large matrices
x1, x2, x3, x4 = zeros(4)

