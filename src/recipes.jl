#-----------------------------------------------------------------------# Weight
@recipe function f(wt::Weight; nobs=50)
    xlab --> "Number of Observations"
    ylab --> "Weight Value"
    label --> OnlineStatsBase.name(wt)
    ylim --> (0, 1)
    w --> 2
    W = deepcopy(wt)
    v = zeros(nobs)
    for i in eachindex(v)
        updatecounter!(W)
        v[i] = weight(W)
    end
    v
end

#-----------------------------------------------------------------------# OHistogram
@recipe function f(o::OHistogram)
    linetype --> :bar
    o.h.edges[1][1:(end-1)], o.h.weights
end

#-----------------------------------------------------------------------# (1, 0) residual plot
@recipe function f(o::OnlineStat{(1,0)}, x::AbstractMatrix, y::AbstractVector,
        dim::ObsDimension = Rows())
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

#-----------------------------------------------------------------------# IHistogram
@recipe function plot(o::IHistogram)
    linetype --> :sticks
    x = first.(value(o))[1:(end-1)]
    y = last.(value(o))[1:(end-1)]
    x, y
end