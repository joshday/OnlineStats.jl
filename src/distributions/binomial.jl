#------------------------------------------------------# Type and Constructors
type FitBinomial{W <: Weighting} <: DistributionStat
    d::Binomial
    n::Int64
    weighting::W
end

function onlinefit{T <: Integer}(::Type{Binomial}, y::Vector{T}, wgt::Weighting = default(Weighting); n = 1) # n = number of independent Bernoulli trials
    o = FitBinomial(wgt, n = n)
    update!(o, y)
    o
end

FitBinomial{T <: Integer}(y::Vector{T}, wgt::Weighting = default(Weighting); n = 1) =
    onlinefit(Binomial, y, wgt, n = n)

FitBinomial(wgt::Weighting = default(Weighting); n = 1) =
    FitBinomial(Binomial(n, 0), 0, wgt)


#---------------------------------------------------------------------# update!
function update!(o::FitBinomial, y::Integer)
    λ = weight(o)
    p = smooth(o.d.p, @compat(Float64(y / o.d.n)), λ)
    o.d = Binomial(o.d.n, p)
    o.n += 1
    return
end
