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



# #-----------------------------------------------------------------------# PartLines 
# struct PartLines
#     o::Partition 
# end 
# @recipe function f(o::PartLines)
#     color --> :black 
#     alpha --> .1 
#     seriestype --> :vline
#     label --> "Parts ($(length(o.o.parts)))"
#     xlab --> "Nobs"
#     grid --> false
#     linewidth --> .5
#     # xlim --> (0, o.o.parts[end].start + o.o.parts[end].n)
#     [p.start for p in o.o.parts]
# end
# getx(o::Partition) = [p.start + p.n / 2 for p in o.parts]

#-----------------------------------------------------------------------# Partition
getxlim(o::Partition) = (0, o.parts[end].start + o.parts[end].n)
getxlim(o::IndexedPartition) = (o.parts[1].first, o.parts[end].last)

getx(o::Partition) = vcat(map(x -> [x.start, x.start + x.n, x.start + x.n], o.parts)...)
getx(o::IndexedPartition) = vcat(map(x -> [x.first, x.last, x.last], o.parts)...)

function gety(o::Partition, mapfun) 
    repeat(map(x -> mapfun(x.stat), o.parts), inner = 3)
end
function gety(o::IndexedPartition, mapfun) 
    map(x -> mapfun(x.stat), o.parts)
end

@recipe function f(o::AbstractPartition, mapfun = value; connect=false) 
    value(o)  # make sure IndexedPartition is sorted
    xlim --> getxlim(o)

    statname = name(o.parts[1].stat, false, false)
    labelbase = "$statname ($(length(o.parts)) Parts)"

    # get values
    ymap = gety(o, mapfun)
    x = getx(o)
    
    if first(ymap) isa ScalarOb 
        @series begin
            label --> labelbase 
            w --> 2 
            @show x
                if connect 
                for i in 3:3:length(x)
                    ymap[i] = ymap[i - 1]
                end 
            end
            x, ymap
        end
    elseif first(ymap) isa Tuple{VectorOb, VectorOb}  # Histogram (values, counts)
        @series begin
            values = to_plot_shape(first.(ymap))
            counts = to_plot_shape(last.(ymap))
            line_z --> counts 
            legend --> false
            colorbar --> true
            linewidth --> 2
            # color = :blues
            x, values
        end
    elseif first(ymap) isa VectorOb 
        p = length(first(ymap))
        if p == 2
            @series begin 
                y = to_plot_shape(ymap)
                fillto --> y[:, 2]
                fillalpha --> .4 
                label --> labelbase 
                w --> 0 
                x, y[:, 1]
            end 
        else
            @series begin
                w --> 2
                label --> [labelbase * " $i" for i in 1:p]
                x, to_plot_shape(ymap)
            end
        end
    end
end

# get plottable shape from value.(::Partition)
to_plot_shape(v::Vector) = v 

function to_plot_shape(v::Vector{<:VectorOb}) 
    lvec = length.(v)
    if all(lvec == length(v[1]))
        return [v[i][j] for i in eachindex(v), j in eachindex(v[1])]
    else
        n, p = length(v), maximum(lvec)
        out = fill(NaN, n, p)
        for i in 1:n 
            vi = v[i]
            for j in eachindex(vi)
                out[i, j] = vi[j]
            end
        end
        return out
    end
end

#-----------------------------------------------------------------------# Partition{<:CountMap}
@recipe function f(o::Partition{CountMap{T}}) where {T}
    xlim --> (0, o.parts[end].start + o.parts[end].n)
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
        linewidth --> 0
        seriestype --> :bar
        bar_width --> nobs.(o.parts)
        getx(o), to_plot_shape(map(x -> reverse(cumsum(probs(x.stat, reverse(lvls)))), o.parts))
    end
end