using OnlineStats
using Base.Test
using Distributions
using PDMats
println("densityestimation_test.jl")

#------------------------------------------------------------------------------#
#                                                                    Bernoulli #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
p = rand(1)[1]
x1 = rand(Bernoulli(p), n1)
x2 = rand(Bernoulli(p), n2)
x = [x1, x2]

obj = OnlineStats.onlinefit(Bernoulli, x1)
@test obj.d.p == mean(x1)
@test obj.n1 == sum(x1)
@test obj.n == n1
@test obj.nb == 1

OnlineStats.update!(obj, x2)
@test obj.d.p == mean(x)
@test obj.n1 == sum([x1; x2])
@test obj.n == n1 + n2
@test obj.nb == 2

# clean up
x1, x2, x = zeros(3)



#------------------------------------------------------------------------------#
#                                                                         Beta #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
α, β = rand(1:0.1:10, 2)
x1 = rand(Beta(α, β), n1)
x2 = rand(Beta(α, β), n2)
x = [x1, x2]

obj = onlinefit(Beta, x1)
@test mean(obj.d) == mean(x1)
@test_approx_eq var(obj.d) var(x1)
@test obj.n == n1
@test obj.nb == 1

OnlineStats.update!(obj, x2)
@test_approx_eq mean(obj.d) mean(x)
@test_approx_eq var(obj.d) var(x)
@test obj.n == n1 + n2
@test obj.nb == 2

# clean up
x1, x2, x = zeros(3)



#------------------------------------------------------------------------------#
#                                                                     Binomial #
#------------------------------------------------------------------------------#
# n1 = rand(1:1_000_000, 1)[1]
# n2 = rand(1:1_000_000, 1)[1]
# n = rand(1:1000, 1)[1]
# p = rand(1)[1]
# x1 = rand(Binomial(n, p), n1)
# x2 = rand(Binomial(n, p), n2)
# x = [x1, x2]

# obj = onlinefit(Binomial, n, x1)
# @test obj.d.n == n
# @test obj.d.p == sum(x1) / (n * n1)
# @test obj.stats.ns == sum(x1)
# @test obj.stats.ne == n1
# @test obj.n == n1
# @test obj.nb == 1

# OnlineStats.update!(obj, x2)
# @test obj.d.n == n
# @test obj.d.p == sum(x) / (n * (n1 + n2))
# @test obj.stats.ns == sum(x)
# @test obj.stats.ne == n1 + n2
# @test obj.n == n1 + n2
# @test obj.nb == 2

# # clean up
# x1, x2, x = zeros(3)


#------------------------------------------------------------------------------#
#                                                                  Exponential #
#------------------------------------------------------------------------------#
# n1 = rand(1:1_000_000, 1)[1]
# n2 = rand(1:1_000_000, 1)[1]
# θ = rand(1:1000, 1)[1]
# x1 = rand(Exponential(θ), n1)
# x2 = rand(Exponential(θ), n2)
# x = [x1, x2]

# obj = onlinefit(Exponential, x1)
# @test obj.d.β == mean(x1)
# @test obj.stats.sx == sum(x1)
# @test obj.stats.sw == n1
# @test obj.n == n1
# @test obj.nb == 1

# OnlineStats.update!(obj, x2)
# @test_approx_eq  obj.d.β  mean(x)
# @test_approx_eq  obj.stats.sx  sum(x)
# @test obj.stats.sw == n1 + n2
# @test obj.n == n1 + n2
# @test obj.nb == 2

# # clean up
# x1, x2, x = zeros(3)



#------------------------------------------------------------------------------#
#                                                                        Gamma #
#------------------------------------------------------------------------------#
# n1 = rand(1:1_000_000, 1)[1]
# n2 = rand(1:1_000_000, 1)[1]
# α, β = rand(1:0.1:100, 2)
# x1 = rand(Gamma(α, β), n1)
# x2 = rand(Gamma(α, β), n2)
# x = [x1, x2]

