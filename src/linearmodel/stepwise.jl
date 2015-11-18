# Online Stepwise Regression
#
# With each updated batch, there is the possibility of one variable
# entering or leaving the model based on Mallow's Cp

#-------------------------------------------------------# Type and Constructors
"""
Online stepwise regression.

At each update, there is the possible of one variable entering or leaving the model.
Performs best using `updatebatch!()` with large batches.
"""
type StepwiseReg{W <: Weighting} <: OnlineStat
    C::CovarianceMatrix{W}  # Cov([X y])
    s::MatF                 # "Swept" version of [X y]' [X y] / n
    set::IntSet             # set of coefficients included in the model
    n::Int
end

function StepwiseReg(x::AMatF, y::AVecF, wgt::Weighting = default(Weighting))
    n, p = size(x)
    o = StepwiseReg(p, wgt)
    updatebatch!(o, x, y)
    o
end

function StepwiseReg(p::Integer, wgt::Weighting = default(Weighting))
    c = CovarianceMatrix(p + 1, wgt)
    StepwiseReg(c, zeros(p + 1, p + 1), IntSet([]), 0)
end


#-----------------------------------------------------------------------# state
statenames(o::StepwiseReg) = [:β, :nobs]
state(o::StepwiseReg) = Any[coef(o), nobs(o)]

function StatsBase.coef(o::StepwiseReg)
    β = vec(o.s[end, 1:end - 1])
    for i in setdiff(1:length(β), o.set)
        β[i] = 0.
    end
    β
end

#----------------------------------------------------------------------# update!
function update!(o::StepwiseReg, x::AVecF, y::Float64)
    updatebatch!(o, x', collect(y))
end

function updatebatch!(o::StepwiseReg, x::AMatF, y::AVecF)
    n, p = size(x)
    o.n += n
    updatebatch!(o.C, hcat(x, y))
    copy!(o.s, o.C.A)

    # get average squared error using all predictors
    sweep!(o.s, 1:p)
    ase = o.s[end, end]

    copy!(o.s, o.C.A)
    sweep!(o.s, collect(o.set))

    # Find best index to add/remove
    s = 1
    val = o.s[end, 1] ^ 2 / (o.s[1, 1] * ase) * (o.n - in(1, o.set)) + 2.0 - in(1, o.set)
    for i in 2:p
        newval = o.s[end, i] ^ 2 / (o.s[i, i] * ase) * (o.n - in(i, o.set)) - 2.0 * in(i, o.set)
        if newval > val
            val = newval
            s = i
        end
    end

    if s in o.set
        delete!(o.set, s)
    else
        push!(o.set, s)
    end

    DEBUG("Active set: ", o.set)
end


########## TEST code
# log_severity!(DebugSeverity)
#
# n,p = 10_000, 10
# x = randn(n,p)
# β = collect(1.:p)
# β[5] = 0.
# y = x*β + randn(n)
#
# o = StepwiseReg(p)
# @time update!(o, x, y, 500)
# print(coef(o))
