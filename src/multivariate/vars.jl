#-------------------------------------------------------# Type and Constructors
"Track the means of a data matrix, similar to `var(x, 1)`"
type Variances{W<:Weighting} <: OnlineStat
    μ::VecF
    biasedvar::VecF    # BIASED variance (makes for easier update)
    n::Int64
    weighting::W
end


function Variances(y::AMatF, wgt::Weighting = default(Weighting))
    o = Variances(size(y, 2), wgt)
    update!(o, y)
    o
end

function Variances(y::AVecF, wgt::Weighting = default(Weighting))
    o = Variances(length(y), wgt)
    update!(o, y)
    o
end

Variances(p::Integer, wgt::Weighting = default(Weighting)) =
    Variances(zeros(p), zeros(p), 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::Variances) = [:μ, :σ², :nobs]
state(o::Variances) = Any[mean(o), var(o), nobs(o)]

Base.mean(o::Variances) = copy(o.μ)
Base.var(o::Variances) = (n = nobs(o); (n < 2 ? zeros(length(o.μ)) : o.biasedvar * n / (n - 1)))
Base.std(o::Variances) = sqrt(var(o))

center(o::Variances, y::AVecF) = y - mean(o)
center!(o::Variances, y::AVecF) = (update!(o, y); center(o, y))
uncenter(o::Variances, y::AVecF) = y + mean(o)

function standardize!(o::Variances, y::AVecF)
    update!(o, y)
    ynew = (y - mean(o)) ./ (any(var(o) .== 0) ? 1 : std(o))
end

function standardize(o::Variances, y::AVecF)
    ynew = (y - mean(o)) ./ (any(var(o) .== 0) ? 1 : std(o))
end

function unstandardize(o::Variances, y::AVecF)
    nobs(o) < 2 ? y + mean(o) : y .* std(o) + mean(o)
end

#---------------------------------------------------------------------# update!
function update!(o::Variances, y::AVecF)
    λ = weight(o)
    μ = copy(o.μ)
    smooth!(o.μ, y, λ)
    smooth!(o.biasedvar, (y - μ) .* (y - mean(o)), λ)
    o.n += 1
    return
end

function update!(o::Variances, y::AMatF)
    for i in 1:size(y, 1)
        update!(o, vec(y[i, :]))
    end
    return
end

function updatebatch!(o::Variances, y::AMatF)
    n2 = size(y, 1)
    λ = weight(o, n2)
    smooth!(o.μ, vec(mean(y, 1)), λ)
    smooth!(o.biasedvar, vec(var(y, 1)) * ((n2 - 1) / n2), λ)
    o.n += n2
    return
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
