mutable struct StumpForest{T <: NBClassifier} <: ExactStat{(1,0)}
    forest::Vector{T}
    inputs::Matrix{Int}
    nobs::Int
end

# b  = size of histogram
# nt = number of trees in forest
# np = number of predictors to give each tree
function StumpForest(p::Integer, T::Type; b = 10, nt = 100, np = 3)
    forest = [NBClassifier(np, T, b) for i in 1:nt]
    inputs = zeros(Int, np, nt)
    for j in 1:nt 
        inputs[:, j] = sample(1:p, np; replace = false)
    end
    StumpForest(forest, inputs, 0)
end

Base.keys(o::StumpForest) = keys(o.forest[1])

function fit!(o::StumpForest, xy, γ)
    o.nobs += 1
    x, y = xy
    i = rand(1:length(o.forest))
    fit!(o.forest[i], (@view(x[o.inputs[:, i]]), y), γ)
end

function predict(o::StumpForest, x::VectorOb)
    out = predict(o.forest[1], x[o.inputs[:, 1]])
    for i in 2:length(o.forest)
        @views smooth!(out, predict(o.forest[i], x[o.inputs[:, i]]), 1/i)
    end
    out
end
function classify(o::StumpForest, x::VectorOb)
    _, i = findmax(predict(o, x))
    keys(o)[i]
end

for f in [:predict, :classify]
    @eval begin yhat
        function $f(o::StumpForest, x::AbstractMatrix, dim::Rows = Rows())
            mapslices(x -> $f(o, x), x, 2)
        end
        function $f(o::StumpForest, x::AbstractMatrix, dim::Cols)
            mapslices(x -> $f(o, x), x, 1)
        end
    end
end
