#-------------------------------------------------------# Type and Constructors
"""
Univariate five-number summary.  Maximum and minimum are exact and .25, .5, .75
quantiles are approximate using on online MM algorithm.
"""
type FiveNumberSummary <: OnlineStat
    extrema::Extrema
    quantiles::QuantileMM
    n::Int64
end

function FiveNumberSummary(y::AVecF, wgt::Weighting = StochasticWeighting();
                           start = zeros(3))
    o = FiveNumberSummary(wgt, start = start)
    update!(o, y)
    o
end

function FiveNumberSummary(wgt::Weighting = StochasticWeighting();
                           start = zeros(3))
    FiveNumberSummary(Extrema(), QuantileMM(wgt, start = start), 0)
end


#-----------------------------------------------------------------------# state
statenames(o::FiveNumberSummary) = [:min, :q1, :median, :q3, :max, :nobs]
state(o::FiveNumberSummary) = [minimum(o); copy(o.quantiles.q); maximum(o); nobs(o)]

Base.minimum(o::FiveNumberSummary) = minimum(o.extrema)
Base.maximum(o::FiveNumberSummary) = maximum(o.extrema)



#---------------------------------------------------------------------# update!
function update!(o::FiveNumberSummary, y::Float64)
    update!(o.extrema, y)
    update!(o.quantiles, y)
    o.n += 1
    return
end

function update!(o::FiveNumberSummary, y::AVecF)
    for yi in y
        update!(o, yi)
    end
end

function updatebatch!(o::FiveNumberSummary, y::AVecF)
    updatebatch!(o.extrema, y)
    updatebatch!(o.quantiles, y)
    o.n += length(y)
    return
end
