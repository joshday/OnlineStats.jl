abstract type AbstractBootstrap{I} <: OnlineStatMeta{I} end
function show_series(io, o::AbstractBootstrap)
    print_item(io, "stat", o.o)
    print_item(io, "cached_state", summary(o.cached_state))
    print_item(io, "function", o.f)
    s = replace(string(typeof(o.d)), "Distributions.", "")
    s = replace(s, r"\{(.*)", "")
    print_item(io, "boot method", s, false)
end
function update_replicates!(reps, d::Ds.Bernoulli, y, γ::Float64)
    foreach(reps) do r
        rand() > 0.5 && (fit!(r, y, γ); fit!(r, y, γ))
    end
end
function update_replicates!(reps, d::Ds.Poisson, y, γ::Float64)
    foreach(reps) do r
        for k in 1:rand(Ds.Poisson())
            fit!(r, y, γ)
        end
    end
end
replicates(b::AbstractBootstrap) = b.replicates
function cached_state(b::AbstractBootstrap)
    if b.cache_is_dirty
        b.cached_state .= b.f.(b.replicates)
        b.cache_is_dirty = false
    end
    return b.cached_state
end
Base.mean(b::AbstractBootstrap) = mean(cached_state(b))
Base.std(b::AbstractBootstrap) = std(cached_state(b))
Base.var(b::AbstractBootstrap) = var(cached_state(b))

for (T, I) in [(:Bootstrap, 0), (:MvBootstrap, 1)]
    @eval begin
        mutable struct $T{
                D,
                O <: OnlineStat,
                F <: Function,
                W <: Weight,
                T <: AbstractArray
            } <: AbstractBootstrap{$I}
            weight::W
            nobs::Int
            nups::Int
            id::Symbol
            o::O
            replicates::Vector{O}
            cached_state::T
            f::F
            d::D
            cache_is_dirty::Bool
        end
        function $T(nreps::Int, o::OnlineStat, f::Function, d;
                    weight::Weight = EqualWeight(), id::Symbol = :unlabeled)
            _io(o, 1) == $I || throw(ArgumentError("Input dim must be $($I)"))
            replicates = [copy(o) for i in 1:nreps]
            cached_state = f.(replicates)
            D = typeof(d)
            O = typeof(o)
            F = typeof(f)
            W = typeof(weight)
            T = typeof(cached_state)
            $T{D,O,F,W,T}(weight, 0, 0, id, o, replicates, cached_state, f, d, false)
        end
        function $T(o::OnlineStat, nreps::Int = 100, d = Ds.Bernoulli(), f::Function = value)
            $T(nreps, o, f, d)
        end
    end
end



function StatsBase.confint(b::Bootstrap, coverageprob = 0.95, method = :quantile)
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

#--------------------------------------------------------------------# Updates
function singleton_update!(b::Bootstrap, y::Real, γ::Float64)
    fit!(b.o, y, γ)
    update_replicates!(b.replicates, b.d, y, γ)
    b.cache_is_dirty = true
end

function singleton_update!(b::MvBootstrap, y::AVec, γ::Float64)
    fit!(b.o, y, γ)
    update_replicates!(b.replicates, b.d, y, γ)
    b.cache_is_dirty = true
end
