module AdagradTest
using OnlineStats, FactCheck
using Distributions
using Compat
# import StreamStats

const n = 1_000_000
const p = 10
const λ = 0.0001

# TODO compare to StreamStats results
# TODO compare timing to StreamStats and profile

function convertLogisticY(xβ)
    prob = 1 ./ (1 + exp(-xβ))
    @compat Float64(rand(Bernoulli(prob)))
end


function do_ss_ols(x, y)
    ols = StreamStats.ApproxOLS(p, 1.0)
    for i in 1:n
        StreamStats.update!(ols, vec(x[i,:]), y[i])
    end
    ols
end

function do_os_ols(x, y)
    ols = Adagrad(p+1)
    for i in 1:n
        update!(ols, vec(x[i,:]), y[i])
    end
    ols
end

function do_os_ols_bias(x, y)
    ols = Adagrad(p+1)
    for i in 1:n
        xb = BiasVector(vec(x[i,:]))
        update!(ols, xb, y[i])
    end
    ols
end


function do_ss_approx_ridge(x,y)
    ols = StreamStats.ApproxRidge(p, λ, 1.0)
    for i in 1:n
        StreamStats.update!(ols, vec(x[i,:]), y[i])
    end
    ols
end
function do_ss_approx_logit(x,y)
    ols = StreamStats.ApproxLogit(p, 1.0)
    for i in 1:n
        StreamStats.update!(ols, vec(x[i,:]), y[i])
    end
    ols
end
function do_ss_approx_l2_logit(x,y)
    ols = StreamStats.ApproxL2Logit(p, λ, 1.0)
    for i in 1:n
        StreamStats.update!(ols, vec(x[i,:]), y[i])
    end
    ols
end

function do_os_ols_l2_logit(x, y)
    ols = Adagrad(p+1; link=LogisticLink(), loss=LogisticLoss(), reg=L2Reg(λ))
    for i in 1:n
        update!(ols, vec(x[i,:]), y[i])
    end
    ols
end


