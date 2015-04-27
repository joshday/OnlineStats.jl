#-------------------------------------------------------# Type and Constructors
type QuantileSGD <: ScalarStat
    est::Vector{Float64}              # Quantile estimates
    τ::Vector{Float64}                # tau values (which quantiles)
    r::Float64                        # learning rate
    n::Int64                          # number of observations used
    nb::Int64                         # number of batches used
end


QuantileSGD(y::Vector; τ::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.6) =
    QuantileSGD(quantile(y, sort(τ)), sort(τ), r, length(y), 1)

QuantileSGD(y::Real; args...) = QuantileSGD([y], args)


#-------------------------------------------------------------# param and value
param(obj::QuantileSGD) = [symbol("τ_$i") for i in obj.τ]

value(obj::QuantileSGD) = copy(obj.est)


#---------------------------------------------------------------------# update!
function update!(obj::QuantileSGD, y::Vector)

    for i in 1:length(obj.τ)
        obj.est[i] -= (obj.nb ^ - obj.r) * (mean(y .< obj.est[i]) - obj.τ[i])
    end

    obj.n += length(y)
    obj.nb += 1
end

update!(obj::QuantileSGD, y::Real) = update!(obj, [y])


#------------------------------------------------------------------------# Base
Base.copy(obj::QuantileSGD) = QuantileSGD(obj.est, obj.τ, obj.r, obj.n, obj.nb)
