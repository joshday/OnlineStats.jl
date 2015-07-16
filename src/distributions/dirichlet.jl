#------------------------------------------------------# Type and Constructors
type FitDirichlet{W <: Weighting} <: DistributionStat
    d::Dirichlet
    meanlogx::Vector{Float64}
    n::Int64
    weighting::W
end

function onlinefit(::Type{Dirichlet}, y::AMatF, wgt::Weighting = default(Weighting))
    o = FitDirichlet(ncols(y), wgt)
    updatebatch!(o, y)
    o
end

FitDirichlet(y::AMatF, wgt::Weighting = default(Weighting)) =
    onlinefit(Dirichlet, y, wgt)

FitDirichlet(d::Integer = 2, wgt::Weighting = default(Weighting)) =
    FitDirichlet(Dirichlet(ones(d)), zeros(d), 0, wgt)


#---------------------------------------------------------------------# update!
# Since MLE is via Newton's method, it's much faster to do batch updates
function updatebatch!(o::FitDirichlet, y::AMatF)
    n2 = nrows(y)
    λ = weight(o, n2)
    o.meanlogx = smooth(o.meanlogx, vec(mean(log(y), 1)), λ)

    if o.n == 0 # fit_dirichlet! needs decent starting values
        o.d = fit_dirichlet!(o.meanlogx, exp((o.meanlogx)))
    else
        o.d = fit_dirichlet!(o.meanlogx, o.d.alpha)
    end
    o.n += n2
    return
end

update!(o::FitDirichlet, y::AVecF) = updatebatch!(o, y')

# function update!(o::FitDirichlet, y::Matrix{Float64})
#     for i in 1:size(y, 1)
#         updatebatch!(o, y[:, i])
#     end
# end

