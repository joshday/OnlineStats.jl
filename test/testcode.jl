############################################################## TEST
module Test
using OnlineStats
using Plots
pyplot()


n, p = 100, 10
β = collect(1.:p)
sd = 3
x = randn(n, p) * sd
y = x * β + randn(n)

# o = StochasticModel(x, y, algorithm = MMGrad())
#
# tr = TracePlot(o)
#
# for i in 1:100
#     x = randn(n, p)
#     y = x * β + randn(n)
#     update!(tr, x, y)
# end

o1 = StochasticModel(p, algorithm = MMGrad(r = .6))
o2 = StochasticModel(p, algorithm = SGD(r = .6))
# o3 = StochasticModel(p, algorithm = ProxGrad())
# o4 = StochasticModel(p, algorithm = RDA())
o5 = LinReg(p)


xtest = randn(10_000, p) * sd
ytest = xtest*β + randn(10_000)
myloss(o) = loss(o, xtest, ytest)
myloss(o::LinReg) = mean(abs2(ytest - xtest*coef(o)))

comp = CompareTracePlot([o1, o2, o5], myloss)
for i in 1:100
    x = randn(n, p) * sd
    y = x * β + randn(n)
    update!(comp, x, y, 5)
end


plot!(comp.p, ylims=(0,10))
display(comp.p)

end
