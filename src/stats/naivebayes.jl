#-----------------------------------------------------------------------# NBClassifier 
export NBClassifier

struct NBClassifier{T, G <: Group} <: ExactStat{(1, 0)}
    d::OrderedDict{T, G}  # class => group
    init::G        # empty group
end
NBClassifier(T::Type, g::G) where {G<:Group} = NBClassifier(OrderedDict{T,G}(), g)
NBClassifier(g::Group, T::Type) = NBClassifier(T, g)
function NBClassifier(labels::Vector{T}, g::G) where {T, G<:Group} 
    NBClassifier(OrderedDict{T, G}(lab=>copy(g) for lab in labels), g)
end 
NBClassifier(p::Int, T::Type, b=20) = NBClassifier(T, p * Hist(b))


function Base.show(io::IO, o::NBClassifier)
    println(io, name(o))
    sd = sort(o.d)
    for di in sd
        print(io, "    > ", first(di), " (", round(nobs(last(di)) / nobs(o), 4), ")")
    end
end

Base.keys(o::NBClassifier) = keys(o.d)
Base.values(o::NBClassifier) = values(o.d)
Base.haskey(o::NBClassifier, y) = haskey(o.d, y)
nvars(o::NBClassifier) = length(o.init)
nkeys(o::NBClassifier) = length(o.d)
nobs(o::NBClassifier) = sum(nobs, values(o))
probs(o::NBClassifier) = [nobs(g) for g in values(o)] ./ nobs(o)
Base.getindex(o::NBClassifier, j) = [stat[j] for stat in values(o)]

# d is an object that iterates keys in known order
function index_to_key(d, i)
    for (k, ky) in enumerate(keys(d))
        k == i && return ky 
    end
end

function fit!(o::NBClassifier, xy, γ)
    x, y = xy 
    if haskey(o, y)
        g = o.d[y]
        fit!(g, x, 1 / (nobs(g) + 1))
    else 
        o.d[y] = fit!(copy(o.init), x, 1.0)
    end
end
entropy(o::NBClassifier) = entropy(probs(o), 2)

function predict(o::NBClassifier, x::VectorOb, p = zeros(nkeys(o)), n = nobs(o))
    for (k, gk) in enumerate(values(o))
        # P(Ck)
        p[k] = log(nobs(gk) / n + ϵ) 
        # P(xj | Ck)
        for j in eachindex(x)
            p[k] += log(_pdf(gk[j], x[j]) + ϵ)
        end
        p[k] = exp(p[k])
    end
    sp = sum(p)
    sp == 0.0 ? p : p ./= sum(p)
end
function classify(o::NBClassifier, x::VectorOb, p = zeros(nkeys(o)), n = nobs(o)) 
    _, k = findmax(predict(o, x, p, n))
    index_to_key(o, k)
end
function classify_node(o::NBClassifier)
    _, k = findmax([nobs(g) for g in values(o)])
    index_to_key(o, k)
end
for f in [:predict, :classify]
    @eval begin 
        function $f(o::NBClassifier, x::AbstractMatrix, ::Rows = Rows())
            n = nobs(o)
            p = zeros(nkeys(o))
            mapslices(xi -> $f(o, xi, p, n), x, 2)
        end
        function $f(o::NBClassifier, x::AbstractMatrix, ::Cols)
            n = nobs(o)
            p = zeros(nkeys(o))
            mapslices(xi -> $f(o, xi, p, n), x, 1)
        end
    end
end

function split(o::NBClassifier)
    nroot = [nobs(g) for g in values(o)]
    nleft = copy(nroot)
    nright = copy(nroot)
    split = NBSplit(length(nroot))
    entropy_root = entropy(o)
    for j in 1:nvars(o)
        ss = o[j]
        stat = merge(ss)
        for loc in split_candidates(stat)
            for k in 1:nkeys(o)
                nleft[k] = round(Int, n_sent_left(ss[k], loc))
            end
            entropy_left = entropy(nleft ./ sum(nleft))
            @. nright = nroot - nleft
            entropy_right = entropy(nright ./ sum(nright))
            entropy_after = smooth(entropy_right, entropy_left, sum(nleft) / sum(nroot))
            ig = entropy_root - entropy_after
            if ig > split.ig
                split.j = j
                split.at = loc
                split.ig = ig 
                split.nleft .= nleft
            end
        end
    end
    left = NBClassifier(collect(keys(o)), o.init)
    right = NBClassifier(collect(keys(o)), o.init)
    for (i, g) in enumerate(values(left.d))
        g.nobs = split.nleft[i]
    end
    for (i, g) in enumerate(values(right.d))
        g.nobs = nroot[i] - split.nleft[i]
    end
    o, split, left, right
end

n_sent_left(o::Union{OrderStats, Hist}, loc) = sum(o, loc)
n_sent_left(o::CountMap, label) = o[label]

#-----------------------------------------------------------------------# NBSplit
# Continuous:  x[j] < at 
# Categorical: x[j] == at
mutable struct NBSplit{}
    j::Int 
    at::Any
    ig::Float64 
    nleft::Vector{Int}
end
NBSplit(n=0) = NBSplit(0, -Inf, -Inf, zeros(Int, n))

whichchild(o::NBSplit, x) = x[o.j] < o.at ? 1 : 2

#-----------------------------------------------------------------------# NBNode
mutable struct NBNode{T <: NBClassifier} <: ExactStat{(1, 0)}
    nbc::T
    id::Int 
    parent::Int 
    children::Vector{Int}
    split::NBSplit
end
function NBNode(o::NBClassifier; id = 1, parent = 0, children = Int[], split = NBSplit()) 
    NBNode(o, id, parent, children, split)
end
function Base.show(io::IO, o::NBNode)
    print(io, "NBNode ", o.id)
    if o.split.j > 0
        print(io, " (split on $(o.split.j)")
    end
end

#-----------------------------------------------------------------------# NBTree 
mutable struct NBTree{T<:NBNode} <: ExactStat{(1, 0)}
    tree::Vector{T}
    maxsize::Int
    minsplit::Int
end
function NBTree(o::NBClassifier; maxsize = 5000, minsplit = 1000)
    NBTree([NBNode(o)], maxsize, minsplit)
end
NBTree(args...; kw...) = NBTree(NBClassifier(args...); kw...)
function Base.show(io::IO, o::NBTree)
    print(io, "NBTree(size = $(length(o.tree)), minsplit=$(o.minsplit))")
end

function fit!(o::NBTree, xy, γ)
    x, y = xy 
    i, node = whichleaf(o, x)
    fit!(node.nbc, xy, γ)
    if length(o.tree) < o.maxsize && nobs(node.nbc) >= o.minsplit 
        nbc, spl, left_nbc, right_nbc = split(node.nbc)
        # if spl.ig > o.cp
            node.split = spl
            node.children = [length(o.tree) + 1, length(o.tree) + 2]
            t = length(o.tree)
            left =  NBNode(left_nbc,  id = t + 1, parent = i)
            right = NBNode(right_nbc, id = t + 2, parent = i)
            push!(o.tree, left)
            push!(o.tree, right)
        # end
    end
end

function whichleaf(o::NBTree, x::VectorOb)
    i = 1 
    node = o.tree[i]
    while length(node.children) > 0
        i = node.children[whichchild(node.split, x)]
        node = o.tree[i]
    end
    i, node
end

function classify(o::NBTree, x::VectorOb)
    i, node = whichleaf(o, x)
    classify_node(node.nbc)
end
function classify(o::NBTree, x::AbstractMatrix)
    mapslices(xi -> classify(o, xi), x, 2)
end