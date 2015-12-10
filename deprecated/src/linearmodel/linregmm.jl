type LinRegMM <: OnlineStat
    β::VecF
    s1::VecF
    s2::VecF
    s3::VecF
    weighting::LearningRate
    n::Int

    function LinRegMM(p::Integer, wgt::LearningRate = LearningRate())
        new(zeros(p), zeros(p), zeros(p), zeros(p), wgt, 0)
    end
end

statenames(o::LinRegMM) = [:β, :nobs]
state(o::LinRegMM) = Any[o.β, nobs(o)]
StatsBase.coef(o::LinRegMM) = copy(o.β)
StatsBase.predict(o::LinRegMM, x::AVecF) = dot(x, o.β)
StatsBase.predict(o::LinRegMM, x::AMatF) = [predict(o, row(x, i)) for i in 1:size(x, 1)]
loss(o::LinRegMM, x::AMatF, y::AVecF) = mean(abs2(y - predict(o, x)))

function update!(o::LinRegMM, x::AVecF, y::Float64)
    γ = weight(o)
    ŷ = dot(x, o.β)

    for j in 1:length(x)
        o.s1[j] += γ * (x[j]^2 / _alpha(x, j) - o.s1[j])
        o.s2[j] += γ * (x[j]^2 / _alpha(x, j) * o.β[j] - o.s2[j])
        o.s3[j] += γ * (x[j] * (y - ŷ) - o.s3[j])

        o.β[j] = (o.s2[j] + o.s3[j]) / o.s1[j]
    end
    o.n += 1
end


_alpha(x::AVecF, i::Int) = abs(x[i]) / sumabs(x)



# n, p = 100000, 10
# x = randn(n, p)
# β = collect(1.:p)
# y = x*β + randn(n)
#
# o = LinRegMM(10, LearningRate(r=.6))
# update!(o, x, y)
# println(maxabs(β - coef(o)))
#
# println("")
# o2 = StochasticModel(x,y, intercept = false, algorithm = SGD(r=.6))
# println(maxabs(β - coef(o2)))
#
# println("")
# o2 = StochasticModel(x,y, intercept = false, algorithm = MMGrad(r=.6))
# println(maxabs(β - coef(o2)))
