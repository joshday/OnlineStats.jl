mutable struct Series{I, W <: Weight, O <: Tuple} <: AbstractSeries
    weight::W
    stats::O
    nobs::Int
    nups::Int
    id::Symbol
    function Series{I, W, O}(weight::W, stats::O, nobs::Int, nups::Int, id::Symbol) where
            {I <: Input, W <: Weight, O <: Tuple}
        all(x -> input_type(x) == I, stats) ||
            throw(ArgumentError("Input types don't all match $I"))
        new{I, W, O}(weight, stats, nobs, nups, id)
    end
end
function Series{W, O}(weight::W, stats::O, nobs::Int, nups::Int, id::Symbol)
    I = input_type(stats[1])
    Series{I, W, O}(weight, stats, nobs, nups, id)
end


Series(id::Symbol, wt::Weight, stats...) = Series(wt, stats, 0, 0, id)
Series(wt::Weight, id::Symbol, stats...) = Series(wt, stats, 0, 0, id)

function Series(stats...; weight::Weight = EqualWeight(), id::Symbol = :unlabeled)
     Series(weight, stats, 0, 0, id)
 end

function Series(y::AA, args...; weight::Weight = EqualWeight(), id::Symbol = :unlabeled)
    o = Series(weight, id, args...)
    fit!(o, y)
    o
end
value(o::Series) = o.stats
nobs(o::Series) = o.nobs
nups(o::Series) = o.nups
unbias(o::Series) = nobs(o) / (nobs(o) - 1)
function Base.show{I}(io::IO, o::Series{I})
    header(io, "$(name(o, false)) | $I | id: $(o.id)\n")
    subheader(io, "weight: $(o.weight)\n")
    subheader(io, "nobs:   $(o.nobs)\n")
    n = length(o.stats)
    for i in 1:n
        s = o.stats[i]
        print_item(io, name(s), value(s, nobs(o)), i != n)
    end
end
updatecounter!(o::Series, n2::Int = 1) = (o.nups += 1; o.nobs += n2)


#-------------------------------------------------------------------------# ScalarInput
function fit!(o::Series{ScalarInput}, y::Real, γ::Float64 = nextweight(o))
    updatecounter!(o)
    map(stat -> fit!(stat, y, γ), o.stats)
    o
end
function fit!(o::Series{ScalarInput}, y::AVec)
    for yi in y
        fit!(o, yi)
    end
    o
end
function fit!(o::Series{ScalarInput}, y::AVec, b::Integer)
    maprows(b, y) do yi
        fitbatch!(o, yi)
    end
    o
end
fitbatch!(o::Series, yi) = fit!(o, yi)
function fit!(o::Series{ScalarInput}, y::AVec, γ::Float64)
    for yi in y
        fit!(o, yi, γ)
    end
    o
end
function fit!(o::Series{ScalarInput}, y::AVec, γ::AVecF)
    length(y) == length(γ) || throw(DimensionMismatch())
    for (yi, γi) in zip(y, γ)
        fit!(o, yi, γi)
    end
    o
end

fit(o::OnlineStat{ScalarInput}, y::AVec) = Series(y, o)
fit(o::OnlineStat{ScalarInput}, y::AVec, wt::Weight) = Series(y, o; weight = wt)

#-------------------------------------------------------------------------# VectorInput
function fit!(o::Series{VectorInput}, y::AVec, γ::Float64 = nextweight(o))
    updatecounter!(o)
    map(stat -> fit!(stat, y, γ), o.stats)
    o
end
function fit!(o::Series{VectorInput}, y::AMat)
    for i in 1:size(y, 1)
        fit!(o, view(y, i, :))
    end
    o
end
