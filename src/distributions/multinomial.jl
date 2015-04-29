#-------------------------------------------------------# Type and Constructors
type FitMultinomial{W <: Weighting} <: OnlineStat
    d::Multinomial
    means::Vector{Float64}
    n::Int64
    weighting::W
end

function onlinefit{T <: Integer}(::Type{Multinomial},
                                 y::Matrix{T},
                                 wgt::Weighting = DEFAULT_WEIGHTING)
    o = FitMultinomial(wgt)
    update!(o, y)
    o
end

FitMultinomial{T <: Integer}(y::Matrix{T}, wgt::Weighting = DEFAULT_WEIGHTING) =
    onlinefit(Multinomial, y, wgt)

function FitMultinomial(wgt::Weighting = DEFAULT_WEIGHTING)
    FitMultinomial(Multinomial(1, [0., 1.]), zeros(0), 0, wgt)
end


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
Base.copy(o::FitMultinomial) = FitMultinomial(o.d, o.means, o.n, o.weighting)

function Base.show(io::IO, o::FitMultinomial)
    snames = statenames(o)
    svals = state(o)

    println(io, "Online ", string(typeof(o)))
    @printf(io, " * %s:  %d\n", snames[1], svals[1])
    for i in 2:length(snames) - 1
        @printf(io, " * %s:  %f\n", snames[i], svals[i])
    end
    @printf(io, " * %s:  %d\n", snames[end], svals[end])
end

function DataFrame(o::FitMultinomial)
    df = convert(DataFrame, state(o)')
    names!(df, statenames(o))
end

Base.push!(df::DataFrame, o::FitMultinomial) = push!(df, state(o))
