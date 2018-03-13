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
    grid --> false
    ylim --> (0, 1)
    xlim --> (0, 1)
    annotations --> [(.5, .75, name(o) * ":"), (.5, .4, string(value(o)))] #), .1, .2, string(value(o))]
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

@recipe function f(o::OnlineStat{(1,0)})
    coef(o)
end

@recipe function f(o::Series{(1,0)}, x::AbstractMatrix, y::AbstractVector)
    for stat in stats(o)
        @series begin stat end
    end
end


#-----------------------------------------------------------------------# AbstractSeries
@recipe function f(s::AbstractSeries)
    if :layout in keys(plotattributes)
        for stat in stats(s)
            @series begin stat end
        end 
    else  # hack to ensure series aren't sent to wrong subplots
        layout --> length(stats(s))
        for i in eachindex(stats(s))
            @series begin 
                subplot --> i 
                stats(s)[i]
            end
        end
    end
end

#-----------------------------------------------------------------------# AutoCov
@recipe function f(o::AutoCov)
    xlabel --> "Lag"
    ylabel --> "Autocorrelation"
    ylim --> (0, 1)
    seriestype --> :scatter
    autocor(o)
end

#-----------------------------------------------------------------------# CovMatrix
@recipe function f(o::CovMatrix)
    seriestype --> :heatmap
    cov(o)
end

#-----------------------------------------------------------------------# Hist 
@recipe f(o::Hist) = o.alg

@recipe f(o::FixedBins{closed}) where {closed} =
    Histogram(o.edges, o.counts, closed)

@recipe function f(o::AdaptiveBins)
    linewidth --> 2
    seriestype --> :sticks
    _midpoints(o), _counts(o)
end


#-----------------------------------------------------------------------# Group 
@recipe function f(o::Union{MV, Group})
    layout --> length(o.stats)
    for (i, stat) in enumerate(o.stats)
        @series begin 
            title --> "Stat $i"
            stat
        end
    end
end

#-----------------------------------------------------------------------# CountMap
@recipe function f(o::CountMap)
    seriestype --> :bar 
    collect(keys(o)), collect(values(o))
end

#-----------------------------------------------------------------------# Vector{<:Part}
@recipe function f(parts::Vector{<:Part}, mapfun = value)
    sort!(parts)
    statname = name(parts[1].stat, false, false)
    nvec = nobs.(parts)
    ymap = map(x -> mapfun(x.stat), parts)
    x = midpoint.(parts)
    
    if first(ymap) isa Tuple{VectorOb, VectorOb} #################### Hist
        realx, y, z = eltype(x)[], Float64[], Float64[]
        for i in eachindex(ymap)
            values, counts = ymap[i]
            for j in eachindex(values)
                push!(realx, x[i])
                push!(y, values[j])
                push!(z, counts[j])
            end
        end
        label --> statname
        seriestype --> :scatter 
        marker_z --> z
        markerstrokewidth --> 0
        color --> :blues
        realx, y
    elseif first(ymap) isa Dict ##################################### CountMap
        lvls = []
        for p in parts
            for k in keys(p.stat)
                k ∉ lvls && push!(lvls, k)
            end
        end
        sort!(lvls)
        @series begin 
            label --> reshape(lvls, (1, length(lvls)))
            ylim --> (0, 1)
            linewidth --> .5
            seriestype --> :bar
            # bar_widths --> nobs.(parts) / sum(nobs.(parts))
            y = to_plot_shape(map(x -> reverse(cumsum(probs(x.stat, reverse(lvls)))), parts))
            x, y
        end
    elseif first(ymap) isa VectorOb ################################# Vector value
        label --> statname 
        y = to_plot_shape(ymap)
        if size(y, 2) == 2
            fillto --> y[:, 2]
            fillalpha --> .6
            linewidth --> 0
            x, y[:, 1]
        else
            x, y
        end
    else ############################################################ Scalar value
        label --> statname
        x, ymap
    end
end

to_plot_shape(v::Vector{<:VectorOb}) = [v[i][j] for i in eachindex(v), j in 1:length(v[1])]

@recipe function f(o::AbstractPartition, mapfun = value)
    o.parts, mapfun
end


# #-----------------------------------------------------------------------# NBClassifier 
# @recipe function f(o::NBClassifier)
#     kys = keys(o)
#     layout --> nparams(o) + 1
#     alpha --> .4
#     seriestype --> :line 
#     fillto --> 0
#     for j in 1:nparams(o) 
#         stats = o[j]
#         for (i, s) in enumerate(stats)
#             @series begin 
#                 title --> "Var $j"
#                 legend --> false 
#                 subplot --> j 
#                 s
#             end
#         end
#     end
#     @series begin 
#         subplot --> nparams(o) + 1
#         label --> reshape(kys, 1, length(kys))
#         framestyle := :none
#         zeros(0, length(kys))
#     end
# end
