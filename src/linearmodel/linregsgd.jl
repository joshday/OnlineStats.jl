
# Stochastic Gradient Descent algorithm for linear models
# Needs testing to ensure this is actually "fast"
#-------------------------------------------------------# Type and Constructors
type LinRegSGD <: OnlineStat
    p::Int64       # length(β)
    β::VecF
    n::Int64
    weighting::StochasticWeighting
end

function LinRegSGD(x::MatF, y::VecF, wgt::StochasticWeighting = StochasticWeighting(.7),
                start = zeros(size(x, 2)))
    o = LinRegSGD(size(x, 2), wgt, start)
    update!(o, x, y)
    o
end

function LinRegSGD(x::VecF, y::Float64, wgt::StochasticWeighting = StochasticWeighting(.7),
                start = zeros(length(x)))
    o = LinRegSGD(length(x), wgt, start)
    update!(o, x, y)
    o
end

LinRegSGD(p::Int, wgt::StochasticWeighting = StochasticWeighting(.7), start = zeros(p)) =
    LinRegSGD(p, start, 0, wgt)


#-----------------------------------------------------------------------# state
statenames(o::LinRegSGD) = [:β, :nobs]
state(o::LinRegSGD) = Any[coef(o), nobs(o)]

coef(o::LinRegSGD) = copy(o.β)


#---------------------------------------------------------------------# update!
function update!(o::LinRegSGD, x::VecF, y::Float64)
    λ = weight(o)
    o.β += λ * (y - sum(x .* o.β)) * x
    o.n += 1
end

function update!(o::LinRegSGD, x::MatF, y::VecF)
    for i in 1:size(x,1)
        update!(o, vec(x[i, :]), y[i])
    end
end


#------------------------------------------------------------------------# Base
function predict(o::LinRegSGD, x::Matrix)
    β = coef(o)
    β[1] + x * β[2:end]
end

# Testing
x = randn(1000,5)
y = vec(sum(x,2)) + randn(1000)
o = OnlineStats.LinRegSGD(x, y)
