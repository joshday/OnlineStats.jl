export trace_df

function trace_df{T <: OnlineStat}(::Type{T}, y::Array, b::Int64; args...)
    T <: MatrixvariateOnlineStat &&
        error("Matrixvariate estimates do not work with trace_df")

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


# function trace_df{T <: UnivariateOnlineStat, S <: UnivariateOnlineStat}(
#         ::Type{T}, ::Type{S}, y::Vector, b::Int64)

#     n = length(y)
#     ind = 1:b
#     ybatch = y[ind]
#     obj1 = T(ybatch)
#     obj2 = S(ybatch)
#     df = state(obj1)
#     addstate!(df, obj2)

#     for i in 2:n/b
#         ind += b
#         copy!(ybatch, y[ind])
#         update!(obj1, ybatch)
#         update!(obj2, ybatch)
#         addstate!(df, obj1)
#         addstate!(df, obj2)
#     end

#     return obj, df
# end
