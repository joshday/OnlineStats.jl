# Online Stepwise Regression
#
# With each updated batch, there is the possibility of one variable
# entering or leaving the model based on Mallow's Cp

#-------------------------------------------------------# Type and Constructors
type StepwiseReg{W <: Weighting} <: OnlineStat
    C::CovarianceMatrix{W}  # Cov([X y])
    s::MatF                 # "Swept" version of [X y]' [X y] / n
    set::Vector{Int}        # set of coefficients included in the model
    n::Int
    weighting::W
end

function StepwiseReg(x::MatF, y::VecF, wgt::Weighting = default(Weighting))
    n, p = size(x)
    o = StepwiseReg(p, wgt)
    updatebatch!(o, x, y)
    o
end

function StepwiseReg(p::Int, wgt::Weighting = default(Weighting))
    c = CovarianceMatrix(p + 1, wgt)
    StepwiseReg(c, zeros(p + 1, p + 1), Int[], 0, wgt)
end


#-----------------------------------------------------------------------# state
statenames(o::StepwiseReg) = [:β, :nobs]
state(o::StepwiseReg) = Any[coef(o), nobs(o)]

function coef(o::StepwiseReg)
    β = vec(o.s[end, 1:end - 1])
    for i in setdiff(1:length(β), o.set)
        β[i] = 0.
    end
    β
end

#---------------------------------------------------------------------# update!
# not optimized
function updatebatch!(o::StepwiseReg, x::MatF, y::VecF)
    n, p = size(x)
    o.n += n
    updatebatch!(o.C, [x y])
    copy!(o.s, o.C.A)

    # get estimate of variance
    sweep!(o.s, 1:p)
    σ² = o.s[end, end] / (nobs(o) - length(o.set))

    # get current cp
    copy!(o.s, o.C.A)
    sweep!(o.s, o.set)
    q = length(o.set)
    cp_old = o.s[end, end] / σ² + 2 * q

    # add variables
    cp_add = Float64[]
    notinset = setdiff(1:p, o.set)
    for i in notinset
        sweep!(o.s, i)
        cp = o.s[end, end] / σ² + 2(q + 1)
        push!(cp_add, cp)
        sweep!(o.s, i, true)
    end
    if !isempty(cp_add)
        add_cp, add_index = findmin(cp_add)
    else
        add_cp = cp_old + 1
    end

    # remove variables
    cp_remove = Float64[]
    for i in o.set
        sweep!(o.s, i, true)
        cp = o.s[end, end] / σ² + 2(q - 1)
        push!(cp_remove, cp)
        sweep!(o.s, i)
    end
    if !isempty(cp_remove)
        rm_cp, rm_index = findmin(cp_remove)
    else
        rm_cp = cp_old + 1
    end


    if cp_old != min(cp_old, add_cp, rm_cp)
        if add_cp < cp_old
            push!(o.set, add_index)
            o.set = unique(o.set)
            sort!(o.set)
            sweep!(o.s, add_index)
        else
            o.set = setdiff(o.set, rm_index)
            sweep!(o.s, rm_index, true)
        end
    end

    println("Active set: ", o.set)
end
