function tracefit!(o::OnlineStat, b::Int64, args...; batch = false)

    # Create DataFrame
    n = size(args[1],1)
    i = 1
    result = [state(o)']

    # Update DataFrame with each batch
    while i <= n
        rng = i:min(i + b - 1, n)
        batch_args = map(x -> getrows(x, rng), args)
        batch ? updatebatch!(o, batch_args...) : update!(o, batch_args...)
        result = vcat(result, state(o)')
        i += b
    end

    result
end
