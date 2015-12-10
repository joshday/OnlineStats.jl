module Performance
using OnlineStats

givetitle(s) = print_with_color(:red, s * " :")
print_with_color(:blue, "================================================\n")
print_with_color(:blue, "Performance on 10 million random normal obs.\n")
print_with_color(:blue, "================================================\n")
y = randn(10_000_000)

givetitle("Mean")
@time Mean(y)

givetitle("Variance")
@time Variance(y)

givetitle("Moments")
@time Moments(y)

givetitle("Summary")
@time Summary(y)

givetitle("Extrema")
@time Extrema(y)

givetitle("QuantileSGD")
@time QuantileSGD(y)

givetitle("QuantileMM")
@time QuantileMM(y)

givetitle("FiveNumberSummary")
@time FiveNumberSummary(y)

givetitle("Diff")
@time Diff(y)


y = randn(10_000_000, 4)
givetitle("CovarianceMatrix")
@time CovarianceMatrix(y)


end # module
