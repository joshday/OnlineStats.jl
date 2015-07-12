#-------------------------------------------------------# Type and Constructors
type Means{W <: Weighting} <: OnlineStat
    μ::VecF
    p::Int  # length of μ
    n::Int
    weighting::W
end


function Means(y::AMatF, wgt::Weighting = default(Weighting))
    o = Means(size(y, 2), wgt)
    update!(o, y)
    o
end
function Means(y::AVecF, wgt::Weighting = default(Weighting))
    o = Means(length(y), wgt)
    update!(o, y)
    o
end
Means(p::Int, wgt::Weighting = default(Weighting)) = Means(zeros(p), p, 0, wgt)


#-----------------------------------------------------------------------# state

statenames(o::Means) = [:μ, :nobs]
state(o::Means) = Any[mean(o), nobs(o)]

Base.mean(o::Means) = copy(o.μ)


center(o::Means, y::AVecF) = y - mean(o)
center!(o::Means, y::AVecF) = (update!(o, y); center(o, y))
uncenter(o::Means, y::AVecF) = y + mean(o)

#---------------------------------------------------------------------# update!
function update!(o::Means, y::AVecF)
    smooth!(o.μ, y * 1.0, weight(o))  # "* 1.0" used to convert y to VecF
    o.n += 1
    return
end

function update!(o::Means, y::MatF)
    for i in 1:size(y,1)
        update!(o, rowvec_view(y, i))
    end
end

function updatebatch!(o::Means, y::AMatF)
    n2 = size(y, 1)
    smooth!(o.μ, vec(mean(y, 1)), weight(o, n2))
    o.n += n2
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
