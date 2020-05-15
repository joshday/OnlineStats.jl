#-----------------------------------------------------------------------# Weight
@recipe function f(wt::Weight; nobs=50)
    xguide --> "n"
    yguide --> "w(n)"
    label --> name(wt)
    xlims --> (0, nobs + 1)
    ylims --> (0, 1.02)
    linewidth --> 2
    seriestype --> :scatter
    wt.(1:nobs)
end

#-----------------------------------------------------------------------# Fallback
@recipe function f(o::OnlineStat)
    legend --> false
    axis --> false
    grid --> false
    ylims --> (0, 1)
    xlims --> (0, 1)
    annotations --> [(.5, .75, name(o) * ":"), (.5, .4, string(value(o)))]
    zeros(0)
end

#-----------------------------------------------------------------------------# OrderStats
@recipe function f(o::OrderStats)
    label --> "Approximate CDF via OrderStats"
    legend --> :topleft
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
    normalize --> normalize
    Histogram(e[vcat(inds, inds[end] + 1)], c[inds], _closed(o))
end

_closed(o::Hist) = o.left ? :left : :right 
_closed(o) = :left


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

#-----------------------------------------------------------------------------# Partition
_xguide(o::Partition) = "Nobs"
_xguide(o::Union{IndexedPartition, KIndexedPartition}) = "Index"

__middle(x) = x 
__middle(x::Tuple) = middle(x...)

@recipe function f(o::Union{Partition, IndexedPartition, KIndexedPartition}; type=1) 
    if type === 1
        @series begin
            t = o isa Partition ? "" : "Joint Distribution"
            title --> t
            xguide --> _xguide(o)
            o.parts
        end
    elseif type === 2
        @series begin 
            title --> "Stat Over Entire Index"
            seriestype --> :bar 
            orientation --> :h
            mergestats(o)
        end
    elseif type === 3
        @series begin 
            l = o isa Partition ? "Nobs / Part" : "Index Distribution"
            label --> "Index Distribution"
            seriestype := :bar
            linewidth --> 0
            line_alpha --> 0
            data = [__middle(loc) => nobs(o) for (loc,o) in o.parts]
            first.(data), last.(data)
        end
    else
        error("type must be 1, 2, or 3.")
    end
end

@recipe function f(parts::T) where T <: AbstractVector{<:Pair{<:Any, <:OnlineStat}}
    seriestype  --> _seriestype(parts)
    seriesalpha --> _alpha(parts)
    linewidth   --> _linewidth(parts)
    linealpha   --> _linealpha(parts)
    line_z      --> _line_z(parts)
    fill_z      --> _fill_z(parts)
    ylims       --> _ylims(parts)
    xlims       --> _xlims(parts)
    yguide      --> _yguide(parts)

    hover --> string.(nobs.(last.(parts))), :quiet

    group = _group(parts)
    x, y = xy(parts)

    if isnothing(group)
        label --> _label(parts)
        return x, y 
    else 
        for k in unique(group)
            @series begin 
                label --> _label(parts) * ": $k"
                x[group .== k], y[group .== k]
            end
        end
    end
end

@recipe function f(parts::AbstractVector{<:Pair{<:Any, <:Union{Series, Group}}})
    nstats = length(parts[1][2].stats)
    for i in 1:nstats 
        @series begin 
            map(x -> x[1] => x[2].stats[i], parts)
        end
    end
end

function xy(parts::AbstractVector{<:Pair{<:Any, <:OnlineStat}}) 
    data = xy.(parts)
    x, y = vcat(first.(data)...), vcat(last.(data)...)
end

_yguide(::Any) = ""
_yguide(::AbstractArray{<:Pair{<:Any, <:CountMap}}) = "Probability"

_seriestype(::Any) = :path
_seriestype(::AbstractVector{<:Pair{<:TwoThings, <:Union{Extrema, HistogramStat, CountMap, ProbMap, Counter}}}) = :shape
_seriestype(::AbstractVector{<:Pair{<:Number, <:Mean}}) = :scatter

_linealpha(parts) = 1
_linealpha(::AbstractVector{<:Pair{<:TwoThings, <:Union{Extrema,HistogramStat,CountMap}}}) = 0

_line_z(parts) = nothing 
_line_z(parts::AbstractVector{<:Pair{<:Number, <:HistogramStat}}) = repeat(vcat(counts.(last.(parts))...), inner=3)

_alpha(parts) = 1
_alpha(::AbstractVector{<:Pair{<:Any, <:Extrema}}) = .5

_linewidth(parts) = 1
_linewidth(::AbstractVector{<:Pair{<:TwoThings, <:Union{Mean, Variance}}}) = 2
_linewidth(::AbstractVector{<:Pair{<:TwoThings, <:Union{Extrema,HistogramStat,CountMap}}}) = 0
_linewidth(::AbstractVector{<:Pair{<:Number, <:Extrema}}) = 2
_linewidth(::AbstractVector{<:Pair{<:Number, <:Union{HistogramStat,CountMap}}}) = 4

