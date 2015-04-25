using OnlineStats
using Base.Test
using Distributions, PDMats
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
@test obj.d.p == mean(x1)
@test obj.n1 == sum(x1)
@test obj.n == n1
@test obj.nb == 1

OnlineStats.update!(obj, x2)
@test obj.d.p == mean(x)
@test obj.n1 == sum([x1; x2])
@test obj.n == n1 + n2
@test obj.nb == 2

@test state(obj) == [[:p, :n, :nb] [mean(x), n1 + n2, 2]]
obj2 = copy(obj)
@test state(obj2) == [[:p, :n, :nb] [mean(x), n1 + n2, 2]]
@test mean(obj2) == mean(x)
@test nobs(obj) == n1 + n2



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
@test obj.nb == 1

OnlineStats.update!(obj, x2)
@test_approx_eq mean(obj.d) mean(x)
@test_approx_eq var(obj.d) var(x)
@test obj.n == n1 + n2
@test obj.nb == 2

@test state(obj) == [[:α, :β, :n, :nb] [obj.d.α, obj.d.β, n1+n2, 2]]
obj2 = copy(obj)
@test state(obj2) == [[:α, :β, :n, :nb] [obj.d.α, obj.d.β, n1+n2, 2]]



#------------------------------------------------------------------------------#
#                                                                     Binomial #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
n = rand(1:1000, 1)[1]
p = rand(1)[1]
x1 = rand(Binomial(n, p), n1)
x2 = rand(Binomial(n, p), n2)
x = [x1, x2]

obj = onlinefit(Binomial, n, x1)
@test obj.d.n == n
@test obj.d.p == sum(x1) / (n * n1)
@test obj.nsuccess == sum(x1)
@test obj.n == n1
@test obj.nb == 1

OnlineStats.update!(obj, x2)
@test obj.d.n == n
@test obj.d.p == sum(x) / (n * (n1 + n2))
@test obj.nsuccess == sum(x)
@test obj.n == n1 + n2
@test obj.nb == 2

@test state(obj) == [[:ntrials, :p, :n, :nb] [obj.d.n, obj.d.p, obj.n, obj.nb]]
obj2 = copy(obj)
@test state(obj2) == [[:ntrials, :p, :n, :nb] [obj.d.n, obj.d.p, obj.n, obj.nb]]



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
@test obj.slogp == vec(sum(log(x1), 2) / n1)
@test obj.n == n1
@test obj.nb == 1

update!(obj, x2)
@test length(obj.d.alpha) == αlength
@test_approx_eq_eps obj.d.alpha fit(Dirichlet, x).alpha 1e-8 # fit is wrong sometimes
@test obj.n == n1 + n2
@test obj.nb == 2

@test state(obj) == hcat([[symbol("α$i") for i in 1:length(obj.d.alpha)], :n, :nb],
                     [obj.d.alpha, obj.n, obj.nb])
obj2 = copy(obj)
@test state(obj2) == state(obj)



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
@test obj.d.β == mean(x1)
@test obj.n == n1
@test nobs(obj) == n1
@test obj.nb == 1

OnlineStats.update!(obj, x2)
@test_approx_eq  obj.d.β mean(x)
@test obj.n == n1 + n2
@test obj.nb == 2

obj1 = copy(obj)
@test_approx_eq  obj.d.β mean(x)
@test obj.n == n1 + n2
@test obj.nb == 2



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
@test mean(obj.m) == mean(x1)
@test mean(obj.mlog) == mean(log(x1))
@test obj.n == n1
@test obj.nb == 1

OnlineStats.update!(obj, x2)
@test_approx_eq_eps mean(obj.m) mean(x) 1e-6
@test_approx_eq_eps mean(obj.mlog) mean(log(x)) 1e-6
@test obj.n == n1 + n2
@test obj.nb == 2

obj1 = copy(obj)
@test obj.n == n1 + n2
@test obj.nb == 2


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
@test obj.nb == 1


OnlineStats.update!(obj, x2)
@test obj.d.n == n
@test_approx_eq  obj.d.p  sum(x, 2) / (n * (n1 + n2))
@test obj.d.n == Multinomial(n, vec(sum(x1, 2) / (n * n1))).n
@test_approx_eq obj.d.p Multinomial(n, vec(sum(x, 2) / (n * (n1 + n2)))).p
@test obj.n == n1 + n2
@test obj.nb == 2

obj1 = copy(obj)
@test obj1.d.n == n
@test_approx_eq  obj1.d.p  sum(x, 2) / (n * (n1 + n2))
@test obj1.d.n == Multinomial(n, vec(sum(x1, 2) / (n * n1))).n
@test_approx_eq obj1.d.p Multinomial(n, vec(sum(x, 2) / (n * (n1 + n2)))).p
@test obj1.n == n1 + n2
@test obj1.nb == 2



#------------------------------------------------------------------------------#
#                                                                     MvNormal #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
d = rand(1:10, 1)[1]
x1 = rand(MvNormal(zeros(d), eye(d)), n1)
x2 = rand(MvNormal(zeros(d), eye(d)), n2)
x = [x1  x2]

obj = onlinefit(MvNormal, x1)
@test_approx_eq obj.d.μ  vec(mean(x1, 2))
@test_approx_eq mean(obj.c) vec(mean(x1, 2))
@test_approx_eq cov(obj.c)  cov(x1')
@test_approx_eq_eps cov(obj.c) obj.d.Σ.mat 1e-4
@test obj.n == n1
@test obj.nb == 1

OnlineStats.update!(obj, x2)
@test_approx_eq  obj.d.μ  vec(mean(x, 2))
@test_approx_eq mean(obj.c) vec(mean(x, 2))
@test_approx_eq cov(obj.c) cov(x')
@test obj.n == n1 + n2
@test obj.nb == 2

obj1 = copy(obj)
@test_approx_eq  obj1.d.μ  vec(mean(x, 2))
@test_approx_eq mean(obj1.c) vec(mean(x, 2))
@test_approx_eq cov(obj1.c) cov(x')
@test obj1.n == n1 + n2
@test obj1.nb == 2



#------------------------------------------------------------------------------#
#                                                                       Normal #
#------------------------------------------------------------------------------#
n1 = rand(1:1_000_000, 1)[1]
n2 = rand(1:1_000_000, 1)[1]
x1 = randn(n1)
x2 = randn(n2)
x = [x1, x2]

obj = onlinefit(Normal, x1)
@test mean(obj.v) == mean(x1)
@test_approx_eq mean(obj.d) mean(obj.v)
@test_approx_eq var(obj.v) var(x1)
@test obj.n == n1
@test obj.nb == 1

update!(obj, x2)
@test_approx_eq obj.d.σ std(x)
@test_approx_eq obj.d.μ mean(x)
@test_approx_eq mean(obj.v) mean(x)
@test_approx_eq var(obj.v) var(x)
@test obj.n == n1 + n2
@test obj.nb == 2

obj1 = copy(obj)
@test_approx_eq obj1.d.σ std(x)
@test_approx_eq obj1.d.μ mean(x)
@test_approx_eq mean(obj1.v) mean(x)
@test_approx_eq var(obj1.v) var(x)
@test obj1.n == n1 + n2
@test obj1.nb == 2
