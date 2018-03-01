# Assume input is -1 or 1
mutable struct BinaryStump{S} <: ExactStat{(1, 0)}
    stats1::S
    stats2::S
    split::Pair{Int, Float64}
    featuresubset::Vector{Int}
end
function BinaryStump(p::Int, b::Int = 10, subset = 1:p) 
    BinaryStump(p * Hist(b), p * Hist(b), Pair(0, Inf), collect(subset))
end
function Base.show(io::IO, o::BinaryStump)
    println(io, "BinaryStump:")
    println(io, "  > -1: ", name(o.stats1))
    print(io, "  >  1: ", name(o.stats2))
    if first(o.split) > 0
        print(io, "\n  > split on variable ", first(o.split), " at ", last(o.split))
    end
end

nparams(o::BinaryStump) = length(o.stats1)
function probs(o::BinaryStump) 
    n = [nobs(first(o.stats1)), nobs(first(o.stats2))]
    n ./ sum(n)
end

value(o::BinaryStump) = find_split(o)

function fit!(o::BinaryStump, xy, γ)
    x, y = xy
    xi = x[o.featuresubset]
    if y == -1.0 
        fit!(o.stats1, xi, γ)
    elseif y == 1.0
        fit!(o.stats2, xi, γ)
    else 
        error("$y should be -1 or 1")
    end
end

function find_split(o::BinaryStump)
    imp_root = impurity(probs(o))
    s1 = copy(o.stats1)
    s2 = copy(o.stats2)
    ig = zeros(nparams(o))  # information gain
    x = zeros(nparams(o))
    for j in eachindex(ig)
        h1 = s1[j]
        h2 = s2[j]
        xj = (mean(h1) + mean(h2)) / 2  # find best split location

        n1l, n1r = splitcounts(h1, xj)
        n2l, n2r = splitcounts(h2, xj)

        counts_l = [n1l, n2l]
        counts_r = [n1r, n2r]

        probs_l = counts_l ./ sum(counts_l)
        probs_r = counts_r ./ sum(counts_r)

        left_imp = impurity(probs_l)
        right_imp = impurity(probs_r)
        after_imp = smooth(left_imp, right_imp, (n1r + n2r) / (n1r + n2r + n1l + n2l))

        x[j] = xj
        ig[j] = imp_root - after_imp 
    end
    j = findmin(ig)[2]
    xj = x[j]
    o.split = Pair(j, xj)
end

classify(o::BinaryStump, x::VectorOb) = 2.0 * (x[o.featuresubset[first(o.split)]] < last(o.split)) - 1.0
function classify(o::BinaryStump, x::AbstractMatrix, ::Rows = Rows())
    mapslices(x -> classify(o, x), x, 2)
end
function classify(o::BinaryStump, x::AbstractMatrix, ::Cols)
    mapslices(x -> classify(o, x), x, 1)
end

#-----------------------------------------------------------------------# BinaryStumpForest 
struct BinaryStumpForest{S} <: ExactStat{(1, 0)}
    forest::Vector{BinaryStump{S}}
end
function BinaryStumpForest(p::Integer; nt = 100, b = 10, np = 3)
    forest = [BinaryStump(np, b, sample(1:p, np; replace=false)) for i in 1:nt]
    BinaryStumpForest(forest)
end

value(o::BinaryStumpForest) = value.(o.forest)

function fit!(o::BinaryStumpForest, xy, γ)
    i = rand(1:length(o.forest))
    fit!(o.forest[i], xy, γ)
end

function predict(o::BinaryStumpForest, x::VectorOb)
    [classify(stump, x) for stump in o.forest]
end


















#-----------------------------------------------------------------------# Stump
struct Stump{T <: NBClassifier} <: ExactStat{(1, 0)}
    root::T 
    split_locs::Vector{Float64}
    info_gains::Vector{Float64}
    probs::Vector{Float64}
end
Stump(p::Integer, T::Type, b::Int=10) = Stump(NBClassifier(p, T, b), zeros(p), zeros(p), zeros(p))

function fit!(o::Stump, xy, γ)
    fit!(o.root, xy, γ)
end

nparams(o::Stump) = length(split_locs)

function get_splits!(o::Stump)
    base_impurity = impurity(o.root)
    for j in nparams(o)
        hist_vec = o.root[j]
        split_locs[j] = mean(mean(h) for h in hist_vec)

    end
end

function impurity(v::Vector{<:Hist})
    n = nobs.(v)
    entropy2(nobs.(v) ./ sum(n))
end



#-----------------------------------------------------------------------# StumpForest

"""
    StumpForest(p::Int, T::Type; b=10, nt=100, np=3)

Online random forest with stumps (one-node trees) where:

- `p` is the number of predictors. 
- `b` is the number of histogram bins to estimate conditional densities.
- `nt` is the number of trees in the forest.
- `np` is the number predictors to give to each stump.

# Example 

    x = randn(10_000, 10)
    y = x * linspace(-1, 1, 10) .> 0 

    s = Series((x, y), StumpForest(10, Bool))

    # prediction accuracy
    mean(y .== classify(s.stats[1], x))
"""
struct StumpForest{T <: NBClassifier} <: ExactStat{(1,0)}
    forest::Vector{T}
    inputs::Matrix{Int}  # NBClassifier i gets: x[inputs[i]]
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
    StumpForest(forest, inputs)
end

Base.keys(o::StumpForest) = keys(o.forest[1])

function fit!(o::StumpForest, xy, γ)
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
    @eval begin
        function $f(o::StumpForest, x::AbstractMatrix, dim::Rows = Rows())
            mapslices(x -> $f(o, x), x, 2)
        end
        function $f(o::StumpForest, x::AbstractMatrix, dim::Cols)
            mapslices(x -> $f(o, x), x, 1)
        end
    end
end
