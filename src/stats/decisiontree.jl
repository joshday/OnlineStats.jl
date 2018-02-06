hoeffding_bound(R, δ, n) = sqrt(R ^ 2 * -log(δ) / 2n)



mutable struct Node{T} <: ExactStat{(1, 0)}
    nbc::NBClassifier{T}
    decisionrule
    left 
    right
    nobs::Int
    b::Int
end

function Node(p::Integer, labeltype::Type)
    Node(NBClassifier(p, labeltype), x -> 0, nothing, nothing, 0, 100)
end

function fit!(o::Node, xy::Tuple, γ::Float64)
    o.nobs += 1
    fit!(o.nbc, xy, γ)
    if o.decisionrule(o) == 0
        e = hoeffding_bound(log2(length(keys(o.nbc))), .01, o.nobs)
        # for j in 
    elseif o.decisionrule(o) == 1
        fit!(o.left, xy, γ)
    else
        fit!(o.right, xy, γ)
    end
end


struct DTree{T} <: ExactStat{(1,0)}
    nodes::Vector{NBClassifier{T}}
    leaf::Vector{Bool}
    rules::Vector
end
function DTree(p::Integer, T::Type)
    DTree([NBClassifier(p, T)], [true], [(o, x) -> 1])
end
Base.show(io::IO, o::DTree) = print(io, "DTree of $(length(o.nodes)) leaves")

function fit!(o::DTree, xy::Tuple, γ::Float64)
    x, y = xy 
    i = find_node(o, x)
    fit!(o.nodes[i], xy, γ)
    if nobs(o.nodes[i]) % 1000 == 0  # make split
        for j in eachindex(x)
            
        end
    end
end

function find_node(o::DTree, x::VectorOb)
    isleaf = false
    i = 1
    while !isleaf
        if !o.leaf[i]  # if it's not a leaf, apply next rule
            i = o.rules[i](o, x)
        else
            isleaf = true
        end
    end
    i
end


# #-----------------------------------------------------------------------# Description
# # x1 => IndexedPartition(LabelType, SummaryType1)
# # x2 => IndxedPartition(LabelType, SummaryType2)
# # ...

# struct Node{C, T} <: ExactStat{(1, 0)}
#     summary::T
#     left::C
#     right::C
# end
# function Node(T::Type, summaries::OnlineStat{0}...; left=nothing, right=nothing)
#     Node(IndexedPartition.(T, summaries), left, right)
# end
# function Base.show(io::IO, o::Node{C, T}) where {C, T}
#     print(io, name(o, false, false), "($(index_type(o.summary[1])) label, ", length(o.summary), " summaries)")
# end
# function fit!(o::Node, xy::XyOb, γ::Float64)
#     x, label = xy
#     for i in eachindex(o.summary)
#         fit!(o.summary[i], (label, x[i]), γ)
#     end
# end


# struct BTree{T}
#     dict
#     left::T
#     right::T
# end
# function fit!(o::BTree, x, y)
#     if haskey(o.dict, y)
#         o.dict[y]
#     end
# end

# find_node(o::BTree{Void}) = o 
# function find_node(o::BTree, x::VectorOb)
#     goleft ? find_node(o.left, x) : find_node(o.right, x)
# end




# mutable struct VFDT{T} <: ExactStat{(1, 0)}
#     stat_schema::T
#     root::BTree
# end
# function VFDT(stat_schema)
#     VFDT(stat_schema, BTree(Dict(), nothing, nothing))
# end
# Base.show(io::IO, o::VFDT) = print(io, "VFDT: $(name.(o.stat_schema, false, false))")
# function fit!(o::VFDT, xy::XyOb, γ::Float64)
#     x, y = xy
#     node = find_node(o.root, x)
# end






# #-----------------------------------------------------------------------# OLD
# # Review paper:
# # https://people.cs.umass.edu/~utgoff/papers/mlj-id5r.pdf

# # abstract type DecisionTreeAlgorithm end

# # mutable struct Node{T, F <: Function}
# #     counts::CountMap{T}
# #     impurity::F
# # end
# # function Node(T::Type, impurity = p -> entropy(p, 2)) 
# #     Node(CountMap(T), impurity)
# # end
# # function Base.show(io::IO, o::Node)
# #     print_with_color(:green, io, "Node\n")
# #     println(io, "  > impurity: ", o.impurity)
# #     print(  io, "  > counts:   ", o.counts)
# # end

# # probs(o::Node) = collect(values(o)) ./ sum(values(o))



# # #-----------------------------------------------------------------------# DecisionTree
# # mutable struct DecisionTree{T <: DecisionTreeAlgorithm} <: ExactStat{(1, 0)}
# #     alg::T
# # end
# # DecisionTree(args...) = DecisionTree(VFDT(args...))

# # function Base.show(io::IO, o::DecisionTree)
# #     print_with_color(:green, io, "DecisionTree: ")
# #     print(io, o.alg)
# # end

# # fit!(o::DecisionTree, xy::Tuple{VectorOb, Any}, γ::Float64) = fit!(o.alg, xy, γ)


# # #-----------------------------------------------------------------------# VFDT 
# # # https://homes.cs.washington.edu/~pedrod/papers/kdd00.pdf

# # # Hoeffding Tree Node
# # mutable struct HNode{T}
# #     ss::Vector{CountMap{T}}
# #     children
# # end
# # HNode(T) = HNode(CountMap{T}[], nothing)

# # function Base.show(io::IO, o::HNode)
# #     print_with_color(:green, io, name(o))
# #     println(io)
# #     n_att = length(o.ss)
# #     println(io, "  > N Attributes: ", n_att)
# #     print(io,   "  > Children:     ", o.children)
# # end

# # struct VFDT{G, T} <: DecisionTreeAlgorithm
# #     g::G        # split evaluation function 
# #     δ::Float64  # 1 - δ = desired probability of choosing correct attribute to split on
# #     tree::HNode{T}
# # end
# # VFDT(T, δ::Float64 = .01) = VFDT(information_gain, δ, HNode(T))

# # function Base.show(io::IO, o::VFDT{G, T}) where {G, T}
# #     print_with_color(:green, io, "VFDT")
# #     println(io)
# #     println(io, "  > Label Type    : ", T)
# #     println(io, "  > Split Criteria: ", o.g)
# #     println(io, "  > δ             : ", o.δ)
# #     print(  io, "  > Tree Size     : ", "???")
# # end

# # # attribute selection measures (TODO)
# # function information_gain end
# # function gini_index end

# # # helpers 
# # 

# # # assume x is a Tuple
# # function fit!(o::VFDT, xy::Tuple{VectorOb, Any}, γ::Float64)

# # end