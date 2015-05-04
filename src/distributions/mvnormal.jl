#-------------------------------------------------------# Type and Constructors
type FitMvNormal{W <: Weighting} <: DistributionStat
    d::MvNormal
    c::CovarianceMatrix{W}
    n::Int64
    weighting::W
end

function onlinefit(::Type{MvNormal},
                   y::Matrix{Float64},
                   wgt::Weighting = default(Weighting))
    o = FitMvNormal(size(y, 1), wgt)
    updatebatch!(o, y)
    o
end

FitMvNormal(y::Matrix{Float64}, wgt::Weighting = default(Weighting)) =
    onlinefit(MvNormal, y, wgt)

FitMvNormal(p::Int, wgt::Weighting = default(Weighting)) =
    FitMvNormal(MvNormal(zeros(p), eye(p)), CovarianceMatrix(p, wgt), 0, wgt)


#---------------------------------------------------------------------# update!
function updatebatch!(o::FitMvNormal, y::MatF)
    updatebatch!(o.c, y')
    o.n = nobs(o.c)
    o.d = MvNormal(mean(o.c), cov(o.c))
end

# update!(o::FitMvNormal, y::Vector{Float64}) = updatebatch!(o, y')


#------------------------------------------------------------------------# Base
function Base.show(io::IO, o::FitMvNormal)
    println(io, "Online ", string(typeof(o)))
    print(" * ")
    show(o.d)
    @printf(io, " * %s:  %d\n", :nobs, nobs(o))
end
