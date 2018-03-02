# Sufficient statistics for one variable
mutable struct VarSummary{T}
    stats::SortedDict{T, Hist{0, AdaptiveBins{Float64}}}
    b::Int
    j::Int
end
Base.show(io::IO, o::VarSummary) = print(io, "VarSummary ", o.id)

function VarSummary(T::Type, j::Int; b = 10)
    VarSummary(SortedDict{T, Hist{0, AdaptiveBins{Float64}}}(), b, j)
end

