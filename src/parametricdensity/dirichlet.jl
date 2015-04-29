#------------------------------------------------------# Type and Constructors
type FitDirichlet{W <: Weighting} <: ScalarStat
    d::Dirichlet
    meanlogx::Vector{Float64}
    n::Int64
    weighting::W
end

function onlinefit(::Type{Dirichlet},
                   y::Array{Float64},
                   wgt::Weighting = DEFAULT_WEIGHTING)
    o = FitDirichlet(wgt; d = size(y, 1))
    update!(o, y)
    o
end

FitDirichlet(y::Array{Float64}, wgt::Weighting = DEFAULT_WEIGHTING) =
    onlinefit(Dirichlet, y, wgt)

FitDirichlet(wgt::Weighting = DEFAULT_WEIGHTING; d = 2) =
    FitDirichlet(Dirichlet([]), zeros(d), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::FitDirichlet) = [[symbol("α$i") for i in 1:length(o.meanlogx)]; :nobs]

state(o::FitDirichlet) = [o.d.alpha; o.n]


#---------------------------------------------------------------------# update!
# Since MLE is via Newton's method, it's MUCH faster to do batch updates
function update!(o::FitDirichlet, y::Matrix{Float64})
    n2 = size(y, 2)
    λ = weight(o, n2)
    o.meanlogx = smooth(o.meanlogx, vec(mean(log(y), 2)), λ)

    if isempty(o.d.alpha) # fit_dirichlet! needs good starting values
        o.d = fit_dirichlet!(o.meanlogx, exp(copy(o.meanlogx)))
    else
        o.d = fit_dirichlet!(o.meanlogx, o.d.alpha)
    end
    o.n += n2
    return
end

update!(o::FitDirichlet, y::Vector{Float64}) = update!(o, y')


#-----------------------------------------------------------------------# Base
Base.copy(o::FitDirichlet) = FitDirichlet(o.d, o.slogp, o.n, o.weighting)

