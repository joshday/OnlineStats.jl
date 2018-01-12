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
    legend --> false
    axis --> false
    # grid --> false
    ylim --> (0, 1)
    xlim --> (0, 1)
    annotations --> [(.5, .75, name(o)), (.5, .25, string(value(o)))] #), .1, .2, string(value(o))]
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


#-----------------------------------------------------------------------# Series
@recipe function f(s::Series)
    if :layout in keys(plotattributes)
        for stat in s.stats
            @series begin stat end
        end 
    else  # hack to ensure series aren't sent to wrong subplots
        layout --> length(s.stats)
        for i in eachindex(s.stats)
            @series begin 
                subplot --> i 
                s.stats[i]
            end
        end
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
@recipe function f(o::MV)
    i = 1
    layout --> length(o.stats)
    for stat in o.stats
        @series begin 
            title --> "Stat $i"
            stat 
        end
        i += 1
    end
end

#-----------------------------------------------------------------------# Group 
@recipe function f(o::Group)
    for stat in o.stats 
        @series begin 
            stat
        end
    end
end

#-----------------------------------------------------------------------# CountMap
@recipe function f(o::CountMap)
    seriestype --> :bar 
    collect(keys(o)), collect(values(o))
end


#-----------------------------------------------------------------------# Partition 
@recipe function f(o::Partition, mapfun = value)
    ymap = map(x -> mapfun(x.stat), o.parts)
    x = map(x -> x.start + x.n/2, o.parts)
    nvec = nobs.(o.parts)
    xlab --> "Nobs"

    if first(ymap) isa ScalarOb
            label --> name(o.parts[1].stat, false, false)
            x, ymap
    elseif first(ymap) isa Tuple{VectorOb, VectorOb}
        realx, y, z = Float64[], Float64[], Float64[]
        for i in eachindex(ymap)
            values, counts = ymap[i]
            for j in eachindex(values)
                push!(realx, x[i])
                push!(y, values[j])
                push!(z, counts[j])
            end
        end
        label --> name(o.parts[1].stat, false, false)
        seriestype --> :scatter 
        marker_z --> z
        markerstrokewidth --> 0
        realx, y
    elseif first(ymap) isa VectorOb 
        y = to_plot_shape(ymap)
        label --> name(o.parts[1].stat, false, false)
        if length(first(ymap)) == 2
            fillto --> y[:, 2]
            fillalpha --> .6
            linewidth --> 0
            x, y[:, 1]
        else 
            x, y
        end
    elseif first(ymap) isa Dict 
        lvls = []
        for p in o.parts
            for k in keys(p.stat)
                k ∉ lvls && push!(lvls, k)
            end
        end
        sort!(lvls)
        label --> reshape(lvls, (1, length(lvls)))
        linewidth --> 0
        seriestype --> :bar
        bar_width --> nobs.(o.parts)
        x, to_plot_shape(map(x -> reverse(cumsum(probs(x.stat, reverse(lvls)))), o.parts))
    end
end

to_plot_shape(v::Vector) = v 
to_plot_shape(v::Vector{<:VectorOb}) = [v[i][j] for i in eachindex(v), j in 1:length(v[1])]


#-----------------------------------------------------------------------# IndexedPartition
@recipe function f(o::IndexedPartition, mapfun = value)

end