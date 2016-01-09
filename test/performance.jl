# The Performance module uses Benchmark.jl to benchmark many of the main functions
# in OnlineStats.jl.

module Performance
using OnlineStats, Distributions, Benchmark
import DeprecatedOnlineStats
O = DeprecatedOnlineStats

title(s) = print_with_color(:red, @sprintf( "%26s", s * " :\n"))





function comparison(title, n::AbstractString, o::AbstractString, nrep = 20)
    old_behavior() = eval(parse(o))
    new_behavior() = eval(parse(n))
    print_with_color(:red, "▶ " * title * ":\n")
    compare([new_behavior, old_behavior], nrep)
end


print_with_color(:blue, "  =============================================\n")
print_with_color(:blue, "  Univariate Distributions, 1 million obs.\n")
print_with_color(:blue, "  =============================================\n\n")


n = 1_000_000
y = rand(Beta(3, 4), n)
display(comparison("Beta", "FitDistribution(Beta, y)", "O.FitBeta(y)"))

y = rand(Bernoulli(.5), n)
display(comparison("Bernoulli", "FitDistribution(Bernoulli, y)", "O.FitBernoulli(y)"))

y = rand(Exponential(4), n)
display(comparison("Exponential", "FitDistribution(Exponential, y)", "O.FitExponential(y)"))

y = rand(Poisson(4), n)
display(comparison("Poisson", "FitDistribution(Poisson, y)", "O.distributionfit(Poisson, y)"))

y = rand(Cauchy(), n)
display(comparison("Cauchy", "FitDistribution(Cauchy, y)", "O.distributionfit(Cauchy, y)"))

y = rand(Gamma(), n)
display(comparison("Gamma", "FitDistribution(Gamma, y)", "O.distributionfit(Gamma, y)"))

y = rand(LogNormal(), n)
display(comparison("LogNormal", "FitDistribution(LogNormal, y)", "O.distributionfit(LogNormal, y)"))

y = rand(Normal(), n)
display(comparison("Normal", "FitDistribution(Normal, y)", "O.distributionfit(Normal, y)"))



println(); println()
print_with_color(:blue, "  =============================================\n")
print_with_color(:blue, "  Multivariate Distributions \n")
print_with_color(:blue, "  =============================================\n\n")

y = rand(MvNormal(zeros(10), eye(10)), 100_000)'
display(comparison("MvNormal",
    "o = FitMvDistribution(MvNormal, 10); fit!(o, y, 100_000)",
    "o = O.FitMvNormal(10); O.update!(o, y, 100_000)"
))

y = rand(Multinomial(20, 10), 100_000)'
display(comparison("Multinomial",
    "FitMvDistribution(Multinomial, y)",
    "O.distributionfit(Multinomial, y)"
))



# y = rand(MvNormal(zeros(50), eye(50)), 1_000_000)'
# title("MvNormal (new)")
# @time (o = FitMvDistribution(MvNormal, 50); fit!(o, y))
# title("MvNormal (old)")
# @time o = O.distributionfit(MvNormal, y)
# println("")
#
# y = rand(Multinomial(10, 50), 1_000_000)'
# title("Multinomial (new)")
# @time (o = FitMvDistribution(Multinomial, 50); fit!(o, y))
# title("Multinomial (old)")
# @time o = O.distributionfit(Multinomial, y)
# println("")




