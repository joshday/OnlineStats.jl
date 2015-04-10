export LogRegSGD


logitexp(x) = 1 / (1 + exp(-x))
@vectorize_1arg Real logitexp

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type LogRegSGD <: OnlineStat
    β::Vector             # Coefficients
    int::Bool             # Add intercept?
    r::Float64            # learning rate
    n::Int64
    nb::Int64
end

function LogRegSGD(X::Array, y::Vector; r = 0.51, intercept = true,
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
    β += vec(mean(y ./ (1 + exp(y .* X * β)) .* X, 1))

    LogRegSGD(β, intercept, r, n, 1)
end


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::LogRegSGD, X::Matrix, y::Vector)
    if obj.int
        X = [ones(length(y)) X]
    end
    y = 2 * (y .== unique(sort(y))[2]) - 1 # convert y to -1 or 1
    γ = obj.nb ^ -obj.r
    obj.β += γ * vec(mean(y ./ (1 + exp(y .* X * obj.β)) .* X, 1))
    obj.n += length(y)
    obj.nb += 1
end



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::LogRegSGD)
    names = [[symbol("β$i") for i in [1:length(obj.β)] - obj.int];
             :n; :nb]
    estimates = [obj.β, obj.n, obj.nb]
    return([names estimates])
end


#----------------------------------------------------------------------------#
#----------------------------------------------------------------------# Base
StatsBase.coef(obj::LogRegSGD) = return obj.β

function Base.show(io::IO, obj::LogRegSGD)
    println(io, "Online Logistic Regression (SGD Algorithm):\n", state(obj))
end






# Testing
# β = ([1:10] - 10/2) / 10
# xs = randn(100, 10)
# ys = vec(logitexp(xs * β))
# for i in 1:length(ys)
#     ys[i] = rand(Bernoulli(ys[i]))
# end

# obj = OnlineStats.LogRegSGD(xs, ys, r=.51)
# df = OnlineStats.make_df(obj) # Save estimates to DataFrame

# for i in 1:9999
#     xs = randn(100, 10)
#     ys = vec(logitexp(xs * β))
#     for i in 1:length(ys)
#         ys[i] = rand(Bernoulli(ys[i]))
#     end

#     OnlineStats.update!(obj, xs, ys)
#     OnlineStats.make_df!(df, obj)
# end

# df_melt = melt(df, 12:13)
# plot(df_melt, x=:n, y=:value, color=:variable, Geom.line,
#             yintercept=β, Geom.hline,
#             Scale.y_continuous(minvalue=-.75, maxvalue=.75))

