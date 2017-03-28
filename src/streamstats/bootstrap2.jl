mutable struct Bootstrap{
        I <: Input,
        D,
        O <: OnlineStat{I},
        F <: Function,
        W <: Weight,
        T <: AbstractArray
    } <: AbstractSeries
    weight::W
    nobs::Int
    nups::Int
    id::Symbol
    stat::O
    replicates::Vector{O}
    cached_state::T
    f::F
    d::D
    cache_is_dirty::Bool

end
function Bootstrap{I<:Input}(nreps::Int, o::OnlineStat{I}, f::Function, d;
                             weight::Weight = EqualWeight(), id::Symbol = :unlabeled)
     replicates = [copy(o) for i in 1:nreps]
     cached_state = f.(replicates)
     D = typeof(d)
     O = typeof(o)
     F = typeof(f)
     W = typeof(weight)
     T = typeof(cached_state)
     Bootstrap{I,D,O,F,W,T}(weight, 0, 0, id, o, replicates, cached_state, f, d, false)
end

function Base.show(io::IO, o::Bootstrap)
    header(io, "$(name(o))\n")
    subheader(io, "         id | $(o.id)\n")
    subheader(io, "     weight | $(o.weight)\n")
    subheader(io, "       nobs | $(o.nobs)\n")
    print_item(io, "Stat", o.stat)
    print_item(io, "n reps", length(o.replicates))
    print_item(io, "Function", o.f)

    s = replace(string(typeof(o.d)), "Distributions.", "")
    s = replace(s, r"\{(.*)", "")
    print_item(io, "Dist", s)
end

replicates(b::Bootstrap) = b.replicates
function cached_state(b::Bootstrap{ScalarIn})
    if b.cache_is_dirty
        b.cached_state .= b.f.(b.replicates)
        b.cache_is_dirty = false
    end
    return b.cached_state
end
Base.mean(b::Bootstrap{ScalarIn}) = mean(cached_state(b))
Base.std(b::Bootstrap{ScalarIn}) = std(cached_state(b))
Base.var(b::Bootstrap{ScalarIn}) = var(cached_state(b))

function StatsBase.confint(b::Bootstrap{ScalarIn}, coverageprob = 0.95, method = :quantile)
    states = cached_state(b)
    # If any NaN, return NaN, NaN
    if any(isnan, states)
        return (NaN, NaN)
    else
        α = 1 - coverageprob
        if method == :quantile
            return (quantile(states, α / 2), quantile(states, 1 - α / 2))
        elseif method == :normal
            norm_approx = Ds.Normal(mean(states), std(states))
            return (quantile(norm_approx, α / 2), quantile(norm_approx, 1 - α / 2))
        else
            throw(ArgumentError("$method not recognized.  Use :quantile or :normal"))
        end
    end
end

#-------------------------------------------------------------------------# fit!
function fit!(b::Bootstrap{ScalarIn}, y::Real, γ::Float64 = nextweight(b))
    updatecounter!(b)
    fit!(b.stat, y, γ)
    update_replicates!(b, y, γ)
    b.cache_is_dirty = true
    b
end
function fit!(b::Bootstrap{ScalarIn}, y::AVec)
    for yi in y
        fit!(b, yi)
    end
    b
end

#---------------------------------------------------------------------# update_replicates!
function update_replicates!{D <: Ds.Bernoulli}(b::Bootstrap{ScalarIn, D}, y, γ::Float64)
    foreach(b.replicates) do r
        rand() > 0.5 && (fit!(r, y, γ); fit!(r, y, γ))
    end
end

function update_replicates!{D <: Ds.Poisson}(b::Bootstrap{ScalarIn, D}, y, γ::Float64)
    foreach(b.replicates) do r
        for k in 1:rand(Ds.Poisson())
            fit!(r, y, γ)
        end
    end
end
