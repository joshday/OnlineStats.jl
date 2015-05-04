"""
`tracedata(o, y, b, args...)`

Create data for traceplot using starting value `o`.

### Arguments:
* `o`         : Subtype of OnlineStat
* `y`         : data
* `b`         : batch size to update estimates with
* `args`      : additional arguments, first of which is data`

### Returns:
* `o` updated with data in `y`
* DataFrame with trace data
"""
:tracedata


getrows(x::Vector, rows) = x[rows]
getrows(x::Matrix, rows) = x[rows,:]


# adjusted to take the batch size first
function tracedata(o::OnlineStat, b::Int64, args...; batch = false)

    # Create DataFrame
    n = size(args[1],1)
    i = 1
    df = DataFrame(o; addFirstRow = false)

    # Update DataFrame with each batch
    while i <= n
        rng = i:min(i+b-1,n)
        batch_args = map(x->getrows(x,rng), args)
        batch? updatebatch!(o, batch_args...) : update!(o, batch_args...)
        push!(df, o)
        i += b
    end

    df
end
