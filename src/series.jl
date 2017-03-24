struct Stats{T <: OnlineStat, W <: Weight}
    weight::W
    stats::Vector{T}
end
function Base.show(io::IO, o::Stats)
    printheader(io, name(o))
    for s in o.stats
        println(io, s)
    end
end

function fit!(o::Stats, y::Real)
    updatecounter!(o.weight)
    γ = weight(o.weight)
    for i in eachindex(o.stats)
        @inbounds o.stats[i] = fit(o.stats[i], y, γ)
    end
    o
end
function fit!(o::Stats, y::AVec)
    for yi in y
        fit!(o, yi)
    end
    o
end



struct Mean <: OnlineStat{ScalarInput}
    value::Float64
    Mean(μ::Real = 0.0) = new(μ)
end
fit(o::Mean, y::Real, γ::Float64) = Mean(smooth(o.value, y, γ))
