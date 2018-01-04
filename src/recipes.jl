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
    collect(keys(o)), value(o)
end

# #-----------------------------------------------------------------------# Partition 
# @recipe function f(o::Partition, f::Function = value) 
#     legend --> false
#     color --> :black
#     xlab --> "Nobs"
#     title --> "Partition of $(length(o.parts)) Parts: $(name(o.parts[1].stat))"
#     for part in o.parts
#         @series begin part, f end
#     end
#     # reshape(o.parts, (1, length(o.parts)))
# end

# @recipe function f(o::Part, f::Function = value)
#     v = f(o.stat)
#     x = [o.start, o.start + o.n]
#     if v isa ScalarOb 
#         @series begin 
#             x, [v, v]
#         end
#     elseif v isa VectorOb 
#         v2 = reshape(v, (1, length(v)))
#         @series begin 
#             x, repmat(v2, 2, 1)
#         end
#     else
#         error("3D Partition plots not supported yet")
#     end
# end

#-----------------------------------------------------------------------# PartLines 
struct PartLines
    o::Partition 
end 
@recipe function f(o::PartLines)
    color --> :black 
    alpha --> .1 
    seriestype --> :vline
    label --> "Parts"
    xlab --> "Nobs"
    title --> "Partition of $(length(o.o.parts)) Parts"
    grid --> false
    linewidth --> .5
    # xlim --> (0, o.o.parts[end].start + o.o.parts[end].n)
    [p.start for p in o.o.parts]
end
getx(o::Partition) = [p.start + p.n / 2 for p in o.parts]

#-----------------------------------------------------------------------# Partition
@recipe function f(o::Partition{T}, f::Function = value; parts=true, connect=false) where {T}
    xlim --> (0, o.parts[end].start + o.parts[end].n)

    statname = name(o.parts[1].stat, false, false)
    labelbase = f == value ? 
        "Value of $statname" :
        "Custom Function of $statname"

    # get values
    y = repeat(map(x -> f(x.stat), o.parts), inner = 3)
    x = vcat(map(x -> [x.start, x.start + x.n, NaN], o.parts)...)
    if connect  # replace NaNs with values
        for i in 3:3:length(x) 
            x[i] = x[i - 1]  
        end
    end

    firstvalue = y[1]

    if firstvalue isa ScalarOb 
        @series begin
            label --> labelbase 
            w --> 2 
            x, y
        end
    elseif firstvalue isa Tuple{VectorOb, VectorOb}
        # for Hist
        # assume firstvalue[1] is values, firstvalue[2] is "weights"
        @series begin
            y2 = to_plot_shape([yi[1] for yi in y])
            y3 = to_plot_shape([yi[2] for yi in y])
            line_z --> y3 
            legend --> false
            w --> 2
            x, y2
        end
    elseif firstvalue isa VectorOb 
        p = length(firstvalue)
        # if each value is two numbers, assume they're the same series (e.g. Extrema)
        if p == 2
            @series begin 
                y = to_plot_shape(y)
                fillto --> y[:, 2]
                fillalpha --> .4 
                label --> labelbase 
                w --> 0 
                x, y[:, 1]
            end 
        else
            @series begin
                w --> 2
                label --> [labelbase * " $i" for i in 1:length(y[1])]
                x, to_plot_shape(y)
            end
        end
    end
    parts && @series PartLines(o) 
end

to_plot_shape(v::Vector) = v 
to_plot_shape(v::Vector{<:VectorOb}) = [v[i][j] for i in 1:length(v), j in 1:length(v[1])]

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