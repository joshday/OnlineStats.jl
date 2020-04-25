#-----------------------------------------------------------------------# Weight
@recipe function f(wt::Weight; nobs=50)
    xguide --> "n"
    yguide --> "w(n)"
    label --> name(wt)
    xlim --> (0, nobs + 1)
    ylim --> (0, 1.02)
    linewidth --> 2
    seriestype --> :scatter
    wt.(1:nobs)
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

#-----------------------------------------------------------------------------# OrderStats
@recipe function f(o::OrderStats)
    label --> "Approximate CDF via OrderStats"
    xguide --> "x"
    yguide --> "P(X ≤ x)"
    a, b = value(o.ex)
    v = vcat(a, value(o), b)
    k = length(v)
    v, [1:k] ./ k
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


#-----------------------------------------------------------------------# StatCollection
@recipe function f(s::OnlineStatsBase.StatCollection)
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

#-----------------------------------------------------------------------# StatLag
@recipe function f(o::StatLag)
    layout --> length(o.value)
    for i in 1:length(o.value)
        @series begin
            subplot --> i
            label --> "Current - $(i-1)"
            o.value[i]
        end
    end
end

#-----------------------------------------------------------------------# AutoCov
@recipe function f(o::AutoCov)
    xguide --> "Lag"
    yguide --> "Autocorrelation"
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
@recipe function f(o::HistogramStat; normalize=true)
    e, c = edges(o), counts(o)
    inds = findfirst(x -> x > 0, c):findlast(x -> x > 0, c)
    closed = o.left ? :left : :right
    normalize --> normalize
    Histogram(e[vcat(inds, inds[end] + 1)], c[inds], closed)
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


#-----------------------------------------------------------------------------# Vector{<:Part}
function _x(p::Part{<:ClosedInterval}) 
    a, b = p.domain.first, p.domain.last
    [a, b, b]  # third point won't be plotted since _y(val)[3] is NaN
end
_y(val) = [val, val, NaN]
_label(v::Vector{<:Part}) = OnlineStatsBase.name(first(v).stat, false, false)

# Fallback (Mean, Variance, and scalar-valued stat)
@recipe function f(val::Vector{<:Part})
    label --> _label(val)
    vcat(_x.(val)...), vcat(map(x -> _y(value(x.stat)), val)...)
end

# CountMap
@recipe function f(parts::Vector{<:Part{<:Any, <:CountMap}}; prob=true, use_part_width=true)
    keyset = sort!(collect(mapreduce(x -> Set(keys(value(x.stat))), union, parts)))
    for k in keyset, p in parts 
        get!(p.stat.value, k, 0)
    end
    x = [_middle(p.domain.first, p.domain.last) for p in parts]
    ys = hcat([[value(p.stat)[k] for p in parts] for k in keyset]...)
    for (i, k) in enumerate(reverse(keyset))
        y = sum(ys[:, i:end], dims=2)
        if prob 
            y = y ./ sum(ys, dims=2)
        end
        @series begin 
            seriestype --> :bar
            if use_part_width
                bar_widths --> [p.domain.last - p.domain.first for p in parts]
            end
            linewidth --> 0
            label --> string(k)
            x,  y
        end
    end
end 
_middle(a,b) = middle(a,b)
function _middle(a::Date, b::Date) 
    m = (Millisecond(a.instant.periods) + Millisecond(b.instant.periods)) / 2
    DateTime(Dates.UTInstant(m))
end

# Extrema
@recipe function f(parts::Vector{<:Part{<:Any, <:Extrema}}) 
    sort!(parts)
    label --> _label(parts)
    alpha --> .3
    fillrange --> vcat(map(x -> _y(x.stat.min), parts)...)
    vcat(_x.(parts)...), vcat(map(x -> _y(x.stat.max), parts)...)
end

# KHist and Hist
@recipe function f(parts::Vector{<:Part{<:Any, <:HistogramStat}}; prob=true)
    sort!(parts)
    x = []
    y = []
    fillz = Float64[]
    for part in parts
        edg = edges(part.stat)
        cnts = counts(part.stat)
        n = nobs(part.stat)
        for i in eachindex(cnts)
            if cnts[i] > 0
                # rectangle
                push!(x, part.domain.first); push!(y, edg[i])
                push!(x, part.domain.first); push!(y, edg[i + 1])
                push!(x, part.domain.last); push!(y, edg[i + 1])
                push!(x, part.domain.last); push!(y, edg[i])
                push!(x, NaN); push!(y, NaN);
                # fill color
                push!(fillz, prob ? cnts[i] / n : cnts[i])
            end
        end
    end
    @series begin
        lt = prob ? "Probabilities" : "Counts"
        seriestype := :shape
        linewidth --> 0
        linealpha --> 0
        label --> ""
        legendtitle --> lt
        fill_z := fillz
        x, y
    end
end

# Series
@recipe function f(val::Vector{T}) where {O, T<:Part{<:Any, <:Series}}
    for i in eachindex(first(val).stat.stats) 
        @series begin 
            map(x -> Part(x.stat.stats[i], x.domain), val)
        end
    end
end

#-----------------------------------------------------------------------------# Partition 
@recipe function f(o::Partition{T,O}) where {O, T}
    xguide --> "Nobs"
    yguide --> "Value"
    ylim -> (0, o.parts[end].domain.last)
    o.parts
end

@recipe function f(o::IndexedPartition{T,O}; connect=false) where {O, T}
    xguide --> "Index"
    yguide --> "Value"
    o.parts
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
        label --> string.(reshape(kys, 1, length(kys)))
        framestyle := :none
        zeros(0, length(kys))
    end
end
