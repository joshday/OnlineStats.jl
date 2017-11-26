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

#-----------------------------------------------------------------------# OHistogram
@recipe function f(o::OHistogram)
    o.h
end

#-----------------------------------------------------------------------# IHistogram
@recipe function f(o::IHistogram)
    linetype --> :bar
    o.value, o.counts
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

#-----------------------------------------------------------------------# FitCategorical
@recipe function f(o::FitCategorical)
    seriestype --> :bar 
    collect(keys(o)), value(o)
end

#-----------------------------------------------------------------------# LinRegBuilder
# @recipe function f(o::LinRegBuilder, x::AbstractMatrix, y::AbstractVector, dim = Rows())
#     ŷ = predict(o, x, dim)
#     r = y - ŷ
# end