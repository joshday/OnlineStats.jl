"""
`https://en.wikipedia.org/wiki/Bradley–Terry_model`
"""
type BradleyTerryModel <: OnlineStat
    value::VecF
    B::Matrix{Int64}  # B[i, j] = # times team i beats team j
    weight::EqualWeight
    BradleyTerryModel(p::Integer) = new(zeros(p), zeros(Int64, p, p), EqualWeight())
end

function fit!{T <: Integer}(o::BradleyTerryModel, B::AMat{T})
    @assert size(o.B) == size(B)
    for i in eachindex(o.B)
        o.B[i] += B[i]
    end
    num = vec(sum(o.B, 1))
    # denom = num + sum(o)
    # oldval = copy(o.value)
    # for j in eachindex(o.value)
    #     o.value[j] = num[j] / (denom[j] / oldval)
    # end
end
