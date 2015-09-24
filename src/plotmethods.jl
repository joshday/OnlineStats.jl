import Plots

"Convert a Vector of equal-length Vectors to a Matrix"
function vecvec_to_mat(x::Vector{Vector})
    n = length(x)
    p = length(x[1])
    mat = zeros(n, p)
    for i in 1:n
        mat[i, :] = x[i]'
    end
    mat
end

"Get the first element from the output of `state()`"
state1(o::OnlineStat) = state(o)[1]



#-------------------------------------------------------------------# traceplot!
"""
### Update an OnlineStat and plot its history

`traceplot!(o, batchsize, data...)`

Update an OnlineStat `o` with `data...` and create a traceplot of its history.
A snapshot of the statistic/model will be taken every `batchsize` observations.
At each snapshot, the value(s) `y = f(o)` is plotted at `x = nobs(o)`.

`f` is specified by a keyword argument that defaults to the first element returned by `state(o)`.

### Example: coefficients of a stochastic gradient descent model

`o = SGModel(size(x,2))`

`traceplot!(o, batchsize, x, y)`
"""
function traceplot!(o::OnlineStat, b::Integer, data...;
        f::Function = state1
    )
    v = tracefit!(o, b, data...)
    mat = vecvec_to_mat(Vector[collect(f(vi)) for vi in v])
    nvec = Int[nobs(vi) for vi in v]
    plt = Plots.plot(nvec, mat, xlab = "nobs", ylab = "value",
        title = "Trace Plot of " * string(typeof(o)) * ", b = $b, with function " * string(f) * "()"
    )
end



# TEST
if false
    n, p = 50_000, 5
    x = randn(n, p)
    β = vcat(1:p) - p/2
    y = 3.0 + x*β + randn(n)
    o = OnlineStats.SGModel(p, algorithm = OnlineStats.RDA(η = .1))
    OnlineStats.traceplot!(o, 1000, x, y)
end
