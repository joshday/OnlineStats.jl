# Review paper:
# https://people.cs.umass.edu/~utgoff/papers/mlj-id5r.pdf

abstract type DecisionTreeAlgorithm end

mutable struct Node{T, F <: Function}
    pmk::CountMap{T}
    impurity::F
end
probs(o::Node) = collect(values(o)) ./ sum(values(o))



#-----------------------------------------------------------------------# DecisionTree
mutable struct DecisionTree{T <: DecisionTreeAlgorithm} <: ExactStat{(1, 0)}
    alg::T
end
DecisionTree(args...) = DecisionTree(VFDT(args...))

function Base.show(io::IO, o::DecisionTree)
    print_with_color(:green, io, "DecisionTree: ")
    print(io, o.alg)
end

fit!(o::DecisionTree, xy::Tuple{VectorOb, ScalarOb}, γ::Float64) = fit!(o.alg, xy, γ)


#-----------------------------------------------------------------------# VFDT 
# https://homes.cs.washington.edu/~pedrod/papers/kdd00.pdf

# Hoeffding Tree Node
mutable struct HNode{T}
    ss::Vector{CountMap{T}}
    children
end
HNode(T) = HNode(CountMap{T}[], nothing)

function Base.show(io::IO, o::HNode)
    print_with_color(:green, io, name(o))
    println(io)
    n_att = length(o.ss)
    println(io, "  > N Attributes: ", n_att)
    print(io,   "  > Children:     ", o.children)
end

struct VFDT{G, T} <: DecisionTreeAlgorithm
    g::G        # split evaluation function 
    δ::Float64  # 1 - δ = desired probability of choosing correct attribute to split on
    tree::HNode{T}
end
VFDT(T, δ::Float64 = .01) = VFDT(information_gain, δ, HNode(T))

function Base.show(io::IO, o::VFDT{G, T}) where {G, T}
    print_with_color(:green, io, "VFDT")
    println(io)
    println(io, "  > Label Type    : ", T)
    println(io, "  > Split Criteria: ", o.g)
    println(io, "  > δ             : ", o.δ)
    print(  io, "  > Tree Size     : ", "???")
end

# attribute selection measures (TODO)
function information_gain end
function gini_index end

# helpers 
hoeffding_bound(R, δ, n) = sqrt(R ^ 2 * -log(δ) / 2n)

# assume x is a Tuple
function fit!(o::VFDT, xy::Tuple{VectorOb, ScalarOb}, γ::Float64)

end





# # mutable struct Node{T} 
# #     children::Vector{Node} 
# #     categories::CountMap{T}
# #     ig::Vector{Float64}  # buffer for information gain 
# #     n_instance::Vecto
# # end
# # Node(T) = Node(Node[], CountMap(T), Float64[])

# # function _I(x, y)
# #     if x == 0
# #         return 0.0
# #     elseif y == 0
# #         return 0.0
# #     else
# #         xpy = x + y 
# #         a = x / xpy 
# #         b = y / xpy
# #         return -a * log(a) - b * log(b)
# #     end
# # end

# # function ig!(node::Node, xy::Tuple{VectorOb, ScalarOb})
# #     x, y = xy 
# #     if length(node.ig) != length(x)
# #         node.ig = zeros(length(x))
# #     end
# #     denom = sum(values(node.categories))
# #     for j in eachindex(x)

# #     end
# # end







# # #-----------------------------------------------------------------------# ID4
# # struct ID4 <: DecisionTreeAlgorithm end 

# # function fit!(o::DecisionTree{ID4}, xy::Tuple{<:VectorOb, <:ScalarOb}, γ::Float64)

# # end
