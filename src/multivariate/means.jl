#-------------------------------------------------------# Type and Constructors
type Means{W <: Weighting} <: OnlineStat
    μ::VecF
    dim::Int64  # length of μ
    n::Int64
    weighting::W
end


function Means(y::MatF, wgt::Weighting = default(Weighting))
    o = Means(wgt, size(y, 2))
    update!(o, y)
    o
end
function Means(y::VecF, wgt::Weighting = default(Weighting))
    o = Means(wgt, length(y))
    update!(o, y)
    o
end
Means(wgt::Weighting = default(Weighting), dim = 2) = Means(zeros(dim), dim, 0, wgt)


#-----------------------------------------------------------------------# state

statenames(o::Means) = [:μ, :nobs]
state(o::Means) = Any[mean(o), nobs(o)]

Base.mean(o::Means) = o.μ

#---------------------------------------------------------------------# update!
function update!(o::Means, y::VecF)
    o.μ = smooth(o.μ, y, weight(o))
    o.n += 1
    return
end
-
function update!(o::Means, y::MatF)
    for i in 1:size(y,1)
        update!(o, vec(y[i, :]))
    end
end

function updatebatch!(o::Means, y::MatF)
    smooth!(o.μ, vec(mean(y, 1)), weight(o))
    o.n += size(y, 1)
    return
end

#------------------------------------------------------------------------# Base
function Base.empty!(o::Means)
    o.μ = zeros(o.p)
    o.n = 0
    return
end

function Base.merge!(o1::Means, o2::Means)
    λ = mergeweight(o1, o2)
    smooth!(o1.μ, o2.μ, λ)
    o1.n += nobs(o2)
    o1
end
