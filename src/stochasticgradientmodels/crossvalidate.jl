#--------------------------------------------------------# Type and Constructors
"""
Fit an SGModel using an automated tuning procedure.


"""
type SGModelCV <: OnlineStat
    o::SGModel
    o_l::SGModel    # low
    o_h::SGModel    # high
    decay::Float64  # decay rate for λ
    function SGModelCV(o::SGModel; decay = .7)
        @assert decay > 0
        new(o, copy(o), copy(o), decay)
    end
end

#----------------------------------------------------------------------# update!
# NoPenalty
function updateλ!{A <: SGAlgorithm, M <: ModelDefinition}(
        o::SGModel{A, M, NoPenalty},
        o_l::SGModel{A, M, NoPenalty},
        o_h::SGModel{A, M, NoPenalty},
        x::AVecF, y::Float64)
    update!(o, x, y)
    update!(o_l, x, y)
    update!(o_h, x, y)
end

# L2Penalty and L1Penalty
function updateλ!(o::SGModel, o_l::SGModel, o_h::SGModel, x::AVecF, y::Float64, decay::Float64)
    # alter λ for o_l and o_h
    γ = 1 / (nobs(o) + 1) ^ decay
    o_l.penalty.λ = max(0.0, o_l.penalty.λ - γ)
    o_h.penalty.λ += γ

    # update all three models
    update!(o, x, y)
    update!(o_l, x, y)
    update!(o_h, x, y)

    # Find best model
    ŷ = predict(o, x)
    ŷ_l = predict(o_l, x)
    ŷ_h = predict(o_h, x)
    v = vcat(abs(y - ŷ_l), abs(y - ŷ), abs(y - ŷ_h))
    _, j = findmin(v)

    if j == 1 # o_l is winner
        o.penalty.λ = o_l.penalty.λ
        o_h.penalty.λ = o_l.penalty.λ
    elseif j == 2 # o is winner
        o_l.penalty.λ = o.penalty.λ
        o_h.penalty.λ = o.penalty.λ
    else # o_h is winner
        o_l.penalty.λ = o_h.penalty.λ
        o.penalty.λ = o_h.penalty.λ
    end
end

function update!(o::SGModelCV, x::AVecF, y::Float64)
    updateλ!(o.o, o.o_l, o.o_h, x, y, o.decay)
end


#------------------------------------------------------------------------# state
statenames(o::SGModelCV) = [:β, :penalty, :nobs]
state(o::SGModelCV) = Any[coef(o), copy(o.o.penalty), nobs(o)]
whatisλ(o::SGModelCV) = o.o.penalty.λ

StatsBase.coef(o::SGModelCV) = coef(o.o)
StatsBase.nobs(o::SGModelCV) = nobs(o.o)

function Base.show(io::IO, o::SGModelCV)
    println(io, "Cross-Validated SGModel:")
    show(o.o)
end



# Testing
if false
    function linearmodeldata(n, p)
        x = randn(n, p)
        β = (collect(1:p) - .5*p) / p
        y = x*β + randn(n)
        (β, x, y)
    end
    n,p = 10_000, 10
    β,x,y = linearmodeldata(n,p)

    o = OnlineStats.SGModel(p, penalty = OnlineStats.L2Penalty(.1), algorithm = OnlineStats.RDA())
    ocv = OnlineStats.SGModelCV(o, decay = .9)
    v = OnlineStats.tracefit!(ocv, 100, x, y)
    OnlineStats.traceplot(v, x -> vcat(OnlineStats.whatisλ(x)))
end
