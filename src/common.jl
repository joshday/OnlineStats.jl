"Return the number of observations used"
StatsBase.nobs{T <: OnlineStat}(obj::T) = obj.n


param{T <: OnlineStat}(obj::T) = error("implementation needed for" * typeof(obj))
value{T <: OnlineStat}(obj::T) = error("implementation needed for" * typeof(obj))


#------------------------------------------------------------# ScalarOnlineStat
function Base.show{T <: ScalarOnlineStat}(io::IO, obj::T)
    paramnames = param(obj)
    paramvalues = value(obj)

    @printf(io, "Online %s\n", string(typeof(obj)))
    for i in 1:length(paramnames)
        @printf(io, " * %s:  %f\n", paramnames[i], paramvalues[i])
    end
    @printf(io, " * nobs:  %d\n", nobs(obj))
end

# state() which returns array
# function state{T <: ScalarOnlineStat}(obj::T)
#     [[param(obj), :nobs] [value(obj), nobs(obj)]]
# end
# function addstate!{T <: ScalarOnlineStat}(a::Array, obj::T)
#     append!(a, state(obj))
# end


function state{T <: ScalarOnlineStat}(obj::T)
    DataFrame(variable = param(obj), value = value(obj), nobs = nobs(obj))
end

function addstate!{T <: ScalarOnlineStat}(df::DataFrame, obj::T)
    append!(df, state(obj))
end




"""
`addstate!(df, obj)`

Add `state(obj)` results to new row(s) in `df`
"""
addstate!


"""
`state(obj)`
`state(obj, DataFrame)`

Return the current estimate and nobs.  Column names are
consistent with `melt` (:variable, :value, ...)
"""
state


"""
`update!(obj, newdata)`

Use `newdata` to update estimates of the `OnlineStat` type `obj`
"""
:update!
