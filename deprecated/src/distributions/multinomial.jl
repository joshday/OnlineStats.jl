#-------------------------------------------------------# Type and Constructors
type FitMultinomial{W <: Weighting} <: DistributionStat
    d::Dist.Multinomial
    means::VecF
    n::Int
    weighting::W
end

function distributionfit{T <: Integer}(::Type{Dist.Multinomial}, y::AMat{T}, wgt::Weighting = default(Weighting))
    o = FitMultinomial(wgt)
    update!(o, y)
    o
end

FitMultinomial{T <: Integer}(y::AMat{T}, wgt::Weighting = default(Weighting)) =
    distributionfit(Dist.Multinomial, y, wgt)

FitMultinomial(wgt::Weighting = default(Weighting)) =
    FitMultinomial(Dist.Multinomial(1, [0., 1.]), zeros(0), 0, wgt)


#---------------------------------------------------------------------# update!
function update!{T <: Integer}(o::FitMultinomial, x::AVec{T})
    p = length(x)
    λ = weight(o)

    if !isempty(o.means)
        smooth!(o.means, ([Float64(xi) for xi in x]), λ)
        n = o.d.n
    else
        o.means = zeros(p)
        smooth!(o.means, ([Float64(xi) for xi in x]), λ)
        n = sum(x)
    end

    o.n += 1
    o.d = Dist.Multinomial(n, o.means / sum(o.means))
end

# function update!(o::FitMultinomial, x::Matrix)
#     for i in 1:size(x, 1)
#         update!(o, vec(x[i, :]))
#     end
# end
