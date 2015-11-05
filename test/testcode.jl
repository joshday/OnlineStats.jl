############################################################## TEST
module Test
using OnlineStats
using Plots
pyplot()


n, p = 100, 10
β = collect(1.:p)
x = randn(n, p)
y = x * β + randn(n)

o = StochasticModel(x, y, algorithm = MMGrad())

tr = TracePlot(o)

for i in 1:100
    x = randn(n, p)
    y = x * β + randn(n)
    update!(tr, x, y)
end

end
