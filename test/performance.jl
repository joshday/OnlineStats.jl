# The Performance module uses Benchmark.jl to benchmark many of the main functions
# in OnlineStats.jl.

module Performance
using OnlineStats, Distributions, Benchmark
import DeprecatedOnlineStats
O = DeprecatedOnlineStats

title(s) = print_with_color(:red, @sprintf( "%26s", s * " :\n"))





function comparison(title, n::AbstractString, o::AbstractString, nrep = 10)
    old_behavior() = eval(parse(o))
    new_behavior() = eval(parse(n))
    print_with_color(:red, "▶ " * title * ":\n")
    display(compare([new_behavior, old_behavior], nrep))
end


print_with_color(:blue, "  =============================================\n")
print_with_color(:blue, "  Univariate Distributions, 1 million obs.\n")
print_with_color(:blue, "  =============================================\n\n")


n = 1_000_000
y = rand(Beta(3, 4), n)
comparison("Beta", "FitDistribution(Beta, y)", "O.FitBeta(y)")

y = rand(Bernoulli(.5), n)
comparison("Bernoulli", "FitDistribution(Bernoulli, y)", "O.FitBernoulli(y)")

y = rand(Exponential(4), n)
comparison("Exponential", "FitDistribution(Exponential, y)", "O.FitExponential(y)")

y = rand(Poisson(4), n)
comparison("Poisson", "FitDistribution(Poisson, y)", "O.distributionfit(Poisson, y)")

y = rand(Cauchy(), n)
comparison("Cauchy", "FitDistribution(Cauchy, y)", "O.distributionfit(Cauchy, y)")

y = rand(Gamma(), n)
comparison("Gamma", "FitDistribution(Gamma, y)", "O.distributionfit(Gamma, y)")

y = rand(LogNormal(), n)
comparison("LogNormal", "FitDistribution(LogNormal, y)", "O.distributionfit(LogNormal, y)")

y = rand(Normal(), n)
comparison("Normal", "FitDistribution(Normal, y)", "O.distributionfit(Normal, y)")



println(); println()
print_with_color(:blue, "  =============================================\n")
print_with_color(:blue, "  Multivariate Distributions \n")
print_with_color(:blue, "  =============================================\n\n")

y = rand(MvNormal(zeros(10), eye(10)), 1_000_000)'
comparison("MvNormal",
    "o = FitMvDistribution(MvNormal, 10); fit!(o, y, 1_000_000)",
    "o = O.FitMvNormal(10); O.update!(o, y, 100_000)"
)

y = rand(Multinomial(20, 10), 1_000_000)'
comparison("Multinomial",
    "FitMvDistribution(Multinomial, y)",
    "O.distributionfit(Multinomial, y)"
)



y = randn(10_000_000)
println("")
print_with_color(:blue, "  ========================================\n")
print_with_color(:blue, "  Performance on 10 million observations\n")
print_with_color(:blue, "  ========================================\n\n")

comparison("Mean", "Mean(y)", "O.Mean(y)")
comparison("Mean",
    "(o = Mean(); fit!(o, y, length(y)))",
    "(o = O.Mean(); O.updatebatch!(o, y))"
)
comparison("Variance", "Variance(y)", "O.Variance(y)")
comparison("Extrema", "Extrema(y)", "O.Extrema(y)")
comparison("QuantileSGD", "QuantileSGD(y)", "O.QuantileSGD(y)")
comparison("QuantileMM", "QuantileMM(y)", "O.QuantileMM(y)")
comparison("Moments", "Moments(y)", "O.Moments(y)")


println("")
println("")
print_with_color(:blue, "  ============================================\n")
print_with_color(:blue, "  Performance on 1 million × 400 observations\n")
print_with_color(:blue, "  ============================================\n\n")

n, p = 1_000_000, 400
y = randn(n, p)

# comparison("Means", "Means(y)", "O.Means(y)")
comparison("Means batch",
    "(o = Means(p); fit!(o, y, size(y, 1)))",
    "(o = O.Means(p); O.updatebatch!(o, y))"
)
# comparison("Variances", "Variances(y)", "O.Variances(y)")
comparison("Variances batch",
    "(o = Variances(p); fit!(o, y, size(y, 1)))",
    "(o = O.Variances(p); O.updatebatch!(o, y))"
)
comparison("CovMatrix batch",
    "(o = CovMatrix(p); fit!(o, y, size(y, 1))); cor(o)",
    "(o = O.CovarianceMatrix(p); O.updatebatch!(o, y)); cor(o)"
)



println("")
println("")
print_with_color(:blue, "  ===========================================\n")
print_with_color(:blue, "  Performance on 1 million × 200 design matrix\n")
print_with_color(:blue, "  ===========================================\n\n")

n, p = 1_000_000, 200
x = randn(n, p)
β = collect(1.:p)
y = x * β + randn(n)

comparison("LinReg vs. LinReg",
    "(o = LinReg(x, y); coef(o))",
    "(o = O.LinReg(x, y); coef(o))"
)
comparison("LinReg vs. SparseReg",
    "(o = LinReg(x, y); coef(o))",
    "(o = O.SparseReg(x, y); coef(o))"
)
comparison("SGD", "StatLearn(x, y)", "O.StochasticModel(x, y)")
comparison("AdaGrad", "StatLearn(x, y, AdaGrad())", "O.StochasticModel(x, y, algorithm = O.ProxGrad())")
comparison("RDA", "StatLearn(x, y, algorithm = RDA())", "O.StochasticModel(x, y, algorithm = O.RDA())")
comparison("MMGrad", "StatLearn(x, y, algorithm = MMGrad())", "O.StochasticModel(x, y, algorithm = O.MMGrad())")


# cleanup
y = 0
println("")
end # module
