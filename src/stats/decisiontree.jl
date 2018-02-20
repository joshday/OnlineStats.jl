hoeffding_bound(R, δ, n) = sqrt(R ^ 2 * -log(δ) / 2n)


#-----------------------------------------------------------------------# TreeNode 
mutable struct TreeNode{T, S} <: ExactStat{(1, 0)}
    labels::NBClassifier{T, S}
    id::Int 
    split::Pair{Int, Float64}
    lr::Vector{Int}             # left and right
end
TreeNode(args...) = TreeNode(NBClassifier(args...), 1, Pair(1, -Inf), [1])

nobs(o::TreeNode) = node(o.labels)
probs(o::TreeNode) = probs(o.labels)
condprobs(o::TreeNode, x) = condprobs(o.labels, x)
impurity(o::TreeNode, args...) = impurity(o.labels, args...)
Base.keys(o::TreeNode) = keys(o.labels)
Base.show(io::IO, o::TreeNode) = print(io, "TreeNode with ", o.labels)
fit!(o::TreeNode, xy, γ) = fit!(o.labels, xy, γ)
haschildren(o::TreeNode) = length(o.lr) > 1

function go_to_node(tree::Vector{<:TreeNode}, x)
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

function shouldsplit(o::TreeNode)
    nobs(o) > 10_000
end

#-----------------------------------------------------------------------# CTree 
struct CTree{T, S} <: ExactStat{(1, 0)}
    tree::Vector{TreeNode{T, S}}
end
function CTree(p::Integer, T::Type)
    CTree([TreeNode(p * Hist(10), T)])
end
function Base.show(io::IO, o::CTree)
    print_with_color(:green, io, "CTree of size $(length(o.tree))\n")
    for node in o.tree
        print(io, "  > ", node)
    end
end
go_to_node(o::CTree, x) = go_to_node(o.tree, x)

function fit!(o::CTree, xy, γ) 
    x, class = xy
    i = go_to_node(o, x)
    fit!(o.tree[i], xy, γ)
end

predict(o::CTree, x::VectorOb) = predict(o.tree[go_to_node(o, x)], x)
classify(o::CTree, x::VectorOb) = classify(o.tree[go_to_node(o, x)], x)

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

# #-----------------------------------------------------------------------# Node
# # Type-stable decision tree node.
# mutable struct Node{T}
#     stat::NBClassifier{T}
#     split::Pair{Int, Float64}  # if x[split[1]] < split[2], go left to lr[1]
#     lr::Vector{Int}  # Vector indices of left and right split
#     id::Int
#     δ::Float64
# end
# function Node(p::Integer, T::Type, b::Integer; δ = .01) 
#     Node(NBClassifier(p, T, b), Pair(1, -Inf), [1], 1, δ)
# end

# function Base.show(io::IO, o::Node)
#     print_with_color(:green, io, "Node $(o.id): ")
#     if length(o.lr) == 1
#         kys = keys(o)
#         ps = probs(o)
#         for (key, p) in zip(kys, ps)
#             print(io, key, " ($p)")
#             key != kys[end] && print(io, " ▒ ")
#         end
#     else
#         print(io, "$(o.lr[1]) or $(o.lr[2]), by x$(o.split[1]) < $(o.split[2])")
#     end
# end

# goto(o::Node, x::VectorOb) = o.lr[Int(x[first(o.split)] < last(o.split)) + 1]
# function goto(v::Vector{<:Node}, x::VectorOb)
#     i = 1 
#     while length(v[i].lr) > 1
#         i = goto(v[i], x)
#     end
#     return i
# end

# function shouldsplit(o::Node) 
#     nobs(o) > 100_000  # TODO: be smarter
# end

# function bestsplit(o::Node)
#     kys = keys(o)
#     p = length(o)
#     split_options = zeros(p)
#     for j in 1:p
#         val = o.stat.value
#         μ_min, μ_max = extrema(mean(last(val[k]).stats[j]) for k in 1:length(kys))
#         split_options[j] = (μ_min + μ_max) / 2
#     end
# end

# Base.keys(o::Node) = keys(o.stat)
# probs(o::Node) = probs(o.stat)
# nobs(o::Node) = nobs(o.stat)
# Base.length(o::Node) = length(o.stat)

# #-----------------------------------------------------------------------# DTree
# # TODO: add loss matrix
# struct DTree{T} <: ExactStat{(1,0)}
#     tree::Vector{Node{T}}
# end
# function DTree(p::Integer, T::Type, b::Integer = 10)
#     DTree([Node(p, T, b)])
# end
# Base.show(io::IO, o::DTree) = print(io, "DTree of $(length(o.tree)) leaves")

# function fit!(o::DTree, xy::Tuple, γ::Float64)
#     x, y = xy
#     i = goto(o.tree, x)
#     node = o.tree[i]
#     stat = node.stat
#     fit!(stat, xy, γ)
#     if shouldsplit(node)
#         bestsplit(node)
#         # find best split for each predictor
#     end
# end
