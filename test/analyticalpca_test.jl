module AnalyticalPCATest

using OnlineStats
using FactCheck
using MultivariateStats

facts("AnalyticalPCA") do
    o = AnalyticalPCA(4)

    x1 = rand(1000, 400)
    x2 = rand(1000, 400)
    x3 = rand(1000, 400)

    pca = pcacov(cor(x1), vec(mean(x1, 1)))
    o = AnalyticalPCA(x1)

    # Sometimes vectors are different in sign from pca.  Not sure why this happens.
    # More likely an issue with pcacov() than with eig().
    @fact abs(o.vectors[:, end]) => roughly(abs(pca.proj[:, 1]), 1e-5)
    @fact abs(o.vectors[:, end - 1]) => roughly(abs(pca.proj[:, 2]), 1e-5)
    @fact abs(o.vectors[:, end - 2]) => roughly(abs(pca.proj[:, 3]), 1e-5)

    updatebatch!(o, x2)
    updatebatch!(o, x3)

    pca = pcacov(cor([x1, x2, x3]), vec(mean([x1, x2, x3], 1)))

    # Check top 100 eigenvectors
    for i in 0:99
        @fact abs(o.vectors[:, end - i]) => roughly(abs(pca.proj[:, i + 1]))
    end

    # Check top 100 eigenvalues
    for i in 0:99
        @fact abs(o.values[end - i]) => roughly(abs(pca.prinvars[i + 1]))
    end

    @fact statenames(o) => [:v, :λ, :nobs]
    @fact state(o)[1] => o.vectors
    @fact state(o)[2] => o.values
    @fact state(o)[3] => nobs(o)
end

end # module
