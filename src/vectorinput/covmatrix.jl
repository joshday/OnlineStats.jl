#-------------------------------------------------------------------------# CovMatrix
mutable struct CovMatrix <: OnlineStat{VectorIn, MatrixOut}
    value::MatF
    cormat::MatF
    A::MatF  # X'X / n
    b::VecF  # X * 1' / n (column means)
    nobs::Int
    CovMatrix(p::Integer) = new(zeros(p, p), zeros(p, p), zeros(p, p), zeros(p), 0)
end
function fit!(o::CovMatrix, x::AVec, γ::Float64)
    smooth!(o.b, x, γ)
    smooth_syr!(o.A, x, γ)
    o.nobs += 1
    o
end
function fitbatch!(o::CovMatrix, x::AMat, γ::Float64)
    smooth!(o.b, mean(x, 1), γ)
    smooth_syrk!(o.A, x, γ)
    o.nobs += size(x, 1)
    o
end
function value(o::CovMatrix)
    o.value[:] = full(Symmetric((o.A - o.b * o.b')))
    scale!(o.value, unbias(o))
end
Base.length(o::CovMatrix) = length(o.b)
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
function Base.merge!(o::CovMatrix, o2::CovMatrix, γ::Float64)
    smooth!(o.A, o2.A, γ)
    smooth!(o.b, o2.b, γ)
    o.nobs += o2.nobs
    o
end
