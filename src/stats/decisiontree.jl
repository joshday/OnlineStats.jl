hoeffding_bound(R, δ, n) = sqrt(R ^ 2 * -log(δ) / 2n)


#-----------------------------------------------------------------------# TreeNode 
mutable struct TreeNode{T, S} <: ExactStat{(1, 0)}
    nbc::NBClassifier{T, S}
    id::Int 
    split::Pair{Int, Float64}
    lr::Vector{Int}             # left and right children
end
TreeNode(args...) = TreeNode(NBClassifier(args...), 1, Pair(1, -Inf), Int[])

for f in [:nobs, :probs, :condprobs, :impurity, :predict, :classify, :nparams, 
          :impurity, :(Base.length)]
    @eval $f(o::TreeNode, args...) = $f(o.nbc, args...)
end

Base.keys(o::TreeNode) = keys(o.nbc)
Base.show(io::IO, o::TreeNode) = print(io, "TreeNode with ", o.nbc)
fit!(o::TreeNode, xy, γ) = fit!(o.nbc, xy, γ)
haschildren(o::TreeNode) = length(o.lr) > 0

function go_to_node(tree::Vector{<:TreeNode}, x::VectorOb)
    i = 1
    while haschildren(tree[i])
        o = tree[i]
        if x[first(o.split)] < last(o.split)
            i = o.lr[1]
        else
            i = o.lr[2]
        end
    end
    return i
end

# TODO: Hoeffding bound
function shouldsplit(o::TreeNode)
    nobs(o) > 10_000
end

# get best split for each variable: Vector of Pair(impurity, x)
function top_IGs(leaf::TreeNode, impurity = entropybase2)
    imp = impurity(probs(leaf))
    out = Pair{Float64, Float64}[]
    for j in 1:nparams(leaf)
        tsplits = trysplits(leaf.nbc, j)
        imps = Float64[]
        for x in tsplits
            n1, n2 = split_nobs(leaf.nbc, j, x)
            n1sum = sum(n1)
            n2sum = sum(n2)
            imp_l = impurity(n1 ./ sum(n1sum))
            imp_r = impurity(n2 ./ sum(n2sum))
            γ = n2sum / (n1sum + n2sum)
            push!(imps, smooth(imp_l, imp_r, γ))
        end
        maximp, k = findmax(imps)
        push!(out, Pair(maximp, tsplits[k]))
    end
    imp .- out
end

#-----------------------------------------------------------------------# CTree 
# TODO: options like minsplit, etc.
# TODO: Loss matrix
struct CTree{T, S} <: ExactStat{(1, 0)}
    tree::Vector{TreeNode{T, S}}
    maxsize::Int
end
function CTree(p::Integer, T::Type; maxsize::Int = 25)
    CTree([TreeNode(p * Hist(10), T)], maxsize)
end
function Base.show(io::IO, o::CTree)
    print_with_color(:green, io, "CTree of size $(length(o.tree))\n")
    for node in o.tree
        print(io, "  > ", node)
    end
end

get_leaf(o::CTree, x) = o.tree[go_to_node(o.tree, x)]

function fit!(o::CTree, xy, γ) 
    x, class = xy
    leaf = get_leaf(o, x)
    fit!(leaf, xy, γ)
    if length(o.tree) < 25 && shouldsplit(leaf) # TODO: user-defined max tree size
        igs = top_IGs(leaf)
        ab = sortperm(igs)[1:2]  # Top 2 information gains
        @show first(ab) - last(ab)
        error("HI")
    end
end


predict(o::CTree, x::VectorOb) = predict(get_leaf(o, x), x)
classify(o::CTree, x::VectorOb) = classify(get_leaf(o, x), x)

for f in [:predict, :classify]
    @eval begin 
        function $f(o::CTree, x::AbstractMatrix, dim::Rows = Rows())
            mapslices(x -> $f(o, x), x, 2)
        end
        function $f(o::CTree, x::AbstractMatrix, dim::Cols)
            mapslices(x -> $f(o, x), x, 1)
        end
    end
end
