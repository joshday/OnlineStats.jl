mutable struct MVStats{OS <: Tuple, W <: Weight} <: AbstractStats
    weight::W
    stats::OS
    nobs::Int
    nups::Int
end
MVStats(wt::Weight, args...) = MVStats(wt, args, 0, 0)
MVStats(args...; weight::Weight = EqualWeight()) = MVStats(weight, args, 0, 0)
function MVStats(y::AMat, args...; weight::Weight = EqualWeight())
    o = MVStats(weight, args...)
    fit!(o, y)
    o
end

function fit!(o::MVStats, y::AVec, γ::Float64 = nextweight(o))
    updatecounter!(o)
    for stat in o.stats
        fit!(stat, y, γ)
    end
    o
end
function fit!(o::MVStats, y::AMat)
    for i in 1:size(y, 1)
        fit!(o, getobs(y, i))
    end
    o
end

#-------------------------------------------------------------------------# CovMatrix
struct CovMatrix <: OnlineStat{VectorInput}
    value::MatF
    cormat::MatF
    A::MatF  # X'X / n
    b::VecF  # X * 1' / n (column means)
end
function CovMatrix(p::Integer)
    CovMatrix(zeros(p, p), zeros(p, p), zeros(p, p), zeros(p))
end
function fit!(o::CovMatrix, x::AVec, γ::Float64)
    smooth!(o.b, x, γ)
    smooth_syr!(o.A, x, γ)
    o
end
function fitbatch!(o::CovMatrix, x::AMat, γ::Float64)
    smooth!(o.b, mean(x, 1), γ)
    smooth_syrk!(o.A, x, γ)
end
function value(o::CovMatrix)
    o.value[:] = full(Symmetric((o.A - o.b * o.b')))
end
Base.mean(o::CovMatrix) = o.b
Base.cov(o::CovMatrix) = value(o)
Base.var(o::CovMatrix) = diag(value(o))
Base.std(o::CovMatrix) = sqrt.(var(o))
function Base.cor(o::CovMatrix)
    copy!(o.cormat, value(o))
    v = 1.0 ./ sqrt.(diag(o.cormat))
    scale!(o.cormat, v)
    scale!(v, o.cormat)
    o.cormat
end
# function _merge!(o::CovMatrix, o2::CovMatrix, γ::Float64)
#     smooth!(o.A, o2.A, γ)
#     smooth!(o.b, o2.b, γ)
# end

# #-----------------------------------------------------------------------------# Means
# type Means <: OnlineStat{VectorInput}
#     value::VecF
# end
# Means(p::Int, wgt::Weight = EqualWeight()) = Means(zeros(p), wgt)
# _fit!(o::Means, y::AVec, γ::Float64) = smooth!(o.value, y, γ)
# function _fitbatch!{W <: BatchWeight}(o::Means{W}, y::AMat, γ::Float64)
#     smooth!(o.value, row(mean(y, 1), 1), γ)
# end
# Base.mean(o::Means) = value(o)
# center{T<:Real}(o::Means, x::AVec{T}) = x - mean(o)
# _merge!(o::Means, o2::Means, γ) = _fit!(o, mean(o2), γ)
