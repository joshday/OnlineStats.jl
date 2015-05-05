#-------------------------------------------------------# Type and Constructors
type Variances{W<:Weighting} <: OnlineStat
    μ::VecF
    biasedvar::VecF    # BIASED variance (makes for easier update)
    n::Int64
    weighting::W
end


function Variances(y::MatF, wgt::Weighting = default(Weighting))
    o = Variances(size(y, 2), wgt)
    update!(o, y)
    o
end

function Variances(y::VecF, wgt::Weighting = default(Weighting))
    o = Variances(length(y), wgt)
    update!(o, y)
    o
end

Variances(p::Int, wgt::Weighting = default(Weighting)) =
    Variances(zeros(p), zeros(p), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::Variances) = [:μ, :σ², :nobs]
state(o::Variances) = Any[mean(o), var(o), nobs(o)]

Base.mean(o::Variances) = copy(o.μ)
Base.var(o::Variances) = (n = nobs(o); (n < 2 ? zeros(length(o.μ)) : o.biasedvar * n / (n - 1)))
Base.std(o::Variances) = sqrt(var(o))


#---------------------------------------------------------------------# update!
function update!(o::Variances, y::VecF)
    λ = weight(o)
    μ = copy(o.μ)
    smooth!(o.μ, y, λ)
    smooth!(o.biasedvar, (y - μ) .* (y - mean(o)), λ)
    o.n += 1
    return
end

function update!(o::Variances, y::MatF)
    for i in 1:size(y, 1)
        update!(o, vec(y[i, :]))
    end
    return
end

function standardize!(o::Variances, y::VecF)
    update!(o, y)
    ynew = (y - mean(o)) ./ (any(var(o) .== 0) ? 1 : std(o))
end

function standardize(o::Variances, y::VecF)
    ynew = (y - mean(o)) ./ (any(var(o) .== 0) ? 1 : std(o))
end

#------------------------------------------------------------------------# Base
function Base.empty!(o::Variances)
    p = length(o.μ)
    o.μ = zeros(p)
    o.biasedvar = zeros(p)
    o.n = 0
    return
end

function Base.merge!(o1::Variances, o2::Variances)
    λ = mergeweight(o1, o2)
    smooth!(o1.μ, o2.μ, λ)
    smooth!(o1.biasedvar, o2.biasedvar, λ)
    o1.n += nobs(o2)
    o1
end



