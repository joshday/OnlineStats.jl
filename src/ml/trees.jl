# Hard part about trees:  need to know bivariate relationship between y and every x variable.

struct TreeVariable{T,S}
    
end

#-----------------------------------------------------------------------------# ClassificationTreeNode 
struct ClassificationTreeNode{L, G<:Group} <: OnlineStat{XY}
    labelstats::Dict{L, G}
    split::Union{Nothing, }
    left::Union{Nothing, ClassificationTreeNode}
    right::Union{Nothing, ClassificationTreeNode}
    depth::Int
    n::Int
end



# #-----------------------------------------------------------------------------# RegressionTree 
# mutable struct RegressionTree 
#     tree::RegressionTreeNode 
#     depth::Int
#     n::Int
# end

# function _fit!(o::RegressionTree, xy)
#     _fit!(o.tree, )
# end

# #-----------------------------------------------------------------------------# Split 
# mutable struct Split 

# end

#-----------------------------------------------------------------------------# RegressionTreeNode
mutable struct RegressionTreeNode{G <: Group, EH<:ExpandingHist} <: OnlineStat{XY}
    left_data::EH
    right_data::EH
    left_stats::G 
    right_stats::G 
    split::Union{Nothing, Split}
    left::Union{Nothing, RegressionTreeNode}
    right::Union{Nothing, RegressionTreeNode}
end
nobs(o::RegressionTreeNode) = nobs(o.left_data) + nobs(o.right_data)
isleaf(o::RegressionTreeNode) = isnothing(o.left)
