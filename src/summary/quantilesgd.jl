export QuantileSGD

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type QuantileSGD <: ContinuousUnivariateOnlineStat
    est::Vector{Float64}              # Quantile estimates
    τ::Vector{Float64}                # tau values (which quantiles)
    r::Float64                        # learning rate
    n::Int64                          # number of observations used
    nb::Int64                         # number of batches used
end


QuantileSGD(y::Vector; τ::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.6) =
    QuantileSGD(quantile(y, sort(τ)), sort(τ), r, length(y), 1)

QuantileSGD(y::Real; args...) = QuantileSGD([y], args)



#-----------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
function update!(obj::QuantileSGD, y::Vector)
    γ::Float64 = obj.nb ^ - obj.r

    for i in 1:length(obj.τ)
        obj.est[i] -= γ * (mean(y .< obj.est[i]) - obj.τ[i])
    end

    obj.n += length(y)
    obj.nb += 1
end

update!(obj::QuantileSGD, y::Real) = update!(obj, [y])



#-----------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::QuantileSGD)
    names = [[symbol("q" * string(int(100*i))) for i in obj.τ], :n, :nb]
    estimates = [obj.est, obj.n, obj.nb]
    return([names estimates])
end



#-----------------------------------------------------------------------------#
#------------------------------------------------------------------------# Base
Base.copy(obj::QuantileSGD) = QuantileSGD(obj.est, obj.τ, obj.r, obj.n, obj.nb)

function Base.merge(a::QuantileSGD, b::QuantileSGD)
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
    QuantileSGD(est, a.τ, r, n, nb)
end

function Base.merge!(a::QuantileSGD, b::QuantileSGD)
    if any(a.τ .!= b.τ)
        error("Merge impossible. Objects are estimating different quantiles.")
    end
    if a.r != b.r
        warn("Objects have different learning rates.")
    end
    a.n += b.n
    a.est += (b.n / a.n) * (b.est - a.est)
    a.r += (b.n / a.n) * (b.r - a.r)
    a.nb += b.nb
end

function Base.show(io::IO, obj::QuantileSGD)
    println(io, "Online Quantile (Stochastic Gradient Descent):\n", state(obj))
    return
end
