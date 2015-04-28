#------------------------------------------------------------------# OnlineStat
nobs{T <: OnlineStat}(obj::T) = obj.n


#------------------------------------------------------------------# ScalarStat
function Base.show(io::IO, obj::ScalarStat)
    paramnames = statenames(obj)
    paramvalues = state(obj)

    @printf(io, "Online %s\n", string(typeof(obj)))

    for i in 1:length(paramnames)
        @printf(io, " * %s:  %f\n", paramnames[i], paramvalues[i])
    end
end


function DataFrame(obj::ScalarStat)
    st = state(obj)[1 : end - 1]
    stn = statenames(obj)[1 : end - 1]

    DataFrame(variable = stn, values = st, nobs = nobs(obj))
end


function Base.push!(df::DataFrame, obj::ScalarStat)
    st = state(obj)[1 : end - 1]
    stn = statenames(obj)[1 : end - 1]

    mat = [stn st]
    for i in 1:length(st)
        push!(df, [mat[i, :] nobs(obj)])
    end
end
