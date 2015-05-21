module AnalyticalPCATest

using OnlineStats
using FactCheck
using MultivariateStats

facts("AnalyticalPCA") do
    x1 = rand(1000, 400)
    x2 = rand(1000, 400)
    x3 = rand(1000, 400)

    pca = pcacov(cor(x1), vec(mean(x1, 1)))
    o = AnalyticalPCA(x1)

    @fact o.vectors[:, end] => roughly(pca.proj[:, 1])
    @fact o.vectors[:, end - 1] => roughly(pca.proj[:, 2])
    @fact o.vectors[:, end - 2] => roughly(pca.proj[:, 3])

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
end

end # module
