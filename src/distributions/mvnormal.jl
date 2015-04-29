#-------------------------------------------------------# Type and Constructors
type FitMvNormal{W <: Weighting} <: MatrixStat
    d::MvNormal
    c::CovarianceMatrix{W}
    n::Int64
    weighting::W
end

function onlinefit(::Type{MvNormal},
                   y::Matrix{Float64},
                   wgt::Weighting = default(Weighting))
    o = FitMvNormal(wgt; d = size(y, 1))
    update!(o, y)
    o
end

FitMvNormal(y::Matrix{Float64}, wgt::Weighting = default(Weighting)) =
    onlinefit(MvNormal, y, wgt)

FitMvNormal(wgt::Weighting = default(Weighting); d = 2) =
    FitMvNormal(MvNormal(zeros(d), eye(2)), CovarianceMatrix(wgt), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::FitMvNormal) = [:μ, :Σ, :nobs]

state(o::FitMvNormal) = Any[o.d.μ, o.d.Σ.mat, o.n]

#---------------------------------------------------------------------# update!
function update!(o::FitMvNormal, newdata::Matrix{Float64})
    update!(o.c, newdata')
    o.n = nobs(o.c)
    o.d = MvNormal(mean(o.c), cov(o.c))
end

#------------------------------------------------------------------------# Base
function Base.show(io::IO, o::FitMvNormal)
    println(io, "Online ", string(typeof(o)))
    print(" * ")
    show(o.d)
    @printf(io, " * %s:  %d\n", :nobs, nobs(o))
end
