
nobs(o::OnlineStat) = o.n


update!{T<:Real}(o::ScalarStat, y::Vector{T}) = (for yi in y; update!(o, yi); end)


Base.copy(o::OnlineStat) = deepcopy(o)

function Base.merge(o1::OnlineStat, o2::OnlineStat)
    o1copy = copy(o1)
    merge!(o1copy, o2)
    o1copy
end


#---------------------------------------------------------------# NonMatrixStat

# temporary fix for the "how to print" problem... lets come up with something nicer
mystring(f::Float64) = @sprintf("%f", f)
mystring(x) = string(x)


function Base.show(io::IO, o::NonMatrixStat)
    snames = statenames(o)
    svals = state(o)

    println(io, "Online ", string(typeof(o)))
    for (i, sname) in enumerate(snames)
        @printf(io, " * %8s:  %s\n", sname, mystring(svals[i]))
    end

    # # Better formatting (no decimal) for nobs
    # @printf(io, " * %s:  %d\n", snames[end], svals[end])
end


# Why doesn't this work in 0.3.7?
# DataFrame(o::OnlineStat) = DataFrame(state(o), statenames(o))

function DataFrame(o::NonMatrixStat)
    df = convert(DataFrame, state(o)')
    names!(df, statenames(o))
end

Base.push!(df::DataFrame, o::NonMatrixStat) = push!(df, state(o))

