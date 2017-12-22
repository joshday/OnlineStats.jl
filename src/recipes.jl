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
@recipe function f(o::Partition{<:ExactStat{0}})
    xlab --> "Nobs"
    title --> name(o.summarizer)
    x = map(x -> x.start, o.parts)
    y = value.(o.parts)
    x, y
end

@recipe function f(o::Partition{Variance})
    xlab --> "Nobs"
    title --> "Partition of Size $(length(o.parts))"
    μ = map(x -> mean(x.stat), o.parts)
    σ = map(x -> std(x.stat), o.parts)
    x = map(x -> x.start, o.parts)
    @series begin
        label --> "Mean"
        x, μ
    end
    @series begin 
        label --> "Parts"
        seriestype --> :vline 
        alpha --> .2
        map(x -> x.start, o.parts)
    end
    @series begin
        fillto --> μ .- 1.96 .* σ
        alpha --> .3
        grid --> false
        linewidth --> 0
        label --> "95% CI"
        x, μ .+ 1.96 .* σ
    end
end



#-----------------------------------------------------------------------# LinRegBuilder
# @recipe function f(o::LinRegBuilder, x::AbstractMatrix, y::AbstractVector, dim = Rows())
#     ŷ = predict(o, x, dim)
#     r = y - ŷ
# end