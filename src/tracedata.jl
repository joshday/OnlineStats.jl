"""
`tracedata(obj, y, b, args...)`

Create data for traceplot using starting value `obj`.

### Arguments:
* `obj`       : Subtype of OnlineStat
* `y`         : data
* `b`         : batch size to update estimates with
* `args`      : additional arguments passed to `OnlineStat()`

### Returns:
* `obj` updated with data in `y`
* DataFrame with trace data
"""
:tracedata


function DataFrames.DataFrame{T <: ScalarStat}(obj::T)
    DataFrames.DataFrame(variable = state_names(obj),
                         value = state(obj),
                         nobs = nobs(obj))
end


function tracedata{T <: ScalarStat}(obj::Type{T}, y::Array, b::Int64; args...)
    # Create object with first batch
    n = length(y)
    ind = 1:b
    df = DataFrame(obj)

    # Update DataFrame with each batch
    for i in 2:n/b
        ind += b
        copy!(ybatch, y[ind])
        update!(obj, ybatch)
        addstate!(df, obj)
    end

    return obj, df
end
