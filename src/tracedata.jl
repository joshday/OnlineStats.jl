"""
`tracedata(o, y, b, args...)`

Create data for traceplot using starting value `o`.

### Arguments:
* `o`         : Subtype of OnlineStat
* `y`         : data
* `b`         : batch size to update estimates with
* `args`      : data in the form that update!(o, args...) accepts`

### Returns:
* `o` updated with data in `y`
* DataFrame with trace data
"""
:tracedata


getrows(x::Vector, rows) = x[rows]
getrows(x::Matrix, rows) = x[rows, :]

function tracedata(o::OnlineStat, b::Int64, args...; batch = false)

    # Create DataFrame
    n = size(args[1],1)
    i = 1
    df = DataFrame(o; addFirstRow = false)

    # Update DataFrame with each batch
    while i <= n
        rng = i:min(i + b - 1, n)
        batch_args = map(x -> getrows(x, rng), args)
        batch ? updatebatch!(o, batch_args...) : update!(o, batch_args...)
        push!(df, o)
        i += b
    end

    df
end



# For OnlineStats with vector output, put the DataFrame created by tracedata()
# in a nicer structure (for making traceplots).
#
# The function appends DataFrames created from each row

function unpack_vectors(df::DataFrame, indexchar::String = "β")
    n, p = size(df)
    dfnames = names(df)
    resultdf = DataFrame()

    # Get first row as DataFrame.  Gets correct names and eltypes for append!()
    for j in 1:p
        resultdf[dfnames[j]] = copy(df[1, j])
    end

    # add column for variable (index of the vector)
    colvec = [symbol("$indexchar$i") for i in 1:size(resultdf, 1)]
    resultdf[:variable] = copy(colvec)

    # For each row, make a DataFrame and append it to resultdf
    for i in 2:n
        tempdf = DataFrame()
        for j in 1:p
            tempdf[dfnames[j]] = copy(df[i, j])
        end
        tempdf[:variable] = copy(colvec)
        append!(resultdf, tempdf)
    end

    resultdf
end


function unpack_distributions(df)
    typeof(df[1,1]) <: UnivariateDistribution ||
        error("First row does not have UnivariateDistribution")

    # create first row to get correct names and data types
    resultdf = convert(DataFrame, [params(df[1,1])...]')
    @compat resultdf[:nobs] = Int(df[1,end])
    names!(resultdf, [names(df[1,1]); :nobs])

    p = length(params(df[1,1]))

    for i in 2:size(df, 1)
        push!(resultdf, [[params(df[i,1])...]; df[i, end]])
    end
    resultdf
end
