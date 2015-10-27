abstract StochasticSparsity

"""
After `burnin` observations, coefficients will be set to zero if they are less
than `ϵ`.
"""
immutable HardThreshold <: StochasticSparsity
    burnin::Int
    ϵ::Float64
end

"""
### Enforce sparsity on a StochasticModel

`SparseModel(o::StochasticModel, s::StochasticSparsity)`
"""
type SparseModel{S <: StochasticSparsity} <: OnlineStat
    o::StochasticModel
    s::S
end

function Base.show(io::IO, o::SparseModel)
    println(io, "SparseModel with ", typeof(o.s))
    show(o.o)
end

nobs(o::SparseModel) = nobs(o.o)
state(o::SparseModel) = state(o.o)
statenames(o::SparseModel) = statenames(o.o)


function update!(o::SparseModel, x::AVecF, y::Float64)
    update!(o.o, x, y)
    update!(o.o, o.s)
end

function update!(o::StochasticModel, s::HardThreshold)
    if nobs(o) > s.burnin
        for j in 1:length(o.β)
            if abs(o.β[j]) < s.ϵ
                o.β[j] = 0.0
            end
        end
    end
end
