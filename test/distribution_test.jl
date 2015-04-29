module DistributionTest

using OnlineStats
using Base.Test
using Distributions, PDMats, DataFrames
println("* densityestimation_test.jl")

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
@test_approx_eq(obj.d.p, mean(x1))
@test obj.n == n1

OnlineStats.update!(obj, x2)
@test_approx_eq(obj.d.p, mean(x))
@test obj.n == n1 + n2

@test state(obj) == [obj.d.p, obj.n]
@test statenames(obj) == [:p, :nobs]
@test typeof(DataFrame(obj)) == DataFrame
obj2 = copy(obj)
@test DataFrame(obj2) == DataFrame(p = obj.d.p, nobs = n1 + n2)
@test_approx_eq(mean(obj2.d), mean(x))
@test nobs(obj) == n1 + n2

obj = onlinefit(Bernoulli, x1, ExponentialWeighting(.01))
@test weighting(obj) == ExponentialWeighting(.01)

obj = onlinefit(Bernoulli, x1, ExponentialWeighting(1000))
@test weighting(obj) == ExponentialWeighting(1000)

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
@test_approx_eq_eps mean(obj.d) mean(x1) 1e-10
@test_approx_eq_eps var(obj.d) var(x1) 1e-10
@test obj.n == n1

OnlineStats.update!(obj, x2)
@test_approx_eq mean(obj.d) mean(x)
@test_approx_eq var(obj.d) var(x)
@test obj.n == n1 + n2
@test statenames(obj) == [:α, :β, :nobs]
@test state(obj) == [obj.d.α, obj.d.β, obj.n]
obj2 = copy(obj)
@test DataFrame(obj2) == DataFrame(obj)



#------------------------------------------------------------------------------#
#                                                                     Binomial #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
ntrials = rand(1:1000, 1)[1]
p = rand(1)[1]
x1 = rand(Binomial(ntrials, p), n1)
x2 = rand(Binomial(ntrials, p), n2)
x = [x1, x2]

obj = onlinefit(Binomial, x1, n = ntrials)
@test obj.d.n == ntrials
@test_approx_eq(obj.d.p, sum(x1) / (ntrials * n1))
@test obj.n == n1

OnlineStats.update!(obj, x2)
@test obj.d.n == ntrials
@test_approx_eq(obj.d.p, sum(x) / (ntrials * (n1 + n2)))
@test obj.n == n1 + n2

@test state(obj) == [obj.d.n, obj.d.p, obj.n]
obj2 = copy(obj)
@test statenames(obj2) == [:n, :p, :nobs]
@test DataFrame(obj2) == DataFrame(n = obj.d.n, p = obj.d.p, nobs = obj.n)




#------------------------------------------------------------------------------#
#                                                                    Dirichlet #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
αlength = rand(3:20, 1)[1]
α = rand(.5:.1:20, αlength)
x1 = rand(Dirichlet(α), n1)
x2 = rand(Dirichlet(α), n2)
x = [x1 x2]

obj = onlinefit(Dirichlet, x1)
@test obj.meanlogx == vec(mean(log(x1), 2))
@test obj.n == n1

update!(obj, x2)
@test length(obj.d.alpha) == αlength

# Okay if this fails, fit(Dirichlet, x) sometimes gives strange results
@test_approx_eq obj.d.alpha fit(Dirichlet, x).alpha
@test obj.n == n1 + n2

@test state(obj) == [obj.d.alpha; nobs(obj)]
@test statenames(obj) == [[symbol("α$i") for i in 1:αlength]; :nobs]
obj2 = copy(obj)
@test state(obj2) == state(obj)
@test names(DataFrame(obj)) == statenames(obj)
@test DataFrame(obj)[1, end] == nobs(obj)


#------------------------------------------------------------------------------#
#                                                                  Exponential #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
θ = rand(1:1000, 1)[1]
x1 = rand(Exponential(θ), n1)
x2 = rand(Exponential(θ), n2)
x = [x1, x2]

obj = onlinefit(Exponential, x1)
@test_approx_eq(obj.d.β, mean(x1))
@test obj.n == n1
@test nobs(obj) == n1

OnlineStats.update!(obj, x2)
@test_approx_eq  obj.d.β mean(x)
@test obj.n == n1 + n2

obj1 = copy(obj)
@test state(obj) == [obj.d.β, obj.n]
@test statenames(obj) == [:β, :nobs]
@test state(obj1) == state(obj)
@test DataFrame(obj) == DataFrame(β = obj.d.β, nobs = obj.n)



#------------------------------------------------------------------------------#
#                                                                        Gamma #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
α, β = rand(1:0.1:100, 2)
x1 = rand(Gamma(α, β), n1)
x2 = rand(Gamma(α, β), n2)
x = [x1, x2]

obj = onlinefit(Gamma, x1)
@test_approx_eq(mean(obj.m), mean(x1))
@test_approx_eq(mean(obj.mlog), mean(log(x1)))
@test obj.n == n1

