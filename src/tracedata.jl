"""
`tracedata(OnlineStat, y, b, args...)`

For OnlineStat types which estimate scalars, create data for traceplot.

### Arguments:
* `OnlineStat`: Subtype of OnlineStat
* `y`         : data
* `b`         : batch size to update estimates with
* `args`      : additional arguments passed to `OnlineStat()`

### Returns:
* object of type `OnlineStat`
* DataFrame with trace data
"""
function tracedata{T <: ScalarOnlineStat}(::Type{T}, y::Array, b::Int64; args...)
    # Create object with first batch
    n = length(y)
    ind = 1:b
    ybatch = y[ind]
    obj = T(ybatch; args...)
    df = state(obj)

    # Update DataFrame with each batch
    for i in 2:n/b
        ind += b
        copy!(ybatch, y[ind])
        update!(obj, ybatch)
        addstate!(df, obj)
    end

    return obj, df
end
