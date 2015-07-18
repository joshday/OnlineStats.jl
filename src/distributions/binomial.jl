#------------------------------------------------------# Type and Constructors
type FitBinomial{W <: Weighting} <: DistributionStat
    d::Binomial
    n::Int64
    weighting::W
end

function distributionfit{T <: Integer}(::Type{Binomial}, y::AVec{T}, wgt::Weighting = default(Weighting); n = 1)
    o = FitBinomial(wgt, n = n)
    update!(o, y)
    o
end

FitBinomial{T <: Integer}(y::AVec{T}, wgt::Weighting = default(Weighting); n = 1) =
    distributionfit(Binomial, y, wgt, n = n)

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
