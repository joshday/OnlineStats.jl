#-----------------------------------------------------------------------# Weight
@recipe function f(wt::Weight; nobs=50)
    xlab --> "Number of Observations"
    ylab --> "Weight Value"
    label --> name(wt)
    ylim --> (0, 1)
    w --> 2
    [wt(i) for i in 1:nobs]
end

#-----------------------------------------------------------------------# Fallback
@recipe function f(o::OnlineStat)
    legend --> false
    axis --> false
    grid --> false
    ylim --> (0, 1)
    xlim --> (0, 1)
    annotations --> [(.5, .75, name(o) * ":"), (.5, .4, string(value(o)))]
    zeros(0)
end

#-----------------------------------------------------------------------# residual plot
@recipe function f(o::OnlineStat{VectorOb}, x::AbstractMatrix, y::AbstractVector)
    ylab --> "Residual"
    xlab --> "Observation Index"
    legend --> false
    @series begin
        linetype --> :scatter
        ŷ = predict(o, x)
        eachindex(y), y - ŷ
    end
end

@recipe function f(o::OnlineStat{XY})
    ylab --> "beta_j"
    xlab --> "j"
    seriestype --> :scatter
    coef(o)
end

@recipe function f(o::Series, x::AbstractMatrix, y::AbstractVector)
    for stat in o.stats
        @series begin stat end
    end
end


#-----------------------------------------------------------------------# StatCollection
@recipe function f(s::StatCollection)
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

#-----------------------------------------------------------------------# GroupBy 
@recipe function f(o::GroupBy{T, <:Union{KHist, Hist}}) where {T}
    sort!(o.value)
    link --> :all
    for (k, v) in pairs(o.value)
        @series begin 
            label --> k 
            v
        end
    end
end
@recipe function f(o::GroupBy)
    sort!(o.value)
    link --> :all
    collect(keys(o.value)), value.(collect(values(o.value)))
end

#-----------------------------------------------------------------------# StatHistory 
@recipe function f(o::StatHistory)
    layout --> length(o.circbuff)
    for i in 1:length(o.circbuff)
        @series begin 
            subplot --> i 
            label --> "Current - $(i-1)"
            o.circbuff[i]
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
@recipe function f(o::CovMatrix; corr = false)
    seriestype --> :heatmap
    corr ? cor(o) : cov(o)
end

#-----------------------------------------------------------------------# Histograms
@recipe function f(o::HistogramStat; normed=true)
    e, c = edges(o), counts(o)
    inds = findfirst(x -> x > 0, c):findlast(x -> x > 0, c)
    closed = o.left ? :left : :right
    normed --> normed
    Histogram(e[vcat(inds, inds[end] + 1)], c[inds], closed)
end

@recipe function f(o::KHist; normed=true)
    x, y = value(o)
    y2 = normed ? y ./ area(o) : y
    # xlim --> extrema(o.ex)
    fillto --> 0
    alpha --> .5
    x, y2
end

#-----------------------------------------------------------------------# CountMap
@recipe function f(o::CountMap, kys = keys(o); sortby = :keys)
    seriestype --> :bar 
    kys = collect(kys)
    vls = [o.value[ky] for ky in kys]
    sortby in [:keys, :values] || @warn("sortby = :$sortby not recognized")
    sp = sortby == :keys ? sortperm(kys) : sortperm(vls)
    x, y = string.(kys[sp]), vls[sp]
    hover --> ["($xi, $yi)" for (xi,yi) in zip(x, y)], :quiet
    label --> "Count"
    x, y
end

#-----------------------------------------------------------------------# Partition
@recipe f(o::AbstractPartition, fun=value) = o.parts, fun

@recipe function f(parts::Vector{Part{T, O}}, fun) where {T, O}
    sort!(parts)
    y = map(part -> fun(part.stat), parts)
    x = midpoint.(parts)
    # if parts[1].a isa Number
    #     xlim --> (parts[1].a, parts[end].b)
    # end
    if y[1] isa Number
        seriestype --> :step
        label --> name(parts[1].stat, false, false)
        x, y
    elseif y[1] isa VectorOb
        label --> name(parts[1].stat, false, false)
        y2 = plotshape(y)
        x2 = eltype(x) == Char ? string.(x) : x  # Plots can't handle Char
        if length(y[1]) == 2 
            # seriestype --> :step
            fillto --> y2[:, 1]
            alpha --> .4
            linewidth --> 0
            x2, y2[:, 2]
        else
            x2, y2 
        end
    elseif y[1] isa AbstractDict  # CountMap
        kys = []
        for item in y, ky in keys(item)
            ky ∉ kys && push!(kys, ky)
        end
        sort!(kys)
        @series begin 
            label --> reshape(kys, (1, length(kys)))
            ylim --> (0, 1)
            linewidth --> .5
            seriestype --> :bar
            if parts[1].a isa Number 
                bar_widths --> [p.b - p.a for p in parts]
            end
            y = plotshape(map(x -> reverse(cumsum(probs(x.stat, reverse(kys)))), parts))
            x, y
        end
    else 
        error("No plot recipe exists for this kind of partition")
    end
end

plotshape(v::Vector) = v
plotshape(v::Vector{<:VectorOb}) = [v[i][j] for i in eachindex(v), j in eachindex(v[1])]




#---------------------------------------------------------------# [Indexed]Partition Hist
@recipe f(o::IndexedPartition{T,O}) where {T, O<:HistogramStat} = o.parts
@recipe f(o::Partition{T,O}) where {T, O<:HistogramStat} = o.parts

@recipe function f(parts::Vector{Part{T, O}}) where {T, O<:HistogramStat}
    sort!(parts)
    x = []
    y = []
    fillz = Int[]
    for part in parts 
        edg = edges(part.stat)
        cnts = counts(part.stat)
        for i in eachindex(cnts)
            if cnts[i] > 0
                # rectangle
                push!(x, part.a); push!(y, edg[i])   
                push!(x, part.a); push!(y, edg[i + 1]) 
                push!(x, part.b); push!(y, edg[i + 1]) 
                push!(x, part.b); push!(y, edg[i])   
                push!(x, NaN); push!(y, NaN);
                # fill color
                push!(fillz, cnts[i])
            end
        end
    end
    @series begin 
        seriestype := :shape
        linewidth --> 0
        linealpha --> 0
        legend --> false
        fillz := fillz
        x, y
    end
end



#-----------------------------------------------------------------------# NBClassifier 
@recipe function f(o::NBClassifier)
    kys = collect(keys(o))
    layout --> nvars(o) + 1
    for j in 1:nvars(o) 
        stats = o[j]
        for (i, s) in enumerate(stats)
            @series begin 
                title --> "Var $j"
                legend --> false 
                subplot --> j 
                s
            end
        end
    end
    @series begin 
        subplot --> nvars(o) + 1
        label --> reshape(kys, 1, length(kys))
        framestyle := :none
        zeros(0, length(kys))
    end
end
