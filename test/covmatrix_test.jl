module CovarianceMatrixTest

using OnlineStats
using FactCheck

facts("CovarianceMatrix") do
    CovarianceMatrix(10)
    CovarianceMatrix(rand(100,10))

    # create 4 batches
    n1, n2, n3, n4 = rand(1:1_000_000, 4)
    x1 = rand(n1, 10)
    x2 = rand(n2, 10)
    x3 = rand(n3, 10)
    x4 = rand(n4, 10)
    CovarianceMatrix(x1)

    # updatebatch!
    obj = CovarianceMatrix(x1)
    @fact statenames(obj) => [:μ, :Σ, :nobs]
    @fact state(obj) => Any[mean(obj), cov(obj), nobs(obj)]
    updatebatch!(obj, x2)
    updatebatch!(obj, x3)
    updatebatch!(obj, x4)

    # Check that covariance matrix is approximately equal to truth
    c = cov([x1,x2,x3,x4])
    cobj = OnlineStats.cov(obj)
    @fact c => roughly(cobj, 1e-10)
    @fact var(obj) - vec(var([x1, x2, x3, x4], 1)) => roughly(zeros(10), 1e-10)
    @fact std(obj) - vec(std([x1, x2, x3, x4], 1)) => roughly(zeros(10), 1e-10)

    o1 = CovarianceMatrix(x1)
    o2 = CovarianceMatrix(x2)
    o3 = merge(o1, o2)
    merge!(o1, o2)
    @fact cov(o1) => cov(o3)

end

end # module
