#-----------------------------------------------------------------------# Weight
@recipe function f(wt::Weight; nobs=50)
    xlab --> "Number of Observations"
    ylab --> "Weight Value"
    label --> name(wt)
    ylim --> (0, 1)
    w --> 2
    [wt(i) for i in 1:nobs]
end

#-----------------------------------------------------------------------# OnlineStat{0}
@recipe function f(o::OnlineStat{0})
    title --> "$(name(o)): $(round.(value(o), 5))"
    legend --> false
    axis --> false
    grid --> false
    zeros(0)
end

#-----------------------------------------------------------------------# (1, 0) residual plot
@recipe function f(o::OnlineStat{(1,0)}, x::AbstractMatrix, y::AbstractVector, dim::ObLoc = Rows())
    ylab --> "Residual"
    xlab --> "Observation Index"
    legend --> false
    @series begin
        linetype --> :scatter
        ŷ = predict(o, x, dim)
        eachindex(y), y - ŷ
    end
    @series begin
        linetype --> :hline
        [0]
    end
end

@recipe function f(o::Series{(1,0)}, x::AbstractMatrix, y::AbstractVector)
    for stat in stats(o)
        @series begin stat end
    end
end


#-----------------------------------------------------------------------# Series{0}
@recipe function f(s::Series)
    layout --> length(s.stats)
    for stat in s.stats
        @series begin stat end
    end
end

#-----------------------------------------------------------------------# CovMatrix
@recipe function f(o::CovMatrix)
    seriestype --> :heatmap
    cov(o)
end

#-----------------------------------------------------------------------# Hist 
@recipe f(o::Hist) = o.method

@recipe f(o::KnownBins) = Histogram(o.edges, o.counts, :left)

@recipe function f(o::AdaptiveBins)
    # mids(v) = [0.5 * (v[i] + v[i + 1]) for i = 1:length(v) - 1]
    # val = vcat(o.values[1], mids(o.values), o.values[end])
    # Histogram(val, o.counts, :left)
    linewidth --> 2
    seriestype --> :sticks
    value(o)
end

#-----------------------------------------------------------------------# MV
@recipe function f(s::MV)
    i = 1
    for stat in s.stats
        @series begin 
            title --> "Stat $i"
            stat 
        end
        i += 1
    end
end

#-----------------------------------------------------------------------# CountMap
@recipe function f(o::CountMap)
    seriestype --> :bar 
    collect(keys(o)), value(o)
end

#-----------------------------------------------------------------------# Partition 
struct PartLines
    o::Partition 
end 
@recipe function f(o::PartLines)
    color --> :black 
    alpha --> .1 
    seriestype --> :vline
    label --> "Parts"
    grid --> false
    x = [p.start for p in o.o.parts]
end
getx(o::Partition) = [p.start + p.n / 2 for p in o.parts]

@recipe function f(o::Partition, f = value)
    @series begin 
        title --> "Partition of $(length(o.parts)) Parts"
        label --> string(f) * " of " * name(o.parts[1].stat)
        getx(o), to_plot_shape(map(x -> f(x.stat), o.parts))
    end
    @series PartLines(o) 
end
to_plot_shape(v::Vector) = v 
to_plot_shape(v::Vector{<:Vector}) = [v[i][j] for i in 1:length(v), j in 1:length(v[1])]

@recipe function f(o::Partition{CountMap{T}}) where {T}
    lvls = T[]
    for p in o.parts
        for k in keys(p.stat)
            k ∉ lvls && push!(lvls, k)
        end
    end
    sort!(lvls)
    @series begin 
        title --> "Partition of $(length(o.parts)) Parts"
        label --> reshape(lvls, (1, length(lvls)))
        xlab --> "Nobs"
        seriestype --> :bar
        bar_width --> nobs.(o.parts)
        getx(o), to_plot_shape(map(x -> reverse(cumsum(probs(x.stat, lvls))), o.parts))
    end
end

