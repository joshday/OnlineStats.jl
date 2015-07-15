#-------------------------------------------------------# Type and Constructors
type FitMultinomial{W <: Weighting} <: DistributionStat
    d::Multinomial
    means::VecF
    n::Int
    weighting::W
end

function onlinefit{T <: Integer}(::Type{Multinomial}, y::Matrix{T}, wgt::Weighting = default(Weighting))
    o = FitMultinomial(wgt)
    update!(o, y)
    o
end

FitMultinomial{T <: Integer}(y::Matrix{T}, wgt::Weighting = default(Weighting)) =
    onlinefit(Multinomial, y, wgt)

FitMultinomial(wgt::Weighting = default(Weighting)) =
    FitMultinomial(Multinomial(1, [0., 1.]), zeros(0), 0, wgt)


#---------------------------------------------------------------------# update!
function update!{T <: Integer}(o::FitMultinomial, x::Vector{T})
    p = length(x)
    λ = weight(o)

    if !isempty(o.means)
        @compat smooth!(o.means, VecF(x), λ)
        n = o.d.n
    else
        o.means = zeros(p)
        @compat smooth!(o.means, VecF(x), λ)
        n = sum(x)
    end

    o.n += 1
    o.d = Multinomial(n, o.means / sum(o.means))
end

function update!(o::FitMultinomial, x::Matrix)
    for i in 1:size(x, 1)
        update!(o, vec(x[i, :]))
    end
end
