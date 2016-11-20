module Experimental
reload("OnlineStats")
using OnlineStats, Distributions
O = OnlineStats

function rand_dirmult(α, n)
    d = length(α)
    dir = Dirichlet(α)
    results = zeros(d, n)
    for i in 1:n
        p = rand(dir)
        results[:, i] = rand(Multinomial(rand(10:100), p))
    end
    results'
end

x = rand_dirmult(collect(1.:5), 100_000)

@time o = FitDirichletMultinomial(x)
display(o)

end
