export LogRegMM

logitexp(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real logitexp

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type LogRegMM <: OnlineStat
    β::Vector             # Coefficients
    int::Bool             # Add intercept?
    S1::Matrix            # Sufficient statistic 1
    S2::Vector            # Sufficient statistic 2
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
    y = 2 * (y .== unique(sort(y))[2]) - 1 # convert y to -1 or 1

    S1 = X'X / n
    S2 = X' * ((y + 1) / 2 - logitexp(X * β)) / n

    β += 4 * inv(S1) * S2

    LogRegMM(β, intercept, S1, S2, r, n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::LogRegMM, X::Matrix, y::Vector)
    if obj.int
        X = [ones(length(y)) X]
    end
    y = 2 * (y .== unique(sort(y))[2]) - 1 # convert y to -1 or 1
    n = length(y)

    obj.nb += 1
    γ = 1 / (obj.nb)
#     obj.S1 += γ * (X'X  - obj.S1) / n
    obj.S1 += n / (obj.n + n) * (X'X  - obj.S1)
    obj.S2 += γ * (X' * ((y + 1) / 2 - logitexp(X * obj.β)) / n  - obj.S2)

    obj.β += 4 * inv(obj.S1) * obj.S2
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
x = randn(100, 10)
y = vec(logitexp(sum(x, 2)))
for i in 1:length(y)
    y[i] = rand(Bernoulli(y[i]))
end
obj = OnlineStats.LogRegMM(x, y, r=.51)

df = OnlineStats.make_df(obj)

for i in 1:9999
    x = randn(100, 10)
    y = vec(logitexp(sum(x, 2)))
    for i in 1:length(y)
        y[i] = rand(Bernoulli(y[i]))
    end
    OnlineStats.update!(obj, x, y)
    OnlineStats.make_df!(df, obj)
end

df_melt = melt(df, 12:13)

Gadfly.plot(df_melt, x=:n, y=:value, color=:variable, Gadfly.Geom.line)