#
# print_with_color(:blue, "  =============================================\n")
# print_with_color(:blue, "  Univariate Distributions, 10 million obs.\n")
# print_with_color(:blue, "  =============================================\n\n")
#
# y = rand(Beta(3,4), 10_000_000)
# title("Beta (new)")
# @time FitDistribution(Beta, y)
# title("Beta (old)")
# @time O.FitBeta(y)
# println("")
#
# y = rand(Bernoulli(.5), 10_000_000)
# title("Bernoulli (new)")
# @time FitDistribution(Bernoulli, y)
# title("Bernoulli (old)")
# @time O.FitBernoulli(y)
# println("")
#
# y = rand(Exponential(4), 10_000_000)
# title("Exponential (new)")
# @time FitDistribution(Exponential, y)
# title("Exponential (old)")
# @time O.FitExponential(y)
# println("")
#
# y = rand(Poisson(4), 10_000_000)
# title("Poisson (new)")
# @time FitDistribution(Poisson, y)
# title("Poisson (old)")
# @time O.distributionfit(Poisson, y)
# println("")
#
# y = rand(Categorical(4), 10_000_000)
# title("Categorical (new)")
# @time FitDistribution(Categorical, y)
# title("Categorical (old)")
# println("  Categorical not supported")
# println("")
#
# y = rand(Cauchy(), 10_000_000)
# title("Cauchy (new)")
# @time FitDistribution(Cauchy, y)
# title("Cauchy (old)")
# @time O.distributionfit(Cauchy, y)
# println("")
#
# y = rand(Gamma(5, 1), 10_000_000)
# title("Gamma (new)")
# @time FitDistribution(Gamma, y)
# title("Gamma (old)")
# @time O.distributionfit(Gamma, y)
# println("")
#
# y = rand(LogNormal(), 10_000_000)
# title("LogNormal (new)")
# @time FitDistribution(LogNormal, y)
# title("LogNormal (old)")
# @time O.distributionfit(LogNormal, y)
# println("")
#
# y = rand(Normal(), 10_000_000)
# title("Normal (new)")
# @time FitDistribution(Normal, y)
# title("Normal (old)")
# @time O.distributionfit(Normal, y)
# println("")
#
#
# print_with_color(:blue, "  =============================================\n")
# print_with_color(:blue, "  Multivariate Distributions, 1 million × 50 matrix \n")
# print_with_color(:blue, "  =============================================\n\n")
#
# y = rand(MvNormal(zeros(50), eye(50)), 1_000_000)'
# title("MvNormal (new)")
# @time (o = FitMvDistribution(MvNormal, 50); fit!(o, y))
# title("MvNormal (old)")
# @time o = O.distributionfit(MvNormal, y)
# println("")
#
# y = rand(Multinomial(10, 50), 1_000_000)'
# title("Multinomial (new)")
# @time (o = FitMvDistribution(Multinomial, 50); fit!(o, y))
# title("Multinomial (old)")
# @time o = O.distributionfit(Multinomial, y)
# println("")
#
#
#
# y = randn(100_000_000)
# println("")
# print_with_color(:blue, "  ========================================\n")
# print_with_color(:blue, "  Performance on 100 million observations\n")
# print_with_color(:blue, "  ========================================\n\n")
#
# title("Mean new")
# @time Mean(y)
# title("Mean old")
# @time O.Mean(y)
# println("")
#
# title("Mean (batch) new")
# o = Mean()
# @time fit!(o, y, length(y))
# title("Mean (batch) old")
# o = O.Mean()
# @time O.update!(o, y, length(y))
# println("")
#
# title("Variance new")
# @time Variance(y)
# title("Variance old")
# @time O.Variance(y)
# println("")
#
# title("Extrema new")
# o = Extrema()
# @time fit!(o, y)
# title("Extrema old")
# o = O.Extrema()
# @time O.update!(o, y)
# println("")
#
# title("QuantileSGD new")
# @time QuantileSGD(y, LearningRate(.6))
# title("QuantileSGD old")
# @time O.QuantileSGD(y, O.LearningRate(r = .6))
# println("")
#
# title("QuantileMM new")
# @time QuantileMM(y, LearningRate(.6))
# title("QuantileMM old")
# @time O.QuantileMM(y, O.LearningRate(r = .6))
# println("")
#
# title("Moments new")
# @time Moments(y)
# title("Moments old")
# @time O.Moments(y)
#
#
#
#
# println("")
# println("")
# print_with_color(:blue, "  ============================================\n")
# print_with_color(:blue, "  Performance on 1 million × 300 observations\n")
# print_with_color(:blue, "  ============================================\n\n")
#
# n, p = 1_000_000, 400
# y = randn(n, p)
#
#
# title("Means new")
# @time Means(y)
# title("Means old (SLOW)")
# println("")
# println("")
#
# title("Means (batch) new")
# o = Means(p)
# @time fit!(o, y, size(y, 1))
# title("Means (batch) old")
# o = O.Means(p)
# @time O.update!(o, y, size(y, 1))
# println("")
#
# title("Variances new")
# @time Variances(y)
# title("Variances old (SLOW)")
# println("")
# println("")
#
# title("Variances (batch) new")
# o = Variances(p)
# @time fit!(o, y, size(y,1))
# title("Variances (batch) old")
# o = O.Variances(p)
# @time O.update!(o, y, size(y,1))
# println("")
#
# title("CovMatrix new")
# o = CovMatrix(p)
# @time fit!(o, y)
# title("CovMatrix old (SLOW)")
# println("")
# println("")
#
# title("CovMatrix (batch) new")
# @time (o = CovMatrix(y); cor(o))
# title("CovMatrix (batch) old")
# @time (o = O.CovarianceMatrix(y); cor(o))
# println("")
#
#
# println("")
# println("")
# print_with_color(:blue, "  ===========================================\n")
# print_with_color(:blue, "  Performance on 1 million × 200 design matrix\n")
# print_with_color(:blue, "  ===========================================\n\n")
#
# n, p = 1_000_000, 200
# x = randn(n, p)
# β = collect(1.:p)
# y = x * β + randn(n)
#
# title("LinReg new")
# @time (o = LinReg(x, y); coef(o))
# title("LinReg old")
# @time (o = O.LinReg(x, y); coef(o))
# title("SparseReg old")
# @time (o = O.SparseReg(x, y); coef(o))
# println("")
#
# title("SGD new")
# @time StatLearn(x, y)
# title("SGD old")
# @time O.StochasticModel(x, y)
# println("")
#
# title("AdaGrad new")
# @time StatLearn(x, y, algorithm = AdaGrad())
# title("AdaGrad old")
# @time O.StochasticModel(x, y, algorithm = O.ProxGrad())
# println("")
#
# title("RDA new")
# @time StatLearn(x, y, algorithm = RDA())
# title("RDA old")
# @time O.StochasticModel(x, y, algorithm = O.RDA())
# println("")
#
# title("MMGrad new")
# @time StatLearn(x, y, algorithm = MMGrad())
# title("MMGrad old")
# @time O.StochasticModel(x, y, algorithm = O.MMGrad())
# println("")




# cleanup
y = 0
println("")
end # module
