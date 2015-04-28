
nobs(o::OnlineStat) = o.n


update!{T<:Real}(o::ScalarStat, y::Vector{T}) = (for yi in y; update!(o, yi); end)

function Base.merge(o1::OnlineStat, o2::OnlineStat)
    o1copy = copy(o1)
    merge!(o1copy, o2)
    o1copy
end


#------------------------------------------------------------# ScalarOnlineStat
function Base.show(io::IO, o::ScalarStat)
    snames = statenames(o)
    svals = state(o)

    println(io, "Online ", string(typeof(o)))
    for (i, sname) in enumerate(snames[1 : end - 1])
        @printf(io, " * %s:  %f\n", sname, svals[i])
    end

    # Better formatting (no decimal) for nobs
    @printf(io, " * %s:  %d\n", snames[end], svals[end])
end


# Why doesn't this work in 0.3.7?
# DataFrame(o::ScalarStat) = DataFrame(state(o), statenames(o))

function DataFrame(o::ScalarStat)
    df = convert(DataFrame, state(o)')
    names!(df, statenames(o))
end

Base.push!(df::DataFrame, o::ScalarStat) = push!(df, state(o))