_label(parts) = name(parts[1][2], false, false)
_label(::AbstractVector{<:Pair{<:TwoThings, <:Moments}}) = ["m1" "m2" "m3" "m4"]
_label(::AbstractVector{<:Pair{<:Any, <:HistogramStat}}) = ""
_label(::AbstractVector{<:Pair{<:Any, <:Counter{T}}}) where {T} = "Count of $T"

_fill_z(parts) = nothing 
function _fill_z(parts::AbstractVector{<:Pair{<:TwoThings, <:HistogramStat}}) 
    z = vcat(map(x -> counts(x[2]), parts)...)
    z[z .> 0]
end

_ylims(parts) = (-Inf, Inf)
_ylims(parts::AbstractVector{<:Pair{<:TwoThings, <:Union{CountMap, ProbMap, Counter}}}) = (0, Inf)

_xlims(parts) = (-Inf, Inf)
_xlims(parts::AbstractVector{<:Pair{<:TwoThings{<:Number, <:Number}, <:Any}}) = parts[1][1][1], parts[end][1][2]

_group(parts) = nothing
function _group(parts::AbstractVector{<:Pair{<:TwoThings, <:Union{CountMap, ProbMap}}})
    out = map(x -> collect(keys(sort!(value(x[2])))), parts)
    out = map(x -> repeat(x,inner=5), out)
    string.(vcat(out...))
end
function _group(parts::AbstractVector{<:Pair{<:Number, <:CountMap}}) 
    out = map(x -> collect(keys(sort!(value(x[2])))), parts)
    string.(repeat(vcat(out...), inner=3))
end

#-----------------------------------------------------------------------------# xy Mean and Variance
function xy(part::Pair{<:TwoThings, <:Union{Mean, Variance, Counter}})
    (a,b), o = part 
    [a, b, b], [value(o), value(o), NaN]
end
xy(part::Pair{<:Number, <:Union{Mean, Variance}}) = part[1], value(part[2])
#-----------------------------------------------------------------------------# xy Counter 
function xy(part::Pair{<:TwoThings, <:Counter})
    (a,b), o = part
    [a, a, b, b, b], [0, value(o), value(o), 0, NaN]
end
xy(part::Pair{<:Number, <:Counter}) = part[1], value(part[2])
#-----------------------------------------------------------------------------# xy Extrema
function xy(part::Pair{<:TwoThings, <:Extrema})
    (a,b), o = part 
    low, high = extrema(o)
    [a, a, b, b, b], [low, high, high, low, NaN]
end
function xy(part::Pair{<:Number, <:Extrema})
    loc, o = part 
    low, high = extrema(o)
    [loc, loc, loc], [low, high, NaN]
end
#-----------------------------------------------------------------------------# xy Moments
function xy(part::Pair{<:TwoThings, <:Moments})
    (a,b), o = part 
    hcat([[a, b, b] for _ in 1:4]...), hcat([[v,v,NaN] for v in value(o)]...)
end
function xy(part::Pair{<:Number, <:Moments})
    loc, o = part 
    [loc loc loc loc], hcat(value(o)...)
end
#-----------------------------------------------------------------------------# xy HistogramStat
function xy(part::Pair{<:TwoThings, <:HistogramStat})
    (a,b), o = part 
    x, y = [], Float64[]
    edg = edges(o)
    cnts = counts(o)
    for i in eachindex(cnts)
        if cnts[i] > 0
            append!(x, [a, a, b, b, b])
            append!(y, [edg[i], edg[i+1], edg[i+1], edg[i], NaN])
        end
    end
    x, y
end
function xy(part::Pair{<:Number, <:HistogramStat})
    loc, o = part 
    x, y = [], Float64[]
    edg = edges(o)
    cnts = counts(o)
    for i in eachindex(cnts)
        if cnts[i] > 0 
            append!(x, [loc, loc, loc])
            append!(y, [edg[i], edg[i+1], NaN])
        end
    end
    x, y
end


#-----------------------------------------------------------------------------# xy CountMap
function xy(part::Pair{<:TwoThings, <:CountMap})
    (a,b), o = part 
    x, y = [], Float64[]
    count = 0
    for (k,v) in sort!(o.value)
        append!(x, [a, a, b, b, b])
        append!(y, [count, count + v, count + v, count, NaN] ./ nobs(o))
        count += v
    end
    x, y
end
function xy(part::Pair{<:Number, <:CountMap})
    loc, o = part 
    sort!(o)
    x, y = [], Float64[]
    count = 0 
    for (k,v) in sort!(o.value)
        append!(x, [loc, loc, loc])
        append!(y, [count, count + v, NaN] ./ nobs(o))
        count += v
    end
    x, y
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
