#-----------------------------------------------------------------------# BinarySplit
# Prediction:  x[j] < loc ? lab : -lab
struct BinarySplit
    j::Int 
    loc::Float64 
    lab::Float64
    ig::Float64  # information gain
end
# classify(o::BinarySplit, x::VectorOb) = x[o.j] < o.loc ? o.lab : -o.lab

#-----------------------------------------------------------------------# BinaryStump
# For each label, we store the "sufficient statistics" for each variable as a histogram
mutable struct BinaryStump <: ExactStat{(1, 0)}
    stats1::MV{Hist{0, AdaptiveBins{Float64}}} # summary statistics for class = -1
    stats2::MV{Hist{0, AdaptiveBins{Float64}}} # summary statistics for class = 1
    split::BinarySplit
    subset::Vector{Int}  # indices of the subset of features
end
function BinaryStump(p::Int, b::Int, subset) 
    BinaryStump(p * Hist(b), p * Hist(b), BinarySplit(0,0.0,0.0,0.0), collect(subset))
end

function Base.show(io::IO, o::BinaryStump)
    print(io, "BinaryStump:")
    if o.split.j > 0 
        y = o.split.lab
        xj = "x[$(o.subset[o.split.j])]"
        lt = y == -1 ? "<" : "≥"
        print(io, " -1 if $xj $lt ", round(o.split.loc, 3))
    else 
        print(io, " split not yet determined")
    end
end

# j, loc, lab
split(o::BinaryStump) = (o.subset[o.split.j], o.split.loc, o.split.lab)

nparams(o::BinaryStump) = length(o.stats1)
function probs(o::BinaryStump) 
    n = [nobs(first(o.stats1)), nobs(first(o.stats2))]
    n ./ sum(n)
end

value(o::BinaryStump) = make_split!(o)

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

# find split candidates based on histograms for each label
function split_candidates(h1, h2)
    # get endpoints of both histograms
    a = max(h1.value[1][1], h2.value[1][1])
    b = min(h1.value[end][1], h2.value[end][1])
    # midpoints of merged histograms
    out = midpoints(first.(merge(h1, h2).value))
    # only use midpoints that are in range of both histograms
    out[a .< out .< b]
end

function make_split!(o::BinaryStump)
    # calculate information gain for a lot of split candidates
    imp_root = impurity(probs(o))
    trials = BinarySplit[]
    for j in 1:nparams(o)
        h1 = o.stats1[j].alg 
        h2 = o.stats2[j].alg
        for loc in split_candidates(h1, h2)  # make setting
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

    # find the best split
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

After fitting, you must call `value` to calculate the splits!
"""
mutable struct BinaryStumpForest <: ExactStat{(1, 0)}
    forest::Vector{BinaryStump}
    p::Int
    n::Int
end
function BinaryStumpForest(p::Integer; nt = 1000, b = 50, np = round(Int, sqrt(p)))
    forest = [BinaryStump(np, b, sample(1:p, np; replace=false)) for i in 1:nt]
    BinaryStumpForest(forest, p, 0)
end

function Base.show(io::IO, o::BinaryStumpForest)
    println(io, "BinaryStumpForest")
    println(io, "  > First 5 stumps of $(length(o.forest))")
    for f in o.forest[1:5]
        println(io, "    ", f)
    end
    print(io, "         ⋮")
end

value(o::BinaryStumpForest) = value.(o.forest)
nparams(o::BinaryStumpForest) = o.p

function fit!(o::BinaryStumpForest, xy, γ)
    i = (o.n % length(o.forest)) + 1
    o.n += 1
    fit!(o.forest[i], xy, γ)
end

function predict(o::BinaryStumpForest, x::VectorOb)
    mean(classify(stump, x) for stump in o.forest)
end
classify(o::BinaryStumpForest, x::VectorOb) = sign(predict(o, x))



#-----------------------------------------------------------------------# BinaryStumpClassifier
# lt[j] -> vector of points xj* such that -1 is predicted if x[j] < xj*
# gt[j] -> vector of points xj* such that -1 is predicted if x[j] ≥ xj*
struct BinaryStumpClassifier 
    lt::Vector{Vector{Float64}}
    gt::Vector{Vector{Float64}}
end
function BinaryStumpClassifier(o::BinaryStumpForest)
    p = nparams(o)
    c = BinaryStumpClassifier([Float64[] for i in 1:p], [Float64[] for i in 1:p])
    for stump in o.forest 
        make_split!(stump)
        j, loc, lab = split(stump)
        if lab == -1
            push!(c.lt[j], loc)
        else
            push!(c.gt[j], loc)
        end
    end
    for j in eachindex(c.lt)
        sort!(c.lt[j])
        sort!(c.gt[j])
    end
    c
end

ntrees(o::BinaryStumpClassifier) = sum(length, o.lt) + sum(length, o.gt)

function Base.show(io::IO, o::BinaryStumpClassifier)
    print(io, name(o))
    nt = sum(length, o.lt) + sum(length, o.gt)
    for j in eachindex(o.lt)
        prop = (length(o.lt[j]) + length(o.gt[j])) / nt
        print(io, "\n    > ")
        if prop > 0
            perc = round(Int, prop * 100)
            for _ in 1:round(Int, prop  * 100)
                print(io, "■")
            end
            print(io, " Var $j ($(round(prop*100, 2)))%)")
        end
    end
end

function classify(o::BinaryStumpClassifier, x::VectorOb)
    nneg = 0
    for (ltj, gtj, xj) in zip(o.lt, o.gt, x)
        nneg += searchsortedfirst(ltj, xj) - 1  # number of -1s in lt
        nneg += searchsortedlast(gtj, xj)  # number of -1s in gt
    end
    nneg / ntrees(o) > .5 ? 1.0 : -1.0
end
function classify(o::BinaryStumpClassifier, x::AbstractMatrix, dim::Rows = Rows())
    mapslices(x -> classify(o, x), x, 2)
end
function classify(o::BinaryStumpClassifier, x::AbstractMatrix, dim::Cols)
    mapslices(x -> classify(o, x), x, 1)
end







