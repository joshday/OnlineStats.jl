module Performance
using OnlineStats, Distributions
import DeprecatedOnlineStats
O = DeprecatedOnlineStats

title(s) = print_with_color(:red, @sprintf( "%26s", s * " :"))

#
# print_with_color(:blue, "  =======================================\n")
# print_with_color(:blue, "  Performance on Distributions\n")
# print_with_color(:blue, "  =======================================\n\n")
#
# y = rand(Beta(3,4), 1_000_000)
# title("Beta (new)")
# @time FitDistribution(Beta, y)
# title("Beta (old)")
# @time O.FitBeta(y)
# println("")
#
# y = rand(Bernoulli(.5), 1_000_000)
# title("Bernoulli (new)")
# @time FitDistribution(Bernoulli, y)
# title("Bernoulli (old)")
# @time O.FitBernoulli(y)
# println("")
#
# y = rand(Exponential(4), 1_000_000)
# title("Exponential (new)")
# @time FitDistribution(Exponential, y)
# title("Exponential (old)")
# @time O.FitExponential(y)
# println("")
#
# y = rand(Poisson(4), 1_000_000)
# title("Poisson (new)")
# @time FitDistribution(Poisson, y)
# title("Poisson (old)")
# @time O.distributionfit(Poisson, y)
# println("")
#
# y = rand(Categorical(4), 1_000_000)
# title("Categorical (new)")
# @time FitDistribution(Categorical, y)
# title("Categorical (old)")
# println("  Categorical not supported")
# println("")
#
# y = rand(Cauchy(), 1_000_000)
# title("Cauchy (new)")
# @time FitDistribution(Cauchy, y)
# title("Cauchy (old)")
# @time O.distributionfit(Cauchy, y)
# println("")
#
# y = rand(Gamma(5, 1), 1_000_000)
# title("Gamma (new)")
# @time FitDistribution(Gamma, y)
# title("Gamma (old)")
# @time O.distributionfit(Gamma, y)
# println("")
#
# y = rand(LogNormal(), 1_000_000)
# title("LogNormal (new)")
# @time FitDistribution(LogNormal, y)
# title("LogNormal (old)")
# @time O.distributionfit(LogNormal, y)
# println("")
#
# y = rand(Normal(), 1_000_000)
# title("Normal (new)")
# @time FitDistribution(Normal, y)
# title("Normal (old)")
# @time O.distributionfit(Normal, y)
# println("")
#
# y = rand(MvNormal(zeros(50), eye(50)), 100_000)'
# title("MvNormal (new)")
# @time FitMvDistribution(MvNormal, y)
# title("MvNormal (old)")
# @time O.distributionfit(MvNormal, y)
# println("")
#
# y = rand(Multinomial(10, 4), 100_000)'
# title("Multinomial (new)")
# @time FitMvDistribution(Multinomial, y)
# title("Multinomial (old)")
# @time O.distributionfit(Multinomial, y)
# println("")



y = randn(10_000_000)
println("")
print_with_color(:blue, "  =======================================\n")
print_with_color(:blue, "  Performance on 10 million observations\n")
print_with_color(:blue, "  =======================================\n\n")

title("Mean new")
@time Mean(y)
title("Mean old")
@time O.Mean(y)
println("")

title("Mean (batch) new")
o = Mean()
@time fit!(o, y, length(y))
title("Mean (batch) old")
o = O.Mean()
@time O.update!(o, y, length(y))
println("")

title("Variance new")
@time Variance(y)
title("Variance old")
@time O.Variance(y)
println("")

title("Extrema new")
o = Extrema()
@time fit!(o, y)
title("Extrema old")
o = O.Extrema()
@time O.update!(o, y)
println("")

title("QuantileSGD new")
@time QuantileSGD(y, LearningRate(.6))
title("QuantileSGD old")
@time O.QuantileSGD(y, O.LearningRate(r = .6))
println("")

title("QuantileMM new")
@time QuantileMM(y, LearningRate(.6))
title("QuantileMM old")
@time O.QuantileMM(y, O.LearningRate(r = .6))
println("")

title("Moments new")
@time Moments(y)
title("Moments old")
@time O.Moments(y)




println("")
println("")
print_with_color(:blue, "  ============================================\n")
print_with_color(:blue, "  Performance on .2 million × 500 observations\n")
print_with_color(:blue, "  ============================================\n\n")

n, p = 200_000, 100
y = randn(n, p)


title("Means new")
@time Means(y)
title("Means old (SLOW)")
println("")
println("")

title("Means (batch) new")
o = Means(p)
@time fit!(o, y, size(y, 1))
title("Means (batch) old")
o = O.Means(p)
@time O.update!(o, y, size(y, 1))
println("")

title("Variances new")
@time Variances(y)
title("Variances old (SLOW)")
println("")
println("")

title("Variances (batch) new")
o = Variances(p)
@time fit!(o, y, size(y,1))
title("Variances (batch) old")
o = O.Variances(p)
@time O.update!(o, y, size(y,1))
println("")

title("CovMatrix new")
o = CovMatrix(p)
@time fit!(o, y)
title("CovMatrix old (SLOW)")
println("")
println("")

title("CovMatrix (batch) new")
@time CovMatrix(y)
title("CovMatrix (batch) old")
@time O.CovarianceMatrix(y)
println("")


# println("")
# println("")
# print_with_color(:blue, "  ===========================================\n")
# print_with_color(:blue, "  Performance on 1 million × 20 design matrix\n")
# print_with_color(:blue, "  ===========================================\n\n")
#
# x = randn(1_000_000, 20)
# β = collect(1.:20)
# y = x * β + randn(1_000_000)
#
# title("LinReg new")
# @time LinReg(x, y)
# title("LinReg old")
# @time O.LinReg(x, y)
# title("SparseReg old")
# @time O.SparseReg(x, y)
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
