# Author: Josh Day <emailjoshday@gmail.com>

export QuantileSGD, QuantileMM

#------------------------------------------------------------------------------#
#---------------------------------------------------------------# Quantile Types
### SGD
type QuantileSGD <: ContinuousUnivariateOnlineStat
    est::Vector{Float64}              # Quantiles
    tau::Vector{Float64}              # tau values
    r::Float64                        # learning rate
    n::Int64                          # number of observations used
    nb::Int64                         # number of batches used
end


QuantileSGD(y::Vector; tau::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.51) =
    QuantileSGD(quantile(y, tau), tau, r, length(y), 1)




### MM
type QuantileMM <: ContinuousUnivariateOnlineStat
    est::Vector{Float64}              # Quantiles
    tau::Vector{Float64}              # tau values
    r::Float64                        # learning rate
    s::Vector{Float64}                # sufficients stats for MM (s, t, and o)
    t::Vector{Float64}
    o::Float64
    n::Int64                          # number of observations used
    nb::Int64                         # number of batches used
end


function QuantileMM(y::Vector; tau::Vector = [0.25, 0.5, 0.75], r::Float64 = 0.51)
    p::Int = length(tau)
    qs::Vector{Float64} = quantile(y, tau) + .00000001
    s::Vector{Float64} = [sum(abs(y - qs[i]) .^ -1 .* y) for i in 1:p]
    t::Vector{Float64} = [sum(abs(y - qs[i]) .^ -1) for i in 1:p]
    o::Float64 = length(y)
    qs = [(s[i] + o * (2 * tau[i] - 1)) / t[i] for i in 1:p]

    QuantileMM(qs, tau, r, s, t, o, length(y), 1)
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------------------# update!
### SGD
function update!(obj::QuantileSGD, newdata::Vector)
    γ::Float64 = obj.nb ^ - obj.r

    for i in 1:length(obj.tau)
        obj.est[i] -= γ * (mean(newdata .< obj.est[i]) - obj.tau[i])
    end

    obj.n += length(newdata)
    obj.nb += 1
end


### MM
function update!(obj::QuantileMM, newdata::Vector)
    γ::Float64 = obj.nb ^ - obj.r

    for i in 1:length(obj.tau)
        # Update sufficient statistics
        w::Vector = abs(newdata - obj.est[i]) .^ -1
        obj.s[i] += γ * (sum(w .* newdata) - obj.s[i])
        obj.t[i] += γ * (sum(w) - obj.t[i])
        obj.o += γ * (length(newdata) - obj.o)
        # Update quantile
        obj.est[i] = (obj.s[i] + obj.o * (2 * obj.tau[i] - 1)) / obj.t[i]
    end

    obj.n = obj.n + length(newdata)
    obj.nb += 1
end



#------------------------------------------------------------------------------#
#-----------------------------------------------------------------------# state
function state(obj::QuantileSGD)
    println("      tau = " * string(obj.tau))
    println("quantiles = " * string(obj.est))
    println("        n = " * string(obj.n))
    println("       nb = " * string(obj.nb))
end

function state(obj::QuantileMM)
    println("      tau = " * string(obj.tau))
    println("quantiles = " * string(obj.est))
    println("        n = " * string(obj.n))
    println("       nb = " * string(obj.nb))
end


#------------------------------------------------------------------------------#
#---------------------------------------------------------# Interactive Testing
# y1 = rand(111)
# y2 = rand(222)
# y3 = rand(333)

# obj = OnlineStats.QuantileMM(y1, tau = [.1, .2, .4])
# y2 = rand(100)
# OnlineStats.update!(obj, y2)
# OnlineStats.update!(obj, y3)
# OnlineStats.state(obj)

# obj = OnlineStats.QuantileSGD(y1, tau = [.1, .2, .4])
# y2 = rand(100)
# OnlineStats.update!(obj, y2)
# OnlineStats.update!(obj, y3)
# OnlineStats.state(obj)


