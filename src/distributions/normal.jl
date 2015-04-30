
#-------------------------------------------------------# Type and Constructors
type FitNormal{W <: Weighting} <: OnlineStat
    d::Normal
    v::Var{W}
    n::Int64
    w::W
end

function onlinefit(::Type{Normal},
                   y::Vector{Float64},
                   wgt::Weighting = default(Weighting))
    o = FitNormal(wgt)
    update!(o, y)
    o
end

FitNormal(y::Vector{Float64}, wgt::Weighting = default(Weighting)) =
    onlinefit(Normal, y, wgt)

FitNormal(wgt::Weighting = default(Weighting)) = FitNormal(Normal(), Var(wgt), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::FitNormal) = [:μ, :σ, :nobs]

state(o::FitNormal) = [o.d.μ, o.d.σ, o.n]

#---------------------------------------------------------------------# update!
function update!{T<:Real}(obj::FitNormal, newdata::Vector{T})
    update!(obj.v, newdata)
    obj.n = nobs(obj.v)
    obj.d = Normal(mean(obj.v), sqrt(var(obj.v)))
end
