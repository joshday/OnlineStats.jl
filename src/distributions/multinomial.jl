#-------------------------------------------------------# Type and Constructors
type FitMultinomial{W <: Weighting} <: OnlineStat
    d::Multinomial
    means::Vector{Float64}
    n::Int64
    weighting::W
end

function onlinefit{T <: Integer}(::Type{Multinomial},
                                 y::Matrix{T},
                                 wgt::Weighting = default(Weighting))
    o = FitMultinomial(wgt)
    update!(o, y)
    o
end

FitMultinomial{T <: Integer}(y::Matrix{T}, wgt::Weighting = default(Weighting)) =
    onlinefit(Multinomial, y, wgt)

FitMultinomial(wgt::Weighting = default(Weighting)) =
    FitMultinomial(Multinomial(1, [0., 1.]), zeros(0), 0, wgt)



#-----------------------------------------------------------------------# state
statenames(o::FitMultinomial) = [:n; [symbol("p$i") for i in 1:length(o.d.p)]; :nobs]

state(o::FitMultinomial) = [o.d.n, o.d.p, o.n]


#---------------------------------------------------------------------# update!
function update!{T <: Integer}(o::FitMultinomial, x::Vector{T})
    p = length(x)
    λ = weight(o)
    if !isempty(o.means)
        o.means = smooth(o.means, mean(x, 2), λ)
        n = o.d.n
    else
        o.means = smooth(zeros(p), mean(x, 2), λ)
        n = sum(x)
    end
    o.n += 1
    o.d = Multinomial(n, o.means / sum(o.means))
end

function update!(o::FitMultinomial, x::Matrix)
    for i in 1:size(x, 2)
        update!(o, x[:, i])
    end
end


#------------------------------------------------------------------------# Base
function Base.show(io::IO, o::FitMultinomial)
    println(io, "Online ", string(typeof(o)))
    print(" * ")
    show(o.d)
    println()
    @printf(io, " * %s:  %d\n", :nobs, nobs(o))
end
