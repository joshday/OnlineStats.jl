using OnlineStats
using Base.Test

# Generate Data
srand(18604)
x1 = rand(100, 10)
x2 = rand(201, 10)
x3 = rand(302, 10)
x4 = rand(403, 10)

# Create update with 4 batches
obj = OnlineStats.CovarianceMatrix(x1)
OnlineStats.update!(obj, x2)
OnlineStats.update!(obj, x3)
OnlineStats.update!(obj, x4)

# Test that the covariance matrix is correct after 4 batches
for i in 1:10
    for j in 1:i
        @test_approx_eq(cov([x1,x2,x3,x4])[i,j], OnlineStats.state(obj)[i,j])
    end
end

