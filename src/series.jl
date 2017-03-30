"""
OnlineStatMeta:  Managers for a group or single OnlineStat

Subtypes should:
- Have fields `weight::Weight`, `nobs::Int`, `nups::Int`, and `id::Symbol`
"""
abstract type OnlineStatMeta{I} end
#----------------------------------------------------------------# OnlineStatMeta methods
nobs(o::OnlineStatMeta) = o.nobs
nups(o::OnlineStatMeta) = o.nups
weight!(o::OnlineStatMeta, n2::Int = 1) = (updatecounter!(o, n2); weight(o, n2))
updatecounter!(o::OnlineStatMeta, n2::Int = 1) = (o.nups += 1; o.nobs += n2)
weight(o::OnlineStatMeta, n2::Int = 1) = weight(o.weight, o.nobs, n2, o.nups)
nextweight(o::OnlineStatMeta, n2::Int = 1) = nextweight(o.weight, o.nobs, n2, o.nups)
Base.copy(o::OnlineStatMeta) = deepcopy(o)
Base.ndims{N}(o::OnlineStatMeta{N}) = N

function Base.show(io::IO, o::OnlineStatMeta)
    header(io, "$(name(o))\n")
    subheader(io, "$(o.id) | nobs = $(o.nobs)\n")
    show_series(io, o)
end
show_series(io, o::OnlineStatMeta) = print(io)

#----------------------------------------------------------------# OnlineStatMeta{0} fit!
function fit!(o::OnlineStatMeta{0}, y::Real, γ::Float64 = nextweight(o))
    updatecounter!(o)
    singleton_update!(o, y, γ)
    o
end
function fit!(o::OnlineStatMeta{0}, y::AVec)
    for yi in y
        fit!(o, yi)
    end
    o
end
function fit!(o::OnlineStatMeta{0}, y::AVec, γ::Float64)
    for yi in y
        fit!(o, yi, γ)
    end
    o
end
function fit!(o::OnlineStatMeta{0}, y::AVec, γ::AVecF)
    length(y) == length(γ) || throw(DimensionMismatch())
    for (yi, γi) in zip(y, γ)
        fit!(o, yi, γi)
    end
    o
end
function fit!(o::OnlineStatMeta{0}, y::AVec, b::Integer)
    maprows(b, y) do yi
        bi = length(yi)
        γ = weight!(o, bi)
        batch_update!(o, yi, γ)
    end
    o
end
#----------------------------------------------------------------# OnlineStatMeta{1} fit!
function fit!(o::OnlineStatMeta{1}, y::AVec, γ::Float64 = nextweight(o))
    updatecounter!(o)
    singleton_update!(o, y, γ)
    o
end
function fit!(o::OnlineStatMeta{1}, y::AMat)
    for i in 1:size(y, 1)
        fit!(o, view(y, i, :))
    end
    o
end
function fit!(o::OnlineStatMeta{1}, y::AMat, γ::Float64)
    for i in 1:size(y, 1)
        fit!(o, view(y, i, :), γ)
    end
    o
end
function fit!(o::OnlineStatMeta{1}, y::AMat, γ::AVecF)
    for i in 1:size(y, 1)
        fit!(o, view(y, i, :), γ[i])
    end
    o
end
function fit!(o::OnlineStatMeta{1}, y::AMat, b::Integer)
    maprows(b, y) do yi
        bi = size(yi, 1)
        γ = weight!(o, bi)
        batch_update!(o, yi, γ)
    end
    o
end


#----------------------------------------------------------------# Series and MvSeries
abstract type AbstractSeries{I} <: OnlineStatMeta{I} end
stats(o::AbstractSeries) = o.stats
stats(o::AbstractSeries, i::Integer) = stats(o)[i]
value(o::AbstractSeries) = map(value, o.stats)
value(o::AbstractSeries, i::Integer) = value(stats(o, i))
function show_series(io, o::AbstractSeries)
    n = length(o.stats)
    for i in 1:n
        s = o.stats[i]
        print_item(io, name(s), value(s), i != n)
    end
end
function Base.merge!{T <: AbstractSeries}(o::T, o2::T, method::Symbol = :append)
    n2 = nobs(o2)
    n2 == 0 && return o
    p = length(o.stats)
    for i in 1:p
        stat1 = o.stats[i]
        stat2 = o2.stats[i]
        if method == :append
            merge!(stat1, stat2, nextweight(o, n2))
        elseif method == :mean
            merge!(stat1, stat2, 0.5 * (weight(o) + weight(o2)))
        elseif method == :singleton
            merge!(stat1, stat2, nextweight(o))
        else
            throw(ArgumentError("method must be :append, :mean, or :singleton"))
        end
    end
    updatecounter!(o, n2)
    o
end
function Base.merge{T <: AbstractSeries}(o::T, o2::T, method::Symbol = :append)
    merge!(copy(o), o2, method)
end

for (T, I) in [(:Series, 0), (:MvSeries, 1)]
    @eval begin
        mutable struct $T{W <: Weight, OS <: Tuple} <: AbstractSeries{$I}
            weight::W
            nobs::Int
            nups::Int
            id::Symbol
            stats::OS
        end
        # This acts as inner constructor
        function $T(stats::Tuple, weight::Weight, id::Symbol)
            if any(x -> _io(x, 1) != $I, stats)
                throw(ArgumentError("Input dims must be $($I)"))
            end
            $T(weight, 0, 0, id, stats)
        end
        function $T(wt::Weight, id::Symbol, stats...)
            $T(stats, wt, id)
        end
        function $T(id::Symbol, wt::Weight, stats...)
            $T(stats, wt, id)
        end
        function $T(stats...; weight::Weight = EqualWeight(), id::Symbol = :unlabeled)
            $T(stats, weight, id)
        end
        function $T(data::AbstractArray, stats...;
                    weight::Weight = EqualWeight(), id::Symbol = :unlabeled)
            o = $T(stats, weight, id)
            fit!(o, data)
        end
    end
end

singleton_update!(o::Series, y::Real, γ::Float64) = map(stat -> fit!(stat, y, γ), o.stats)
batch_update!(o::Series, y::AVec, γ::Float64) = map(stat -> fitbatch!(stat, y, γ), o.stats)

singleton_update!(o::MvSeries, y::AVec, γ::Float64) = map(stat -> fit!(stat, y, γ), o.stats)
batch_update!(o::MvSeries, y::AMat, γ::Float64) = map(stat -> fitbatch!(stat, y, γ), o.stats)
