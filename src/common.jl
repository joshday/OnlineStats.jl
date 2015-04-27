
StatsBase.nobs{T <: OnlineStat}(obj::T) = obj.n


#------------------------------------------------------------# ScalarOnlineStat
function Base.show{T <: ScalarStat}(io::IO, obj::T)
    paramnames = state_names(obj)
    paramvalues = state(obj)

    @printf(io, "Online %s\n", string(typeof(obj)))
    for i in 1:length(paramnames)
        @printf(io, " * %s:  %f\n", paramnames[i], paramvalues[i])
    end
    @printf(io, " * nobs:  %d\n", nobs(obj))
end

function DataFrames.DataFrame{T <: ScalarStat}(obj::T)
    DataFrames.DataFrame(variable = state_names(obj),
                         values = state(obj),
                         nobs = nobs(obj))
end
