
struct WeightGroup{W <: Weight, STATS <: Tuple}
    weight::W
    stats::STATS
end
WeightGroup(wt::Weight = EqualWeight(), args...) = WeightGroup(wt, args)


struct Mean value::Float64 end
fit(o::Mean, y::Real, γ::Float64) = smooth(o.value, y, γ)

struct Stats{T}
    stats::Vector{T}
end

function fit!(o::Stats, y::Real, γ::Float64)
    o.stats[1] = fit(o.stats[1], y, γ)
    o
end
function fit!(o::Stats, y::AVec, γ::Float64)
    for yi in y
        fit!(o, yi, γ)
    end
    o
end
