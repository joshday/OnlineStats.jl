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

#-----------------------------------------------------------------------------# Partition
@recipe function f(o::Partition) 
    xguide --> "Nobs"
    o.parts
end
@recipe function f(o::IndexedPartition) 
    xguide --> "Index"
    o.parts
end

@recipe function f(parts::T) where T <: AbstractVector{<:Pair{<:Any, <:OnlineStat}}
    seriestype  --> _seriestype(parts)
    seriesalpha --> _alpha(parts)
    linewidth   --> _linewidth(parts)
    fill_z      --> _fill_z(parts)
    ylims       --> _ylims(parts)
    yguide      --> _yguide(parts)

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

_seriestype(::Any) = :line
_seriestype(::AbstractVector{<:Pair{<:Any, <:Union{Extrema, HistogramStat, CountMap, ProbMap}}}) = :shape

_alpha(parts) = 1
_alpha(::AbstractVector{<:Pair{<:Any, <:Extrema}}) = .5

_linewidth(parts) = 1
_linewidth(::AbstractVector{<:Pair{<:Any, <:Union{Extrema, HistogramStat}}}) = 0

_label(parts) = name(parts[1][2], false, false)
_label(::AbstractVector{<:Pair{<:Any, <:Moments}}) = ["m1" "m2" "m3" "m4"]
_label(::AbstractVector{<:Pair{<:Any, <:HistogramStat}}) = ""

_fill_z(parts) = nothing 
function _fill_z(parts::AbstractVector{<:Pair{<:Any, <:HistogramStat}}) 
    z = vcat(map(x -> counts(x[2]), parts)...)
    z[z .> 0]
end

_ylims(parts) = (-Inf, Inf)
_ylims(parts::AbstractVector{<:Pair{<:Any, <:Union{CountMap, ProbMap}}}) = (0, Inf)

_group(parts) = nothing
function _group(parts::AbstractVector{<:Pair{<:Any, <:Union{CountMap, ProbMap}}})
    out = map(x -> collect(keys(sort!(value(x[2])))), parts)
    out = map(x -> repeat(x,inner=5), out)
    string.(vcat(out...))
end

function xy(part::Pair{<:TwoThings, <:Union{Mean, Variance}})
    (a,b), o = part 
    [a, b, NaN], [value(o), value(o), NaN]
end
function xy(part::Pair{<:TwoThings, <:Extrema})
    (a,b), o = part 
    low, high = extrema(o)
    [a, a, b, b, NaN], [low, high, high, low, NaN]
end
function xy(part::Pair{<:TwoThings, <:Moments})
    (a,b), o = part 
    hcat([[a, b, NaN] for _ in 1:4]...), hcat([[v,v,NaN] for v in value(o)]...)
end
function xy(part::Pair{<:TwoThings, <:HistogramStat})
    (a,b), o = part 
    x, y = Float64[], Float64[]
    edg = edges(o)
    cnts = counts(o)
    for i in eachindex(cnts)
        if cnts[i] > 0
            append!(x, [a, a, b, b, NaN])
            append!(y, [edg[i], edg[i+1], edg[i+1], edg[i], NaN])
        end
    end
    x, y
end

function xy(part::Pair{<:TwoThings, <:CountMap})
    (a,b), o = part 
    x = Float64[]
    y = Float64[]
    count = 0
    for (k,v) in sort!(o.value)
        append!(x, [a, a, b, b, NaN])
        append!(y, [count, count + v, count + v, count, NaN] ./ nobs(o))
        count += v
    end
    x, y
end



# # Series
# @recipe function f(val::Vector{T}) where {O, T<:Part{<:Any, <:Series}}
#     for i in eachindex(first(val).stat.stats) 
#         @series begin 
#             map(x -> Part(x.stat.stats[i], x.domain), val)
#         end
#     end
# end

# #-----------------------------------------------------------------------------# Partition 
# @recipe function f(o::Partition{T,O}) where {O, T}
#     xguide --> "Nobs"
#     yguide --> "Value"
#     ylim -> (0, o.parts[end].domain.last)
#     o.parts
# end

# @recipe function f(o::IndexedPartition{T,O}; connect=false) where {O, T}
#     xguide --> "Index"
#     yguide --> "Value"
#     o.parts
# end

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
