module SparseModelTest
using OnlineStats, FactCheck

facts("Constructors") do
    n, p = 1_000, 10
    x = randn(n, p)
    β = collect(1.:p)
    y = x*β + randn(n)
    o = StochasticModel(x, y, penalty = L1Penalty(.1))
    sp = SparseModel(o)
end

end
