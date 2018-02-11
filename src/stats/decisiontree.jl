hoeffding_bound(R, δ, n) = sqrt(R ^ 2 * -log(δ) / 2n)

#-----------------------------------------------------------------------# Node
mutable struct Node{T}
    stat::NBClassifier{T}
    split::Pair{Int, Float64}  # if x[split[1]] < split[2], go left to lr[1]
    lr::Vector{Int}  # Vector indices of left and right split
    ind::Int
    δ::Float64
end
function Node(p::Integer, T::Type, b::Integer; δ = .01) 
    Node(NBClassifier(p, T, b), Pair(1, -Inf), [1], 1, δ)
end

function Base.show(io::IO, o::Node)
    print_with_color(:green, io, "Node $(o.ind): ")
    if length(o.lr) == 1
        kys = keys(o)
        ps = probs(o)
        for (key, p) in zip(kys, ps)
            print(io, key, " ($p)")
            key != kys[end] && print(io, " ▒ ")
        end
    else
        print(io, "$(o.lr[1]) or $(o.lr[2]), by x$(o.split[1]) < $(o.split[2])")
    end
end

function goto(o::Node, x::VectorOb)
    i, v = o.split
    ind = Int(x[i] < v) + 1
    o.lr[ind]  # getindex 1 or 2
end
function goto(v::Vector{<:Node}, x::VectorOb)
    i = 1
    while true 
        k = i 
        i = goto(v[i], x)
        if k == i 
            return i 
        end
    end
end

function shouldsplit(o::Node) 
    nobs(o) > 100_000 
end

function bestsplit(o::Node)
    kys = keys(o)
    p = length(o)
    split_options = zeros(p)
    for i in 1:p
        # try mean for each label 
        
    end
end

Base.keys(o::Node) = keys(o.stat)
probs(o::Node) = probs(o.stat)
nobs(o::Node) = nobs(o.stat)
Base.length(o::Node) = length(o.stat)

#-----------------------------------------------------------------------# DTree
# TODO: add loss matrix
struct DTree{T} <: ExactStat{(1,0)}
    tree::Vector{Node{T}}
end
function DTree(p::Integer, T::Type, b::Integer = 10)
    DTree([Node(p, T, b)])
end
Base.show(io::IO, o::DTree) = print(io, "DTree of $(length(o.tree)) leaves")

function fit!(o::DTree, xy::Tuple, γ::Float64)
    x, y = xy
    i = goto(o.tree, x)
    node = o.tree[i]
    stat = node.stat
    fit!(stat, xy, γ)
    if shouldsplit(node)
        # find best split for each predictor
    end
end

#-----------------------------------------------------------------------#
#-----------------------------------------------------------------------#
#-----------------------------------------------------------------------# NaiveTree
# Assume all distributions are normal 

# struct NaiveNode{T}
#     d::Dict{T, Variance}
#     split::Pair{Int, Float64}
#     lr::Vector{Int}
#     id::Int
# end
# function NaiveNode(p::Integer, T::Type) 
#     NaiveNode(Dict{T, Variance}, Pair(1, -Inf), [1], 1)
# end
