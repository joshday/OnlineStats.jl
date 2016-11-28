# """
# `https://en.wikipedia.org/wiki/Bradley–Terry_model`
#
# ```julia
# o = BradleyTerryModel(5)  # 5 "teams"
# fit!(o, M)  # M is "win matrix": M[i, j] = # times i beat j
# ```
# """
# type BradleyTerryModel <: OnlineStat
#     value::VecF
#     B::Matrix{Int64}  # B[i, j] = # times team i beats team j
#     weight::EqualWeight
#     BradleyTerryModel(p::Integer) = new(zeros(p), zeros(Int64, p, p), EqualWeight())
# end
#
# function fit!{T <: Integer}(o::BradleyTerryModel, B::AMat{T})
#     @assert size(o.B) == size(B)
#     for i in eachindex(o.B)
#         o.B[i] += B[i]
#     end
#     θ = copy(o.value)
#     W = vec(sum(o.B, 2))
#     for j in eachindex(o.value), i in eachindex(o.value)
#
#     end
# end
