# Author(s): Josh Day <emailjoshday@gmail.com>

export LinearModel, coef, cov


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# NewType
type LinearModel <: OnlineStat
    A::Matrix              # [X y]' * [X y] / n (lower triangular)
    B::Matrix              # swept A (lower triangular)
    n::Int64
    nb::Int64
end

function LinearModel(X::Matrix, y::Vector)
    size(X, 1) == length(y) || error("rows in X don't match length of y")
    n, p = size(X)
    A = BLAS.syrk('L', 'T', 1.0, [X y])
    B = sweep!(copy(A), 1:p)
    LinearModel(A, B, n, 1)
end

function LinearModel(x::Vector, y::Vector)
    n = length(x)
    LinearModel(reshape(x, n, 1), y)
end

coef(obj::LinearModel) = obj.B[end, 1:end-1]'
mse(obj::LinearModel) = obj.B[end, end] / (obj.n - size(obj.A, 1))


#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::LinearModel, X, y)
    n, p = size(X)
    n == length(y) || error("size(X, 1) != length(y)")
    p == size(obj.A, 2) - 1 || error("number of variables don't match")

    BLAS.syrk!('L', 'T', 1.0, [X y], 1.0, obj.A)
    obj.B = sweep!(copy(obj.A), 1:p)
    obj.n += n
    obj.nb += 1
end


#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::LinearModel)
    p = size(obj.A, 1) - 1
    names = [[symbol("b" * string(i)) for i in 1:p], :n, :nb]
    estimates = [coef(obj), obj.n, obj.nb]
    return([names estimates])
end

#-----------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# Batch 1
x1 = randn(1000, 3)
y1 = vec(sum(x1, 2)) + randn(1000)
obj = OnlineStats.LinearModel(x1, y1)

# Batch 2
x2 = rand(1002, 3)
y2 = vec(sum(x2, 2)) + randn(1002)
OnlineStats.update!(obj, x2, y2)

OnlineStats.coef(obj)
OnlineStats.mse(obj)

OnlineStats.state(obj)

maximum(abs(tril(obj.A - [x1 y1; x2 y2]' * [x1 y1; x2 y2])))

