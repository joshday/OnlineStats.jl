module CovarianceMatrixTest

using FactCheck, StatsBase
import OnlineStats

facts("CovarianceMatrix") do
    o = OnlineStats.CovarianceMatrix(10)
    for i in 1:10
        OnlineStats.CovarianceMatrix(randn(100, 5))
    end
    o = OnlineStats.CovarianceMatrix(randn(1000, 50))
    @fact nobs(o) => 1000

    context("update! vs. updatebatch!") do
        o1 = OnlineStats.CovarianceMatrix(10)
        o2 = OnlineStats.CovarianceMatrix(10)
        x = randn(1000,10)
        OnlineStats.update!(o1, x)
        OnlineStats.updatebatch!(o2, x)
        @fact cov(o1) - cov(o2) => roughly(zeros(10,10), 1e-8)
    end

    # create 4 batches
    n1, n2, n3, n4 = rand(1:1_000_000, 4)
    x1 = rand(n1, 10)
    x2 = rand(n2, 10)
    x3 = rand(n3, 10)
    x4 = rand(n4, 10)
    OnlineStats.CovarianceMatrix(x1)

    # updatebatch!
    obj = OnlineStats.CovarianceMatrix(x1)
    @fact OnlineStats.statenames(obj) => [:μ, :Σ, :nobs]
    @fact OnlineStats.state(obj) => Any[mean(obj), cov(obj), nobs(obj)]
    OnlineStats.updatebatch!(obj, x2)
    OnlineStats.updatebatch!(obj, x3)
    OnlineStats.updatebatch!(obj, x4)

    # Check that covariance matrix is approximately equal to truth
    c = cov([x1,x2,x3,x4])
    cobj = OnlineStats.cov(obj)
    @fact c => roughly(cobj, 1e-10)
    @fact var(obj) - vec(var([x1, x2, x3, x4], 1)) => roughly(zeros(10), 1e-10)
    @fact std(obj) - vec(std([x1, x2, x3, x4], 1)) => roughly(zeros(10), 1e-10)

    o1 = OnlineStats.CovarianceMatrix(x1)
    o2 = OnlineStats.CovarianceMatrix(x2)
    o3 = merge(o1, o2)
    merge!(o1, o2)
    @fact cov(o1) => cov(o3)
    @fact cor(o1) => cor(o3)
    OnlineStats.update!(o1, x1[1, :])
    OnlineStats.update!(o3, vec(x1[1, :]))
    @fact cor(o1) - cor(o3) => roughly(zeros(10, 10))

    context("PCA") do
        n = rand(1000:10_000)
        d = rand(10:100)
        x = randn(100, d)
        o = OnlineStats.CovarianceMatrix(x)

        # full PCA - correlation
        @fact abs(OnlineStats.pca(o)[1] - eig(cor(x))[1]) => roughly(zeros(d), .0001)
        @fact abs(OnlineStats.pca(o)[1] - eig(Symmetric(cor(o)))[1]) => roughly(zeros(d), .0001)
        @fact abs(OnlineStats.pca(o)[2]) - abs(eig(cor(x))[2]) => roughly(zeros(d, d), .0001)
        @fact abs(OnlineStats.pca(o)[2] - eig(Symmetric(cor(o)))[2]) => roughly(zeros(d, d), .0001)

        # full PCA - covariance
        OnlineStats.pca(o, length(o.B), false)

        # top d PCA - correlation
        OnlineStats.pca(o, 4)

        # top d PCA - covariance
        OnlineStats.pca(o, 4, false)

    end
end

end # module
