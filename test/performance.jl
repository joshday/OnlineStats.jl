module Performance
using OnlineStats
import OnlineStats
O = OnlineStats

title(s) = print_with_color(:red, @sprintf( "%26s", s * " :"))

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


println("")
println("")
print_with_color(:blue, "  ===========================================\n")
print_with_color(:blue, "  Performance on 1 million × 5 design matrix\n")
print_with_color(:blue, "  ===========================================\n\n")

x = randn(1_000_000, 5)
β = collect(1.:5)
y = x * β + randn(1_000_000)

title("LinReg new")
@time LinReg(x, y)
title("LinReg old")
@time O.LinReg(x, y)
title("SparseReg old")
@time O.SparseReg(x, y)
println("")

title("StochasticModel new")
@time StatLearn(x, y)
title("StochasticModel old")
@time O.StochasticModel(x, y)




# cleanup
y = 0
println("")
end # module
