#-----------------------------------------------------------------------# BinarySplit
# Prediction:  x[j] < loc ? lab : -lab
struct BinarySplit
    j::Int 
    loc::Float64 
    lab::Float64
    ig::Float64
end
classify(o::BinarySplit, x::VectorOb) = x[o.j] < o.loc ? o.lab : -o.lab

#-----------------------------------------------------------------------# BinaryStump
mutable struct BinaryStump <: ExactStat{(1, 0)}
    stats1::MV{Hist{0, AdaptiveBins{Float64}}} # summary statistics for class = -1
    stats2::MV{Hist{0, AdaptiveBins{Float64}}} # summary statistics for class = 1
    split::BinarySplit
    subset::Vector{Int}  # indices of the subset of features
end
function BinaryStump(p::Int, b::Int = 10, subset = 1:p) 
    BinaryStump(p * Hist(b), p * Hist(b), BinarySplit(0,0.0,0.0,0.0), collect(subset))
end
function Base.show(io::IO, o::BinaryStump)
    print(io, "BinaryStump")
    if o.split.j > 0 
        y = o.split.lab
        print(io, " (x[$(o.subset[o.split.j])] < $(o.split.loc) ? ", y, " : ", -y, ")")
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
    xi = x[o.subset]
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
    trials = BinarySplit[]
    for j in 1:nparams(o)
        h1 = s1[j].alg 
        h2 = s2[j].alg
        for loc in [-.1, 0.0, .1] #split_candidates(merge(h1, h2), 10)[2:end-1]  # make setting
            n1l = sum(h1, loc)
            n2l = sum(h2, loc)
            n1r = nobs(h1) - n1l 
            n2r = nobs(h2) - n2l

            counts_l = [n1l, n2l]  # counts of -1 and 1 in left
            counts_r = [n1r, n2r]  # counts of -1 and 1 in right

            left_imp = impurity(counts_l ./ sum(counts_l))  # impurity of left
            right_imp = impurity(counts_r ./ sum(counts_r))  # impurity of right
            after_imp = smooth(left_imp, right_imp, (n1r + n2r) / (n1r + n2r + n1l + n2l))

            lab = n1l > n2l ? -1.0 : 1.0
            push!(trials, BinarySplit(j, loc, lab, imp_root - after_imp))
        end
    end

    max_ig = maximum(split.ig for split in trials)
    i = find(x -> x.ig == max_ig, trials)[1]
    o.split = trials[i]
end

classify(o::BinaryStump, x::VectorOb) = classify(o.split, x[o.subset])


function classify(o::BinaryStump, x::AbstractMatrix, ::Rows = Rows())
    mapslices(x -> classify(o, x), x, 2)
end
function classify(o::BinaryStump, x::AbstractMatrix, ::Cols)
    mapslices(x -> classify(o, x), x, 1)
end

#-----------------------------------------------------------------------# BinaryStumpForest 
"""
    BinaryStumpForest(p::Int; nt = 100, b = 10, np = 3)

Build a random forest (for responses -1, 1) based on stumps (single-split trees) where 

- `p` is the number of predictors 
- `nt` is the number of trees (stumps) in the forest 
- `b` is the number of histogram bins used to estimate ``P(x_j | class)``
- `np` is the number of random predictors each tree will use

# Usage

After fitting, you must call `value` to calculate the splits.
"""
struct BinaryStumpForest <: ExactStat{(1, 0)}
    forest::Vector{BinaryStump}
end
function BinaryStumpForest(p::Integer; nt = 100, b = 10, np = 3)
    forest = [BinaryStump(np, b, sample(1:p, np; replace=false)) for i in 1:nt]
    BinaryStumpForest(forest)
end

function Base.show(io::IO, o::BinaryStumpForest)
    println(io, "BinaryStumpForest")
    for f in o.forest[1:10]
        println(io, "    ", f)
    end
    print(io, "         ⋮")
end

value(o::BinaryStumpForest) = value.(o.forest)

function fit!(o::BinaryStumpForest, xy, γ)
    i = rand(1:length(o.forest))  # TODO: other schemes for this randomization part
    fit!(o.forest[i], xy, γ)
end

function predict(o::BinaryStumpForest, x::VectorOb)
    mean(classify(stump, x) for stump in o.forest)
end
classify(o::BinaryStumpForest, x::VectorOb) = sign(predict(o, x))

for f in [:predict, :classify]
    @eval begin 
        function $f(o::BinaryStumpForest, x::AbstractMatrix, dim::Rows = Rows())
            mapslices(x -> $f(o, x), x, 2)
        end
        function $f(o::BinaryStumpForest, x::AbstractMatrix, dim::Cols)
            mapslices(x -> $f(o, x), x, 1)
        end
    end
end











