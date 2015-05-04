module CovarianceMatrixTest

using OnlineStats
using FactCheck

facts("CovarianceMatrix") do

    # create 4 batches
    n1, n2, n3, n4 = rand(1:1_000_000, 4)
    x1 = rand(n1, 10)
    x2 = rand(n2, 10)
    x3 = rand(n3, 10)
    x4 = rand(n4, 10)

    # updatebatch!
    obj = OnlineStats.CovarianceMatrix(x1)
    @fact statenames(obj) => [:μ, :Σ, :nobs]
    @fact state(obj) => Any[mean(obj), cov(obj), nobs(obj)]
    OnlineStats.updatebatch!(obj, x2)
    OnlineStats.updatebatch!(obj, x3)
    OnlineStats.updatebatch!(obj, x4)

    # Check that covariance matrix is approximately equal to truth
    c = cov([x1,x2,x3,x4])
    cobj = OnlineStats.cov(obj)
    @fact c => roughly(cobj, 1e-10)
end

end # module
