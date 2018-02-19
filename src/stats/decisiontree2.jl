#-----------------------------------------------------------------------# 
struct ConditionalStat{T, OS}
    label::T 
    stat::OS
end


#-----------------------------------------------------------------------# ColSS
struct ColSS{L, T}
    dict::SortedDict{L, Pair{Int, T}}  # key => Pair(nobs, stat)
    empty_stat::T
end
ColSS(L::Type, stat::T) where {T} = ColSS(SortedDict{L, Pair{Int, T}}(), copy(stat))
Base.show(io::IO, o::ColSS) = print(io, name(o), " with $(length(o.dict)) labels")

Base.getindex(o::ColSS{L}, label::L) where {L} = o.dict[label]

function fit!(o::ColSS{L}, label::L, x) where {L}
    addlabel = true 
    for (ky, val) in o.dict
        if label == ky
            pr = o.dict[ky]

            o.dict[ky] = Pair(first(pr) + 1, )
        end
    end
    for (i, v) in enumerate(o.labels)
        if label == v 
            n = (o.nobs[i] += 1)
            fit!(o.stats[i], x, 1 / n)
            addlabel = false 
            break
        end
    end
    if addlabel 
        stat = copy(o.empty_stat)
        fit!(stat, x, 1.0)
        push!(o.stats, stat)
        push!(o.labels, label)
        push!(o.nobs, 1)
    end
end

# #-----------------------------------------------------------------------# SimpleNode 
# # Same stat for each column
# struct SimpleNode{L, T}
#     ss::Vector{ColSS{L, T}}
# end
# function fit!(o::SimpleNode{L}, label::L, x::VectorOb)
#     for (ssi, xi) in zip(o.ss, x)
#         fit!(ssi, label, xi)
#     end
# end

#-----------------------------------------------------------------------# DTree