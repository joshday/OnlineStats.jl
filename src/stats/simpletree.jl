#-----------------------------------------------------------------------# SimpleLabel
mutable struct SimpleLabel{T}
    label::T 
    stats::MV{Variance}
    nobs::Int
end
SimpleLabel(p::Integer, label) = SimpleLabel(label, p * Variance(), 0)
nobs(o::SimpleLabel) = o.nobs
function fit!(o::SimpleLabel, xy, γ)
    x, y = xy 
    y == o.label || error("Label doesn't match")
    o.nobs += 1
    w = 1 / o.nobs
    fit!(o.stats, x, w)
end
function Base.show(io::IO, o::SimpleLabel)
    print(io, "SimpleLabel(label=$(o.label), nobs=$(o.nobs))")
end
label(o::SimpleLabel) = o.label

#-----------------------------------------------------------------------# SimpleNode 
struct SimpleNode{T, F} <: ExactStat{(1,0)}
    value::Vector{SimpleLabel{T}}
    p::Int 
    id::Int
    leftright::Vector{Int}
    impurity::F
end
function SimpleNode(p::Integer, T::Type) 
    SimpleNode(SimpleLabel{T}[], p, 1, Int[], entropybase2)
end

function Base.show(io::IO, o::SimpleNode)
    println(io, "SimpleNode:")
    println(io, "  > probs:    ")
    for (ki, pi) in zip(keys(o), probs(o))
        print(io, ki, "(", pi, ")")
    end
    println(io, "  > id:       ", o.id)
    length(o.leftright) > 0 && println(io, "  > children: ", o.leftright)
    print(io, "  > impurtiy: ", o.impurity)
end

Base.keys(o::SimpleNode) = label.(o.value)
nobs(o::SimpleNode) = length(o.value)  == 0 ? 0 : sum(nobs, o.value)
probs(o::SimpleNode) = length(o.value) == 0 ? [0.0] : nobs.(o.value) ./ sum(nobs, o.value)
impurity(o::SimpleNode) = o.impurity(probs(o))
entropybase2(x) = entropy(x, 2)

# normal cdf
_cdf(μ, σ, x) = (1 + erf((x - μ) / σ)) / 2

function fit!(o::SimpleNode, xy, γ)
    x, y = xy 
    addlabel = true
    for v in o.value
        if v.label == y
            fit!(v, xy, γ)
            addlabel = false 
            break
        end
    end
    if addlabel
        sl = SimpleLabel(o.p, y)
        fit!(sl, xy, γ)
        push!(o.value, sl)
    end
end






# # START HERE
# # impurity: function of probability vector

# impurity = x -> entropy(x, 2)




# _entropy(p) = entropy(p, 2) - entropy(1 .- p, 2)
# entropy(o::SimpleLabels) = _entropy(probs(o))

# function next_entropy(o::SimpleLabels, j, x)
#     priors = probs(o)
#     μs = [mean(o.value[k].stats[j]) for k in 1:length(o.value)]
#     σs = [std(o.value[k].stats[j]) for k in 1:length(o.value)]
#     _entropy(priors .* _cdf.(μs, σs, x))
# end

# # find where to attempt splits
# # TODO: something much, much smarter
# possible_splits(o::SimpleLabels, j) = midpoints([mean(v.stats[j]) for v in o.value])

# # returns (i, x, ig)
# function best_split(o::SimpleLabels)
#     ent = entropy(o)
#     IGs = zeros(length(possible_splits(o, 1)), o.p)
#     for j in 1:o.p 
#         ps = possible_splits(o, j)
#         for (i, xi) in enumerate(ps)
#             IGs[i, j] = ent - next_entropy(o, j, xi)
#         end
#     end
#     IGs
# end