#----------------------------------------------------------------------# SGModel
type SGModel{A <: SGAlgorithm, M <: ModelDefinition, P <: Penalty} <: OnlineStats.OnlineStat
    β0::Float64
    β::VecF
    intercept::Bool
    model::M
    penalty::P
    algorithm::A
    n::Int
end

function SGModel(
        p::Int;
        intercept::Bool = true,
        algorithm::SGAlgorithm = SGD(),
        model::ModelDefinition = L2Regression(),
        penalty::Penalty = NoPenalty()
    )
    SGModel(0.0, zeros(p), intercept, model, penalty, algorithm, 0)
end

function SGModel(x::AMatF, y::AVecF; keyargs...)
    o = SGModel(size(x, 2); keyargs...)
    update!(o, x, y)
    o
end

#----------------------------------------------------------------------# update!
function OnlineStats.update!(o::SGModel, x::AVecF, y::Float64)
    o.n += 1
    updateβ!(o, x, y)
end


#------------------------------------------------------------------------# state
StatsBase.coef(o::SGModel) = o.intercept ? vcat(o.β0, o.β) : copy(o.β)
StatsBase.predict(o::SGModel, x::AVecF) = predict(o.model, x, o.β, o.β0)
StatsBase.predict(o::SGModel, X::AMatF) = predict(o.model, X, o.β, o.β0)

statenames(o::SGModel) = [:β, :nobs]
state(o::SGModel) = Any[coef(o), nobs(o)]

function Base.show(io::IO, o::SGModel)
    println(io, "SGModel")
    println(io, "  > Algorithm:   ", typeof(o.algorithm))
    println(io, "  > Model:       ", typeof(o.model))
    println(io, "  > Intercept:   ", o.intercept ? "Yes" : "No")
    show(io, o.penalty)
    println(io, "  > β: ", StatsBase.coef(o))
end

#----------------------------------------------------------------------# include
