# Playground module for testing new things in OnlineStats.  For the workflow:
# include("src/OnlineStats.jl")
# include("test/testcode.jl")

module Try
import OnlineStats
# import DeprecatedOnlineStats  # josh's local repo.  Simply an old commit of OnlineStats.jl
using StatsBase, Distributions

O = OnlineStats
# D = DeprecatedOnlineStats

# srand(123)
n, p = 100_000, 50
x = randn(n, p)
β = collect(1.:p) / p - .5
β_with_int = vcat(0., β)

println()
for m in [O.L2Regression(), O.LogisticRegression(), O.PoissonRegression()]
    if typeof(m) == O.L2Regression
        y = x*β + randn(n)
    elseif typeof(m) == O.LogisticRegression
        y = [rand(Bernoulli(1 / (1 + exp(-η)))) for η in x*β]
    else
        y = [rand(Poisson(exp(η))) for η in x*β]
    end
    print_with_color(:red, "▒▒▒ " * string(m) * "\n")

    println()
    for r in [.5, .6, .7, .8, .9]
        o = O.StatLearn(x, y, O.AdaGrad2(), O.LearningRate(r), m)
        println("AdaGrad2, r = $r   ",
            @sprintf("%8.4f", round(maxabs(O.loss(o, x, y)), 4)),
            @sprintf("  %15.4f", maxabs(coef(o) - β_with_int)))
    end
    println()
    for r in [.5, .6, .7, .8, .9]
        o = O.StatLearn(x, y, O.SGD(), O.LearningRate(r), m)
        println("SGD, r = $r        ",
            @sprintf("%8.4f", round(maxabs(O.loss(o, x, y)), 4)),
            @sprintf("  %15.4f", maxabs(coef(o) - β_with_int)))
    end
    println()
    for r in [.5, .6, .7, .8, .9]
        o = O.StatLearn(x, y, O.MMGrad(), O.LearningRate(r), m)
        println("MMGrad, r = $r     ",
            @sprintf("%8.4f", round(maxabs(O.loss(o, x, y)), 4)),
            @sprintf("  %15.4f", maxabs(coef(o) - β_with_int)))
    end
    println()
    for r in [.5, .6, .7, .8, .9]
        o = O.StatLearn(x, y, O.SGD2(), O.LearningRate(r), m)
        println("SGD2, r = $r       ",
            @sprintf("%8.4f", round(maxabs(O.loss(o, x, y)), 4)),
            @sprintf("  %15.4f", maxabs(coef(o) - β_with_int)))
    end
    println()

    o = O.StatLearn(x, y, O.AdaGrad(), m)
    println("AdaGrad             ",
        @sprintf("%8.4f", round(maxabs(O.loss(o, x, y)), 4)),
        @sprintf("  %15.4f", maxabs(coef(o) - β_with_int)))
    println("")

    o = O.StatLearn(x, y, O.AdaMMGrad(), m)
    println("AdaMMGrad           ",
        @sprintf("%8.4f", round(maxabs(O.loss(o, x, y)), 4)),
        @sprintf("  %15.4f", maxabs(coef(o) - β_with_int)))
    println("")
end
end
