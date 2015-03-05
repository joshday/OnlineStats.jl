export trace_df

function trace_df{T<:ContinuousUnivariateOnlineStat}(::Type{T}, y::Vector,
                                                  b::Int64; args...)
    n = length(y)
    ybatch = y[1:b]
    obj = T(ybatch; args...)
    df = make_df(obj)

    for i in 2:n/b
        ind = b * (i - 1) + 1 : b*i
        ybatch = y[ind]
        update!(obj, ybatch)
        make_df!(df, obj)
    end

    return obj, df
end


function trace_df{T<:ContinuousUnivariateOnlineStat}(::Type{T}, y::Vector,
                                                  b::Int64, start=0; args...)
    n = length(y)
    ybatch = y[1:b]
    obj = T([0]; args...)
    df = make_df(obj)

    for i in 1:n/b
        ind = b * (i - 1) + 1 : b*i
        ybatch = y[ind]
        update!(obj, ybatch)
        make_df!(df, obj)
    end

    return obj, df
end


# Testing:
# x = rand(Gamma(5,1), 10000)
# qtrace = OnlineStats.trace_df(OnlineStats.QuantileSGD, x, 10, τ = [.7], r=.6)
# qtrace[1]
# qtrace[2]
