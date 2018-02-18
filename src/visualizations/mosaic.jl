"""
    Mosaic(T::Type, S::Type)

Data structure for generating a mosaic plot, a comparison between two categorical variables.

# Example

    using OnlineStats, Plots 
    x = [rand() > .8 for i in 1:10^5]
    y = rand([1,2,2,3,3,3], 10^5)
    s = series([x y], Mosaic(Bool, Int))
    plot(s)
"""
struct Mosaic{T, S} <: ExactStat{1}
    value::Vector{Pair{T, CountMap{S}}}
end
Mosaic(T, S) = Mosaic(Pair{T, CountMap{S}}[])

Base.show(io::IO, o::Mosaic{T,S}) where {T, S} = print(io, "Mosaic: $T × $S")

nobs(o::Mosaic) = sum(nobs.(last.(value(o))))

function fit!(o::Mosaic{T,S}, xy::VectorOb, γ::Float64) where {T, S}
    x = first(xy)
    y = last(xy)
    pushx = true
    for (i, vi) in enumerate(o.value)
        if first(vi) == x 
            fit!(last(o.value[i]), y, γ)
            pushx = false 
            break
        end
    end
    if pushx 
        stat = CountMap(S)
        fit!(stat, y, γ)
        push!(o.value, Pair(x, stat))
    end
end

@recipe function f(o::Mosaic{T,S}) where {T,S}
    o.value[:] = o.value[sortperm(first.(o.value))]
    sort!.(last.(o.value))
    xlevels = first.(o.value)
    xwidths = nobs.(last.(o.value)) ./ sum(nobs.(last.(o.value)))
    xedges = vcat(0.0, cumsum(xwidths))

    ylevels = unique(vcat(keys.(last.(o.value))...))

    yheights = cumsum.(reverse.(probs.(last.(o.value), [ylevels])))

    y = hcat(reverse.(yheights)...)

    seriestype := :bar
    bar_widths := xwidths
    xlim := (0, 1)
    ylim := (0, 1)
    xticks := ([(xedges[i] + xedges[i+1])/2 for i in 1:length(xedges)-1], xlevels)
    labels := ylevels'

    xedges, y'
end