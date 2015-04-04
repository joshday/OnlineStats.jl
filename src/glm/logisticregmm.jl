export LogRegMM

logitexp(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real logitexp

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type LogRegMM <: OnlineStat
    β::Vector             # Coefficients
    int::Bool             # Add intercept?
    t1::Vector            # Sufficient statistic 1
    t2::Matrix            # Sufficient statistic 2
    t3::Vector            # Sufficient statistic 3
    r::Float64            # learning rate
    n::Int64
    nb::Int64
end

function LogRegMM(X::Array, y::Vector; r = 0.51, intercept = true,
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

    t1 = X' * (y - logitexp(X * β))
    t2 = X'X
    t3 = X'X * β

    β = 4 * inv(t2) * (t3 + t1)

    LogRegMM(β, intercept, t1, t2, t3, r, n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::LogRegMM, X::Matrix, y::Vector)
    if obj.int
        X = [ones(length(y)) X]
    end
    y = y .== unique(sort(y))[2]  # convert y to 0 or 1
    n = length(y)

    obj.nb += 1
    γ = obj.nb ^ -obj.r

    obj.t1 += γ * (X' * (y - logitexp(X * obj.β)) - obj.t1)
    obj.t2 += γ * (X'X - obj.t2)
    obj.t3 += γ * (X'X * obj.β - obj.t3)

    obj.β = inv(obj.t2) * (obj.t3 + obj.t1)
    obj.n += n
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::LogRegMM)
    names = [[symbol("β$i") for i in [1:length(obj.β)] - obj.int];
             :n; :nb]
    estimates = [obj.β, obj.n, obj.nb]
    return([names estimates])
end


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# Base
StatsBase.coef(obj::LogRegMM) = return obj.β

function Base.show(io::IO, obj::LogRegMM)
    println(io, "Online Logistic Regression (MM Algorithm):\n", state(obj))
end






# # Testing
# p = 10
# β = ([1:p] - p/2) / p
# xs = randn(100, p)
# ys = vec(logitexp(xs * β))
# for i in 1:length(ys)
#     ys[i] = rand(Distributions.Bernoulli(ys[i]))
# end
# # obj = OnlineStats.LogRegMM(xs, ys, r=., β = [0; β])
# obj = OnlineStats.LogRegMM(xs, ys, r=.7)

# df = OnlineStats.make_df(obj)

# for i in 1:999
#     xs = randn(100, p)
#     ys = vec(logitexp(xs * β))
#     for i in 1:length(ys)
#         ys[i] = rand(Distributions.Bernoulli(ys[i]))
#     end
#     OnlineStats.update!(obj, xs, ys)
#     OnlineStats.make_df!(df, obj)
# end

# df_melt = melt(df, p+2:p+3)

# Gadfly.plot(df_melt, x=:n, y=:value, color=:variable, Gadfly.Geom.line,
#             yintercept=β, Gadfly.Geom.hline,
#             Gadfly.Scale.y_continuous(minvalue=-1, maxvalue=1))
