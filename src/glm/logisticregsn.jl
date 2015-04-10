export LogRegSN # Stochastic Newton

logitexp(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real logitexp

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type LogRegSN <: OnlineStat
    β::Vector             # Coefficients
    int::Bool             # Add intercept?
    t1::Vector            # Sufficient statistic 1
    t2::Matrix            # Sufficient statistic 2
    r::Float64            # learning rate
    n::Int64
    nb::Int64
end

function LogRegSN(X::Array, y::Vector; r = 0.51, intercept = true,
                         β = zeros(size(X, 2) + intercept))
    if length(unique(y)) != 2
        error("response vector does not have two categories")
    end

    n, p = size(X)
    if intercept
        X = [ones(length(y)) X]
        p += 1
    end
    y = y .== sort(unique(y))[2]  # convert y to 0 or 1

    t1 = X' * (y - logitexp(X * β)) / n
    t2 = X'X / n

    β += inv(t2) * t1

    LogRegSN(β, intercept, t1, t2, r, n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::LogRegSN, X::Matrix, y::Vector)
    if obj.int
        X = [ones(length(y)) X]
    end
    y = y .== unique(sort(y))[2]  # convert y to 0 or 1
    n = length(y)

    obj.nb += 1
    obj.n += n
    γ = obj.nb ^ -obj.r
    γ₂ = obj.nb ^ - .7

    obj.t1 += γ * (X' * (y - logitexp(X * obj.β)) / n - obj.t1)
    obj.t2 += n / (obj.n) * (X'X / n - obj.t2)

    obj.β += γ₂ * inv(obj.t2) * obj.t1
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::LogRegSN)
    names = [[symbol("β$i") for i in [1:length(obj.β)] - obj.int];
             :n; :nb]
    estimates = [obj.β, obj.n, obj.nb]
    return([names estimates])
end


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# Base
StatsBase.coef(obj::LogRegSN) = return obj.β

function Base.show(io::IO, obj::LogRegSN)
    println(io, "Online Logistic Regression (SN Algorithm):\n", state(obj))
end






# Testing
p = 10
β = ([1:p] - p/2) / p
xs = randn(100, p)
ys = vec(logitexp(xs * β))
for i in 1:length(ys)
    ys[i] = rand(Distributions.Bernoulli(ys[i]))
end

obj = OnlineStats.LogRegSN(xs, ys, r=.51)

df = OnlineStats.make_df(obj)

for i in 1:999
    xs = randn(100, p)
    ys = vec(logitexp(xs * β))
    for i in 1:length(ys)
        ys[i] = rand(Distributions.Bernoulli(ys[i]))
    end
    OnlineStats.update!(obj, xs, ys)
    OnlineStats.make_df!(df, obj)
end

df_melt = melt(df, p+2:p+3)
Gadfly.plot(df_melt, x=:n, y=:value, color=:variable, Gadfly.Geom.line,
            yintercept=β, Gadfly.Geom.hline,
            Gadfly.Scale.y_continuous(minvalue=-.6, maxvalue=.6))

