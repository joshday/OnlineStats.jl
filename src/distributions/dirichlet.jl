#------------------------------------------------------# Type and Constructors
type FitDirichlet{W <: Weighting} <: DistributionStat
    d::Dirichlet
    meanlogx::Vector{Float64}
    n::Int64
    weighting::W
end

function onlinefit(::Type{Dirichlet},
                   y::Array{Float64},
                   wgt::Weighting = default(Weighting))
    o = FitDirichlet(wgt; d = size(y, 1))
    batchupdate!(o, y)
    o
end

FitDirichlet(y::Array{Float64}, wgt::Weighting = default(Weighting)) =
    onlinefit(Dirichlet, y, wgt)

FitDirichlet(wgt::Weighting = default(Weighting); d = 2) =
    FitDirichlet(Dirichlet([]), zeros(d), 0, wgt)


#---------------------------------------------------------------------# update!
# Since MLE is via Newton's method, it's much faster to do batch updates
function batchupdate!(o::FitDirichlet, y::Matrix{Float64})
    n2 = size(y, 2)
    λ = weight(o, n2)
    o.meanlogx = smooth(o.meanlogx, vec(mean(log(y), 2)), λ)

    if isempty(o.d.alpha) # fit_dirichlet! needs decent starting values
        o.d = fit_dirichlet!(o.meanlogx, exp((o.meanlogx)))
    else
        o.d = fit_dirichlet!(o.meanlogx, o.d.alpha)
    end
    o.n += n2
    return
end

update!(o::FitDirichlet, y::Vector{Float64}) = batchupdate!(o, y')

function update!(o::FitDirichlet, y::Matrix{Float64})
    for i in 1:size(y, 2)
        batchupdate!(o, y[:, i]')
    end
end

