# Online Stepwise Regression
#
# With each updated batch, there is the possibility of one variable
# entering or leaving the model.  The choice is based on Mallow's Cp

#-------------------------------------------------------# Type and Constructors
type StepwiseReg{W <: Weighting} <: OnlineStat
    xycov::CovarianceMatrix{W}  # Cov([X y])
    s::MatF                     # "Swept" version of [X y]' [X y]
    inModel::Vector{Int}        # coefficients included in the model
    cpVec::VecF
    n::Int
    weighting::W
end

function StepwiseReg(x::MatF, y::VecF, wgt::Weighting = default(Weighting))
    n, p = size(x)
    o = StepwiseReg(p, wgt)
    updatebatch!(o, x, y)
    o
end

function StepwiseReg(p, wgt::Weighting = default(Weighting))
    c = CovarianceMatrix(p + 1, wgt)
    StepwiseReg(c, zeros(p + 1, p + 1), Int[], zeros(p), 0, wgt)
end


#-----------------------------------------------------------------------# state
statenames(o::StepwiseReg) = [:β, :nobs]
state(o::StepwiseReg) = Any[coef(o), nobs(o)]

coef(o::StepwiseReg) = vec(o.s[end, 1:end - 1])

#---------------------------------------------------------------------# update!
function updatebatch!(o::StepwiseReg, x::MatF, y::VecF)
    n, p = size(x)
    updatebatch!(o.xycov, [x y])
    copy!(o.s, o.xycov.A)
    sweep!(o.s, o.inModel) # Current model
    sumsquares = o.s[end, end]
    # Update vector of changes to Cp
    for i in 1:length(o.cpVec)
        o.cpVec[i] = o.s[end, end] - o.s[end, i] * o.s[i, end] / o.s[i, i]

    end
    # Add/Remove
    o.n += n
end