facts("Adagrad") do

    atol = 0.1
    rtol = 0.05

    context("L2Regression") do
        x = randn(n, p)
        β = collect(1.:p)
        y = x * β + randn(n)*10


        # normal lin reg
        o = Adagrad(x, y)
        OnlineStats.DEBUG(o, ": β=", β)
        @fact coef(o) --> roughly(β, atol = atol, rtol = rtol) "update! coef(o)"
        @fact predict(o, ones(p)) --> roughly(1.0 * sum(β), atol = atol, rtol = rtol)

        # updatebatch!
        o = Adagrad(p)
        onlinefit!(o, 2, x, y, batch = true)
        onlinefit!(o, 2, x, y, batch = true)
        @fact coef(o) --> roughly(β, .2) "updatebatch! coef(o)"

        # ridge regression
        # repeat same data in first 2 variables
        # it should give 1.5 for β₁ and β₂ after reg (even though actual betas are 1 and 2)
        x[:,2] = x[:,1]
        y = x * β
        β2 = vcat(1.5, 1.5, β[3:end])
        o = Adagrad(x, y; penalty = L2Penalty(0.01))
        OnlineStats.DEBUG(o, ": β=", β2)
        @fact coef(o) --> roughly(β2, atol = atol, rtol = rtol)

        # some simple checks of the interface
        @fact statenames(o) --> [:β, :nobs]
        @fact state(o)[1] --> coef(o)
        @fact state(o)[2] --> nobs(o)
    end

    context("L1Regression") do
        x = randn(n, p)
        β = collect(1.:p)
        y = x * β + randn(n)*10

        o = Adagrad(x, y, model = L1Regression())
        OnlineStats.DEBUG(o, ": β=", β)
        @fact coef(o) --> roughly(β, atol = atol, rtol = rtol)
        @fact predict(o, ones(p)) --> roughly(1.0 * sum(β), atol = .5)
    end

    context("LogisticRegression") do
        x = randn(n, p)
        β = collect(1.:p)
        y = map(convertLogisticY, x * β)

        # logistic
        o = Adagrad(x, y; model=LogisticRegression())
        OnlineStats.DEBUG(o, ": β=", β)
        @fact coef(o) --> roughly(β, atol = 0.5, rtol = 0.1)

        # logistic l2
        # repeat same data in first 2 variables
        # it should give 1.5 for β₁ and β₂ after reg (even though actual betas are 1 and 2)
        x[:,2] = x[:,1]
        y = map(convertLogisticY, x * β)
        β2 = vcat(1.5, 1.5, β[3:end])
        o = Adagrad(x, y; model=LogisticRegression(), penalty=L2Penalty(0.00001))
        OnlineStats.DEBUG(o, ": β=", β2)
        @fact coef(o) --> roughly(β2, atol = 0.8, rtol = 0.2)
    end

    context("PoissonRegression") do
        x = randn(n, p)
        β = collect(1.:p) / p
        y = @compat Float64[rand(Poisson(i)) for i in exp(x*β)]

        o = OnlineStats.Adagrad(x, y, model = OnlineStats.PoissonRegression(), η = .001)
        @pending coef(o) --> roughly(β, atol = 0.8, rtol = 0.2)
    end

    context("QuantileRegression") do
        x = randn(n, p)
        β = collect(1.:p)
        y = x * β + randn(n)

        o = Adagrad(x, y; model = QuantileRegression(.8))
        @fact coef(o) --> roughly(β, atol = 0.5, rtol = 0.1)

        o = Adagrad(hcat(ones(n), x), y; model = QuantileRegression(.8))
        @fact coef(o) --> roughly(vcat(quantile(Normal(), .8), β), atol = 0.5, rtol = 0.1)

        ϵdist = Normal(0, 5)
        y = x * β + rand(ϵdist, n)
        o = Adagrad(hcat(ones(n), x), y; model = QuantileRegression(.8))
        @fact coef(o) --> roughly(vcat(quantile(ϵdist, .8), β), atol = 0.5, rtol = 0.1)
    end

    context("SVMLike") do
        x = randn(n, p)
        β = collect(1.:p)
        y = map(convertLogisticY, x * β)
        y = 2y - 1

        o = Adagrad(x, y; model = SVMLike())
        yhat = (predict(o, x) .> 0)
        y = y .> 0
        misclass = mean(yhat .!= y)
        @fact misclass --> less_than(.2) "Check that less than 20% are misclassified"
    end

    context("HuberRegression") do
        x = randn(n, p)
        β = collect(1.:p)
        y = x * β + randn(n)

        o = Adagrad(x, y; model = HuberRegression(2))
        @fact coef(o) --> roughly(β, atol = 0.5, rtol = 0.1)
    end


    # context("Vs StreamStats") do
    #     x = randn(n, p)
    #     xbias = hcat(x, ones(n))
    #     β = collect(1.:p)
    #     y = x * β + randn(n)*10

    #     # warmup and validity
    #     ols_ss = do_ss_ols(x, y)
    #     β_streamstats = vcat(ols_ss.β, ols_ss.β₀)
    #     β_onlinestats = coef(do_os_ols(xbias, y))
    #     β_os_withbias = coef(do_os_ols_bias(x, y))

    #     @fact β_streamstats --> roughly(β_onlinestats)
    #     @fact β_os_withbias --> roughly(β_onlinestats)

    #     # test speed
    #     e_ss = @elapsed do_ss_ols(x,y)
    #     e_os = @elapsed do_os_ols(xbias,y)
    #     e_os_bias = @elapsed do_os_ols_bias(x,y)
    #     @fact e_os / e_ss --> less_than(1.4)
    #     @fact e_os_bias / e_ss --> less_than(1.4)


    #     # test other algos
    #     ss = do_ss_approx_ridge(x,y)
    #     β_ss_ridge = vcat(ss.β, ss.β₀)
    #     @fact β_ss_ridge --> roughly(coef(Adagrad(xbias,y; reg=L2Reg(λ))), rtol = 0.02)

    #     y = map(convertLogisticY, x * β)
    #     ss = do_ss_approx_logit(x, y)
    #     β_ss_logit = vcat(ss.β, ss.β₀)
    #     @fact β_ss_logit --> roughly(coef(Adagrad(xbias,y; link=LogisticLink(), loss=LogisticLoss())), rtol = 0.02)

    #     ss = do_ss_approx_l2_logit(x, y)
    #     β_ss_l2_logit = vcat(ss.β, ss.β₀)
    #     @fact β_ss_l2_logit --> roughly(coef(Adagrad(xbias,y; link=LogisticLink(), loss=LogisticLoss(), reg=L2Reg(λ))), rtol = 0.02)


    #     # test speed
    #     e_ss_l2logit = @elapsed do_ss_approx_l2_logit(x,y)
    #     e_os_l2logit = @elapsed do_os_ols_l2_logit(xbias,y)
    #     @fact e_os_l2logit / e_ss_l2logit --> less_than(1.5)
    # end

end




# # # if false
# if true
# # using OnlineStats
# # import StreamStats
# const n = 1_000_000;
# const p = 10;
# const x = randn(n, p);
# const xbias = hcat(ones(n), x);
# const β = collect(1.:p);
# const y = x * β + randn(n)*10;
# do_ss_ols(x, y) = (ols = StreamStats.ApproxOLS(p); for i in 1:n; StreamStats.update!(ols, vec(x[i,:]), y[i]); end; ols)
# do_os_ols(x, y) = (ols = Adagrad(p+1); for i in 1:n; update!(ols, vec(x[i,:]), y[i]); end; ols)

# # StreamStats.state(do_ss_ols(x, y))'
# # ols_ss = StreamStats.ApproxOLS(p)
# # coef(do_os_ols(xbias,y))'

# # #warmup complete
# # @time do_ss_ols(x,y)
# # @time do_os_ols(xbias,y)

# include("/home/tom/.julia/v0.4/OnlineStats.jl/src/multivariate/bias.jl")
# function do_os_ols_bias(x, y)
#     ols = Adagrad(p+1)
#     for i in 1:n
#         vx = vec(x[i,:])
#         xb = XXX.BiasVector(vx)
#         update!(ols, xb, y[i])
#     end
#     ols
# end
# # do_os_ols_bias(x, y)
# # @time do_os_ols_bias(x,y)
# # # @profile do_os_ols_bias(x,y)

# function do_os_ols_bias2(x, y)
#     ols = Adagrad(p+1)
#     for i in 1:n
#         vx = vec(x[i,:])
#         xb = XXX.BiasVector2(vx)
#         update!(ols, xb, y[i])
#     end
#     ols
# end
# do_os_ols_bias(x, y)
# @time do_os_ols_bias(x,y)
# @profile do_os_ols_bias(x,y)


end # module
