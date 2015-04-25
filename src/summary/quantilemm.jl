export QuantileMM

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type QuantileMM <: MultivariateOnlineStat
    est::Vector{Float64}              # Quantiles
    τ::Vector{Float64}                # tau values
    r::Float64                        # learning rate
    s::Vector{Float64}                # sufficients stats for MM (s, t, and o)
    t::Vector{Float64}
    o::Float64
    n::Int64                          # number of observations used
    nb::Int64                         # number of batches used
end

function QuantileMM(y::Vector; τ::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.6)
    p::Int = length(τ)
    qs::Vector{Float64} = quantile(y, τ) + .00000001
    s::Vector{Float64} = [sum(abs(y - qs[i]) .^ -1 .* y) for i in 1:p]
    t::Vector{Float64} = [sum(abs(y - qs[i]) .^ -1) for i in 1:p]
    o::Float64 = length(y)
    qs = [(s[i] + o * (2 * τ[i] - 1)) / t[i] for i in 1:p]

    QuantileMM(qs, τ, r, s, t, o, length(y), 1)
end

QuantileMM(y::Real; args...) = QuantileMM([y], args)


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::QuantileMM, y::Vector)
    γ::Float64 = obj.nb ^ - obj.r

    for i in 1:length(obj.τ)
        # Update sufficient statistics
        w::Vector = abs(y - obj.est[i]) .^ -1
        obj.s[i] += γ * (sum(w .* y) - obj.s[i])
        obj.t[i] += γ * (sum(w) - obj.t[i])
        obj.o += γ * (length(y) - obj.o)
        # Update quantile
        obj.est[i] = (obj.s[i] + obj.o * (2 * obj.τ[i] - 1)) / obj.t[i]
    end

    obj.n = obj.n + length(y)
    obj.nb += 1
end

update!(obj::QuantileMM, y::Real) = update!(obj, [y])



#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::QuantileMM)
    DataFrame(variable = [symbol("q" * string(int(100*i))) for i in obj.τ],
              value = obj.est,
              r = obj.r,
              n = nobs(obj))
end


#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::QuantileMM) = QuantileMM(obj.est, obj.τ, obj.r, obj.n, obj.nb)

function Base.merge(a::QuantileMM, b::QuantileMM)
    if any(a.τ .!= b.τ)
        error("Merge impossible. Objects are estimating different quantiles.")
    end
    if a.r != b.r
        warn("Objects have different learning rates.")
    end
    n = a.n + b.n
    est = a.est + (b.n / n) * (b.est - a.est)
    r = a.r + (b.n / n) * (b.r - a.r)
    nb = a.nb + b.nb

end

function Base.show(io::IO, obj::QuantileMM)
    println(io, "Online Quantile (Online MM):\n", state(obj))
    return
end