OnlineStats.update!(obj, x2)
@test state(obj) == [obj.d.α, obj.d.β, obj.n]
@test statenames(obj) == [:α, :β, :nobs]
@test_approx_eq_eps mean(obj.m) mean(x) 1e-6
@test_approx_eq_eps mean(obj.mlog) mean(log(x))  1e-6
@test obj.n == n1 + n2

obj1 = copy(obj)
@test state(obj1) == state(obj)
@test obj.n == n1 + n2


#------------------------------------------------------------------------------#
#                                                                  Multinomial #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
n = rand(1:100, 1)[1]
ncat = rand(1:20, 1)[1]
p = rand(ncat)
p /= sum(p)
x1 = rand(Multinomial(n, p), n1)
x2 = rand(Multinomial(n, p), n2)
x = [x1 x2]

obj = onlinefit(Multinomial, x1)
@test obj.d.n == n
@test_approx_eq  obj.d.p  sum(x1, 2) / (n * n1)
@test obj.d.n == Multinomial(n, vec(sum(x1, 2) / (n * n1))).n
@test_approx_eq obj.d.p Multinomial(n, vec(sum(x1, 2) / (n * n1))).p
@test obj.n == n1
@test nobs(obj) == n1


OnlineStats.update!(obj, x2)
@test obj.d.n == n
@test_approx_eq  obj.d.p  sum(x, 2) / (n * (n1 + n2))
@test obj.d.n == Multinomial(n, vec(sum(x1, 2) / (n * n1))).n
@test_approx_eq obj.d.p Multinomial(n, vec(sum(x, 2) / (n * (n1 + n2)))).p
@test obj.n == n1 + n2

obj1 = copy(obj)
@test state(obj1) == state(obj)
# @test typeof(state(obj)) == DF.DataFrame
@test statenames(obj) == [:n; [symbol("p$i") for i in 1:ncat]; :nobs]
@test obj1.d.n == n
@test_approx_eq  obj1.d.p  sum(x, 2) / (n * (n1 + n2))
@test obj1.d.n == Multinomial(n, vec(sum(x1, 2) / (n * n1))).n
@test_approx_eq obj1.d.p Multinomial(n, vec(sum(x, 2) / (n * (n1 + n2)))).p
@test obj1.n == n1 + n2

@test names(DataFrame(obj)) == statenames(obj)


#------------------------------------------------------------------------------#
#                                                                     MvNormal #
#------------------------------------------------------------------------------#
# n1 = rand(1:1_000_000, 1)[1]
# n2 = rand(1:1_000_000, 1)[1]
# d = rand(1:10, 1)[1]
# x1 = rand(MvNormal(zeros(d), eye(d)), n1)
# x2 = rand(MvNormal(zeros(d), eye(d)), n2)
# x = [x1  x2]

# obj = onlinefit(MvNormal, x1)
# @test_approx_eq obj.d.μ  vec(mean(x1, 2))
# @test_approx_eq mean(obj.c) vec(mean(x1, 2))
# @test_approx_eq cov(obj.c)  cov(x1')
# @test_approx_eq_eps cov(obj.c) obj.d.Σ.mat 1e-4
# @test obj.n == n1

# OnlineStats.update!(obj, x2)
# @test_approx_eq  obj.d.μ  vec(mean(x, 2))
# @test_approx_eq mean(obj.c) vec(mean(x, 2))
# @test_approx_eq cov(obj.c) cov(x')
# @test obj.n == n1 + n2

# obj1 = copy(obj)
# @test_approx_eq  obj1.d.μ  vec(mean(x, 2))
# @test_approx_eq mean(obj1.c) vec(mean(x, 2))
# @test_approx_eq cov(obj1.c) cov(x')
# @test obj1.n == n1 + n2



#------------------------------------------------------------------------------#
#                                                                       Normal #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
x1 = randn(n1)
x2 = randn(n2)
x = [x1, x2]

obj = onlinefit(Normal, x1)
@test_approx_eq mean(obj.v) mean(x1)
@test_approx_eq mean(obj.d) mean(obj.v)
@test_approx_eq var(obj.v) var(x1)
@test obj.n == n1

update!(obj, x2)
@test_approx_eq obj.d.σ std(x)
@test_approx_eq obj.d.μ mean(x)
@test_approx_eq mean(obj.v) mean(x)
@test_approx_eq var(obj.v) var(x)
@test obj.n == n1 + n2

obj1 = copy(obj)
@test statenames(obj) == [:μ, :σ, :nobs]
@test state(obj) == [obj.d.μ, obj.d.σ, obj.n]
@test state(obj1) == state(obj)
@test_approx_eq obj1.d.σ std(x)
@test_approx_eq obj1.d.μ mean(x)
@test_approx_eq mean(obj1.v) mean(x)
@test_approx_eq var(obj1.v) var(x)
@test obj1.n == n1 + n2

end # module
