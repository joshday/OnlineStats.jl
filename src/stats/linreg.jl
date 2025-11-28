#-----------------------------------------------------------------------# LinReg
"""
    LinReg()

Linear regression, optionally with element-wise ridge regularization.

# Example

```julia
x = randn(100, 5)
y = x * (1:5) + randn(100)
o = fit!(LinReg(), zip(eachrow(x),y))
coef(o)
coef(o, .1)
coef(o, [0,0,0,0,Inf])
```
"""
mutable struct LinReg{W} <: OnlineStat{XY}
    β::Vector{Float64}
    A::Matrix{Float64}
    weight::W
    n::Int
end
LinReg(p=0;weight=EqualWeight()) = LinReg(zeros(p), zeros(1, 1), weight, 0)

function _fit!(o::LinReg, xy)
    γ = o.weight(o.n += 1)
    x, y = xy
    if o.n == 1
        p = length(x)
        o.β = zeros(p)
        o.A = zeros(p + 1, p + 1)
    end
    for j in 1:(size(o.A, 2)-1)
        xj = x[j]
        o.A[j, end] = smooth(o.A[j, end], xj * y, γ)    # x'y
        for i in 1:j
            o.A[i, j] = smooth(o.A[i,j], x[i] * xj, γ)  # x'x
        end
    end
    o.A[end] = smooth(o.A[end], y * y, γ)  # y'y
end
value(o::LinReg, args...) = coef(o, args...)
function coef(o::LinReg)
    o.β[:] = Symmetric(o.A[1:(end-1), 1:(end-1)]) \ o.A[1:(end-1), end]
end
function coef(o::LinReg, λ::Real)
    o.β[:] = Symmetric(o.A[1:(end-1), 1:(end-1)] + λ*I) \ o.A[1:(end-1), end]
end
function coef(o::LinReg, λ::AbstractVector{<:Real})
    o.β[:] = Symmetric(o.A[1:(end-1), 1:(end-1)] + Diagonal(λ)) \ o.A[1:(end-1), end]
end

predict(o::LinReg, x::AbstractVector) = x'o.β
predict(o::LinReg, x::AbstractMatrix) = x * o.β

function _merge!(o::LinReg, o2::LinReg)
    o.n += o2.n
    smooth!(o.A, o2.A, nobs(o2) / nobs(o))
end

#-----------------------------------------------------------------------# LinRegBuilder
"""
    LinRegBuilder(p)

Create an object from which any variable can be regressed on any other set of variables,
optionally with element-wise ridge regularization.  The main function to use with
`LinRegBuilder` is `coef`:

```julia
coef(o::LinRegBuilder, λ = 0; y=1, x=[2,3,...], bias=true, verbose=false)
```

Return the coefficients of a regressing column `y` on columns `x` with ridge (`abs2` penalty)
parameter `λ`.  An intercept (`bias`) term is added by default.

# Examples

```julia
x = randn(1000, 10)
o = fit!(LinRegBuilder(), eachrow(x))

coef(o; y=3, verbose=true)

coef(o; y=7, x=[2,5,4])
```
"""
mutable struct LinRegBuilder{W} <: OnlineStat{VectorOb{Number}}
    A::Matrix{Float64}  #  x'x, pretend that x = [x, 1]
    weight::W
    n::Int
end
function LinRegBuilder(p=0; weight = EqualWeight())
    LinRegBuilder(Matrix{Float64}(undef, p + 1, p + 1), weight, 0)
end
function Base.show(io::IO, o::LinRegBuilder)
    print(io, "LinRegBuilder of $(nvars(o)) variables")
end
nvars(o::LinRegBuilder) = size(o.A, 1) - 1

function _fit!(o::LinRegBuilder, x)
    o.n += 1
    if o.n == 1
        o.A = zeros(length(x) + 1, length(x) + 1)
        o.A[end] = 1.0
    end
    smooth_syr!(o.A, BiasVec(x), o.weight(o.n))
end
value(o::LinRegBuilder, args...) = coef(o, args...)

xs(o::LinRegBuilder, y) = setdiff(1:size(o.A, 1) - 1, y)
function add_diag!(S, λ::Number)
    for i in 1:(size(S, 1) - 1)
        S[i, i] += λ
    end
end
function add_diag!(S, λ::AbstractVector)
    for i in 1:(size(S, 1) - 1)
        S[i, i] += λ[i]
    end
end

function coef(o::LinRegBuilder, λ=0.0; y=1, x=xs(o,y), bias=true, verbose=false)
    verbose && @info("Regress $y on $x $(bias ? "with bias" : "")")
    inds = collect(x)
    bias && push!(inds, size(o.A, 1))
    push!(inds, y)
    S = Symmetric(o.A)[inds, inds]
    add_diag!(S, λ)
    p = length(inds) - 1
    return S[1:p, 1:p] \ S[1:p, end]
end

function _merge!(o::LinRegBuilder, o2::LinRegBuilder)
    o.n += o2.n
    smooth!(o.A, o2.A, nobs(o2) / nobs(o))
end
