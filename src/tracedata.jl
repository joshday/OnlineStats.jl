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

# This is very cool.
# adjusted to take the batch size first
function tracedata(o::OnlineStat, b::Int64, args...)
    # Create object with first batch
    n = size(args[1],1)
    rng = 1:b
    df = DataFrame(o)

    # Update DataFrame with each batch
    for i in 1:n/b
        batch_args = map(x->getrows(x,rng), args)
        update!(o, batch_args...)
        push!(df, o)
        rng += b
    end

    df
end
