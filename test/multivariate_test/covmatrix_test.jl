module CovarianceMatrixTest

using OnlineStats, FactCheck, StatsBase, MultivariateStats


facts("CovarianceMatrix") do
    o = CovarianceMatrix(10)
    for i in 1:10
        CovarianceMatrix(randn(100, 5))
    end
    o = CovarianceMatrix(randn(1000, 50))
    @fact nobs(o) --> 1000

    context("update singletons vs batches") do
        o1 = CovarianceMatrix(10)
        o2 = CovarianceMatrix(10)
        x = randn(1000,10)
        update!(o1, x)
        update!(o2, x, b = 500)
        @fact cov(o1) - cov(o2) --> roughly(zeros(10,10), 1e-8)
    end

    # create 4 batches
    n1, n2, n3, n4 = fill(5000, 4)
    x1 = rand(n1, 10)
    x2 = rand(n2, 10)
    x3 = rand(n3, 10)
    x4 = rand(n4, 10)
    CovarianceMatrix(x1)

    # update with batches
    o = CovarianceMatrix(x1)
    @fact statenames(o) --> [:μ, :Σ, :nobs]
    @fact state(o) --> Any[mean(o), cov(o), nobs(o)]
    update!(o, vcat(x2, x3, x4), b = 5000)

    # Check that covariance matrix is approximately equal to truth
    c = cov(vcat(x1,x2,x3,x4))
    covo = cov(o)
    @fact maxabs(c - covo) --> less_than(1e-10)
    @fact var(o) - vec(var(vcat(x1, x2, x3, x4), 1)) --> roughly(zeros(10), 1e-10)
    @fact std(o) - vec(std(vcat(x1, x2, x3, x4), 1)) --> roughly(zeros(10), 1e-10)

    o1 = CovarianceMatrix(x1)
    o2 = CovarianceMatrix(x2)
    o3 = merge(o1, o2)
    merge!(o1, o2)
    @fact cov(o1) --> cov(o3)
    @fact cor(o1) --> cor(o3)
    update!(o1, x1[1, :])
    update!(o3, vec(x1[1, :]))
    @fact cor(o1) - cor(o3) --> roughly(zeros(10, 10))

    context("PCA") do
        # This error sometimes occurs if maxoutdim = d
        # ERROR: ArgumentError("principal variance cannot exceed total variance.")
        n = rand(10_000)
        d = rand(10:100)
        x = randn(100, d)
        o = CovarianceMatrix(x)

        # full PCA - correlation
        oPCA = pca(o, maxoutdim = d-9)
        PCA = pcacov(cor(x), vec(mean(x, 1)), maxoutdim = d-9)
        @fact principalvars(oPCA) --> roughly(principalvars(PCA))
        @fact mean(oPCA) --> roughly(mean(PCA))
        @fact abs(projection(oPCA)) --> roughly(abs(projection(PCA)))

        # full PCA - covariance
        @fact typeof(pca(o, false, maxoutdim = d-2)) <: MultivariateStats.PCA --> true

        # top d PCA - correlation
        @fact typeof(pca(o, true, maxoutdim = 4)) <: MultivariateStats.PCA --> true

        # top d PCA - covariance
        @fact typeof(pca(o, false, maxoutdim = 4)) <: MultivariateStats.PCA --> true

    end
end

end # module
