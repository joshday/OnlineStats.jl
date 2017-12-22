mutable struct Summary{O <: Union{CountMap, Hist}} <: ExactStat{0}
    summarizer::O
    summaries::Dict{Int, O}  # starting observation => summary
    partition::Int
    n::Int
end
function Summary(o::O, partition::Int = 100) where {O}
    Summary(o, Dict{Int, O}(), partition, 0)
end 
value(o::Summary) = sort(o.summaries)

function Base.show(io::IO, o::Summary{O}) where {O}
    print(io, "Summary of $O")
end



function fit!(o::Summary, y::ScalarOb, γ::Float64)
    o.n += 1
    newobj = copy(o.summarizer)
    fit!(newobj, y, γ)
    o.summaries[o.n] = newobj
    if o.n % 2o.partition == 0
        kys = sort(collect(keys(o.summaries)))
        for k in 2:2:length(kys)
            summary = pop!(o.summaries, kys[k])
            merge!(o.summaries[kys[k-1]], summary, 1.0)
        end
    end
end