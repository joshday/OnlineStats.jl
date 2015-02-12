using OnlineStats
using Base.Test
using Distributions
#------------------------------------------------------------------------------#
#                                                                       Normal #
#------------------------------------------------------------------------------#
srand(1234)
n1 = 246
n2 = 978
x1 = randn(n1)
x2 = randn(n2)
x = [x1, x2]

obj = OnlineStats.onlinefit(Distributions.Normal, x1)
@test_approx_eq(obj.stats.m, mean(x1))
@test_approx_eq(obj.d.μ, mean(x1))
@test obj.n == n1
@test obj.nb == 1

OnlineStats.update!(obj, x2)
@test_approx_eq(obj.stats.m, mean(x))
@test_approx_eq(obj.d.μ, mean(x))
@test obj.n == n1 + n2
@test obj.nb == 2


