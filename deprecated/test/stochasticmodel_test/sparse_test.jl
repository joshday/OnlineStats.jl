module SparseModelTest
using OnlineStats, FactCheck

facts("Constructors") do
    n, p = 1_000, 10
    x = randn(n, p)
    β = collect(1.:p)
    y = x*β + randn(n)
    o = StochasticModel(p, penalty = L1Penalty(.1))
    sp = SparseModel(o)
    sp = SparseModel(o, HardThreshold(burnin = 100))
    update!(sp, x, y)
    update!(o, HardThreshold())

    @fact nobs(sp) --> 1_000
    @fact state(sp) --> state(sp.o)
    @fact statenames(sp) --> statenames(sp.o)

    HardThreshold(burnin = 123)
end

end
