


# mutable struct NumericalDist{T}
#     value::Vector{T}
#     nobs::Int
# end
# function fit!(o::NumericalDist, y, γ)
#     o.nobs += 1
#     if o.nobs < length(o.value)
#         o.value[o.nobs] = y
#     elseif o.nobs == length(o.value)
#         o.value[o.nobs] = y
#         sort!(o.value)
#     end
# end

# #-----------------------------------------------------------------------# Group with nobs
# mutable struct NGroup{G}
#     nobs::Int 
#     group::G 
# end 
# NGroup(g::Group) = NGroup(0, g)
# function fit!(o::NGroup, x)
#     o.nobs += 1
#     fit!(o.group, x, 1 / o.nobs)
#     o
# end
# Base.copy(o::NGroup) = deepcopy(o)

# #-----------------------------------------------------------------------# GroupBy 
# struct GroupBy{T, G <: NGroup, F} <: ExactStat{(1, 0)}
#     value::Dict{T, G}
#     init::F
# end
# function GroupBy(T::Type, init::Function) 
#     g = init()
#     GroupBy(Dict{T, NGroup{typeof(g)}}(), init)
# end

# function Base.show(io::IO, o::GroupBy)
#     print(io, "GroupBy: ", length(o.value), " groups")
# end
# function fit!(o::GroupBy, xy, γ)
#     x, y = xy
#     if haskey(o.value, y)
#         fit!(o.value[y], x)
#     else
#         o.value[y] = fit!(NGroup(o.init()), x)
#     end
# end





# #-----------------------------------------------------------------------# StatMap
# struct StatMap{T, G} <: ExactStat{(1, 0)}

# end


# #-----------------------------------------------------------------------# StatMap 
# struct GroupMap{T, G} <: OnlineStat{(1,0)}
#     value::Dict{T, G}
#     init::G
# end
# GroupMap(T::Type, g::G) where {G<:Group} = GroupMap(Dict{T, G}(), g)

# function fit!(o::GroupMap, xy, γ)
#     x, y = xy 
#     if haskey(o.value, y)
#         stat = o.value[y]
#         fit!(stat, x, 1 )
#     end
# end


# StatMap(T::Type, stat::O) where {O} = StatMap(Dict{T,Pair{Int, O}}(), stat)
# default_weight(o::StatMap) = default_weight(o.init)
# function Base.show(io::IO, o::StatMap) 
#     print(io, "StatMap: (", length(o.value), " Levels) × (", length(o.init), " Stats)")
#     print(io, " | ", name(o.init))
# end

# function fit!(o::StatMap, xy::XyOb, γ)
#     x, y = xy
#     if haskey(o.value, y)
#         n, stat = o.value[y]
#         n += 1
#         fit!(stat, x, 1 / n)
#         o.value[y] = Pair(n, stat)
#     else
#         stat = copy(o.init)
#         fit!(stat, x, 1.0)
#         o.value[y] = Pair(1, stat)
#     end
# end