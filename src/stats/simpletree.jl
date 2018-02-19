mutable struct SimpleLab{T} <: ExactStat{(1, 0)}
    label::T 
    stats::MV{Variance}
    nobs::Int
end
SimpleLab(p::Integer, label) = SimpleLab(label, p * Variance(), 0)

function fit!(o::SimpleLab, xy, γ)
    x, y = xy 
    y == o.label || error("Label doesn't match")
    o.nobs += 1
    w = 1 / o.nobs
    fit!(o.stats, x, w)
end

struct SimpleLabels{T} <: ExactStat{(1,0)}
    value::Vector{SimpleLab{T}}
    p::Int
end
SimpleLabels(p::Integer, T::Type) = SimpleLabels(SimpleLab{T}[], p)

function fit!(o::SimpleLabels, xy, γ)
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
        sl = SimpleLab(o.p, y)
        fit!(sl, xy, γ)
        push!(o.value, sl)
    end
end

Base.keys(o::SimpleLabels) = [v.label for v in o.value]

function Base.show(io::IO, o::SimpleLabels)
    print(io, "SimpleLabels: $(keys(o))")
end

# TODO: find where to attempt splits
function possible_splits(o::SimpleLabels, i)
    dists = Variance[]
    for v in o.value 
        push!(dists, v.stats[i])
    end
    sort!(dists, lt = (x,y) -> mean(x) < mean(y))
    mean.(dists)
end