# obj = onlinefit(Gamma, x1)
# @test_approx_eq  obj.stats.sx  sum(x1)
# @test_approx_eq  obj.stats.slogx  sum(log(x1))
# @test obj.stats.tw == n1
# @test obj.n == n1
# @test obj.nb == 1

# OnlineStats.update!(obj, x2)
# @test_approx_eq  obj.stats.sx  sum(x)
# @test_approx_eq  obj.stats.slogx  sum(log(x))
# @test obj.stats.tw == n1 + n2
# @test obj.n == n1 + n2
# @test obj.nb == 2

# # clean up
# x1, x2, x = zeros(3)



#------------------------------------------------------------------------------#
#                                                                  Multinomial #
#------------------------------------------------------------------------------#
# n1 = rand(1:1_000_000, 1)[1]
# n2 = rand(1:1_000_000, 1)[1]
# n = rand(1:100, 1)[1]
# ncat = rand(1:20, 1)[1]
# p = rand(ncat)
# p /= sum(p)
# x1 = rand(Multinomial(n, p), n1)
# x2 = rand(Multinomial(n, p), n2)
# x = [x1 x2]

# obj = onlinefit(Multinomial, x1)
# @test obj.d.n == n
# @test_approx_eq  obj.d.p  sum(x1, 2) / (n * n1)
# @test  obj.stats.n == n
# @test obj.stats.scnts == vec(sum(x1, 2))
# @test obj.stats.tw == n1
# @test obj.n == n1
# @test obj.nb == 1


# OnlineStats.update!(obj, x2)
# @test obj.d.n == n
# @test_approx_eq  obj.d.p  sum(x, 2) / (n * (n1 + n2))
# @test  obj.stats.n == n
# @test obj.stats.scnts == vec(sum(x, 2))
# @test obj.stats.tw == n1 + n2
# @test obj.n == n1 + n2
# @test obj.nb == 2

# # clean up
# x1, x2, x = zeros(3)



#------------------------------------------------------------------------------#
#                                                                     MvNormal #
#------------------------------------------------------------------------------#

# n1 = rand(1:1_000_000, 1)[1]
# n2 = rand(1:1_000_000, 1)[1]
# d = rand(1:10, 1)[1]
# x1 = rand(MvNormal(zeros(d), PDMat(eye(d))), n1)
# x2 = rand(MvNormal(zeros(d), PDMat(eye(d))), n2)
# x = [x1  x2]

# obj = onlinefit(MvNormal, x1)
# @test_approx_eq  obj.d.μ  vec(mean(x1, 2))
# @test_approx_eq  obj.d.Σ.mat  PDMat(cov(x1') * (n1 - 1) / n1).mat
# @test obj.n == n1
# @test obj.nb == 1

# OnlineStats.update!(obj, x2)
# @test_approx_eq  obj.d.μ  vec(mean(x, 2))
# @test_approx_eq  obj.d.Σ.mat  PDMat(cov(x') * (n1 + n2 - 1) / (n1 + n2)).mat
# @test obj.n == n1 + n2
# @test obj.nb == 2

# # clean up
# x1, x2, x = zeros(3)



#------------------------------------------------------------------------------#
#                                                                       Normal #
#------------------------------------------------------------------------------#

# n1 = rand(1:1_000_000, 1)[1]
# n2 = rand(1:1_000_000, 1)[1]
# x1 = randn(n1)
# x2 = randn(n2)
# x = [x1, x2]

# obj = onlinefit(Normal, x1)
# @test_approx_eq(obj.stats.m, mean(x1))
# @test_approx_eq(obj.d.μ, mean(x1))
# @test obj.n == n1
# @test obj.nb == 1

# update!(obj, x2)
# @test_approx_eq(obj.stats.m, mean(x))
# @test_approx_eq(obj.d.μ, mean(x))
# @test obj.n == n1 + n2
# @test obj.nb == 2

# # clean up
# x1, x2, x = zeros(3)
