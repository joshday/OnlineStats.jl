# # https://people.cs.umass.edu/~utgoff/papers/mlj-id5r.pdf

# abstract type DecisionTreeAlgorithm end

# #-----------------------------------------------------------------------# DecisionTree
# """
#     DecisionTree(LabelType, alg = ID4())

# Create a decision tree where labels have type `LabelType` via the incremental algorithm 
# `alg`.
# """
# mutable struct DecisionTree{T <: DecisionTreeAlgorithm, S} <: ExactStat{(1, 0)}
#     alg::T
#     categories::CountMap{S}
# end
# DecisionTree(T, alg = ITI()) = DecisionTree(alg, CountMap(T), Node(T))

# #-----------------------------------------------------------------------# ITI 
# struct ITI <: DecisionTreeAlgorithm 
# end



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
