
nobs(o::OnlineStat) = o.n


update!{T<:Real}(o::OnlineStat, y::Vector{T}) = (for yi in y; update!(o, yi); end)


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



function Base.show(io::IO, o::OnlineStat)
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

function DataFrame(o::OnlineStat; addFirstRow::Bool = true)
    s = state(o)
    df = DataFrame(map(typeof, s), statenames(o), 0)
    if addFirstRow
        push!(df, s)
    end
    df
    # df = convert(DataFrame, state(o)')
    # names!(df, statenames(o))
end

Base.push!(df::DataFrame, o::OnlineStat) = push!(df, state(o))


# some nice helper functions to extract stuff from dataframes... 
# this might exist already in dataframes... didn't look too hard

function getnice(df::DataFrame, s::Symbol)
    data = df[s]
    makenice(data)
end

makenice{T<:Vector}(da::DataArray{T}) = hcat(da...)'
makenice{T<:Number}(da::DataArray{T}) = DataArrays.array(da)

