export OnlineLogReg

#-----------------------------------------------------------------------------#
#-------------------------------------------------------# Type and Constructors
type OnlineLogRegSGD <: OnlineStat
    β::Vector             # Coefficients
    int::Bool             # Add intercept?
    r::Float64            # learning rate
    n::Int64
    nb::Int64
end

function OnlineLogRegSGD(X::Matrix, y::Vector; r = 0.51, intercept = true)
    if length(unique(y)) != 2
        error("response vector does not have two categories")
    end
    if intercept
        X = [ones(length(y)) X]
    end
    n, p = size(X)
    y = (y .== y[1])


    OnlineLogRegSGD(β, r, intercept, n, 1)
end
