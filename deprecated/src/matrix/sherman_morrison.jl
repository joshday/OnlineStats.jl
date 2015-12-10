#--------------------------------------------------------# Type and Constructors
"""
Online update of `inv(X'X) / n`.

`ShermanMorrisonInverse(X, wgt = default(Weighting), ϵ = 1.0)`

`ϵ` is the starting diagonal value to ensure invertibility.  This value shouldn't
matter much.  It is essentially a ridge term that shrinks to zero.
"""
type ShermanMorrisonInverse{W <: Weighting} <: OnlineStat
    A::MatF         # The matrix inverse.  Initializes to ϵ * eye(p)
    n::Int
    weighting::W
    ϵ::Float64      # Ridge term to ensure invertibility
    v::VecF         # Placeholder for o.A * u
end

function ShermanMorrisonInverse(p::Integer, wgt::Weighting = default(Weighting);
        ϵ::Float64 = 1.0)
    ShermanMorrisonInverse(ϵ * eye(p), 1, wgt, ϵ, zeros(p))
end

function ShermanMorrisonInverse(x::MatF, wgt::Weighting = default(Weighting); keyargs...)
    o = ShermanMorrisonInverse(size(x,2), wgt; keyargs...)
    update!(o, x)
    o
end

#----------------------------------------------------------------------# update!
function update!(o::ShermanMorrisonInverse, u::AVecF)
    # This looks hacky, but avoids A LOT of memory allocation
    p = length(u)
    γ = weight(o)
    δ = 1.0 / (1.0 - γ)

    # v = A * u
    fill!(o.v, 0.0)
    for j in 1:p, i in 1:p
        o.v[i] += o.A[i, j] * u[j]
    end

    # update A
    γ2 = γ / (δ + γ * dot(o.v, u))
    for j in 1:p, i in 1:p
        o.A[i, j] = o.A[i, j] * δ - γ2 * o.v[i] * o.v[j]
    end
    o.n += 1
end

#------------------------------------------------------------------------# state
statenames(o::ShermanMorrisonInverse) = [:Ainv, :nobs]
state(o::ShermanMorrisonInverse) = Any[copy(o.A), nobs(o)]
Base.inv(o::ShermanMorrisonInverse) = o.A
