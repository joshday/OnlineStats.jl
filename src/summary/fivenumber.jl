#-------------------------------------------------------# Type and Constructors
type FiveNumberSummary <: OnlineStat
    extrema::Extrema
    quantiles::QuantileSGD
    n::Int64
end

function FiveNumberSummary(y::Vector, wgt::Weighting = StochasticWeighting();
                           start = zeros(3))
    o = FiveNumberSummary(wgt, start = start)
    update!(o, y)
    o
end

function FiveNumberSummary(wgt::Weighting = StochasticWeighting();
                           start = zeros(3))
    FiveNumberSummary(Extrema(), QuantileSGD(wgt, start = start), 0)
end


#-----------------------------------------------------------------------# state
statenames(o::FiveNumberSummary) = [:min, :q1, :median, :q3, :max, :nobs]
state(o::FiveNumberSummary) = [minimum(o); copy(o.quantiles.q); maximum(o); nobs(o)]

minimum(o::FiveNumberSummary) = minimum(o.extrema)
maximum(o::FiveNumberSummary) = maximum(o.extrema)



#---------------------------------------------------------------------# update!
function update!(o::FiveNumberSummary, y::Float64)
    update!(o.extrema, y)
    update!(o.quantiles, y)
    o.n += 1
    return
end

function update!(o::FiveNumberSummary, y::VecF)
    for yi in y
        update!(o, yi)
    end
end

function updatebatch!(o::FiveNumberSummary, y::VecF)
    updatebatch!(o.extrema, y)
    updatebatch!(o.quantiles, y)
    o.n += length(y)
    return
end

