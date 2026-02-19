#=
    Transducers for OnlineStats

Transducers are composable transformations that modify how observations
are processed before reaching an OnlineStat.  They decouple "what to compute"
(the stat) from "how to preprocess" (the transducer).

## Quick Start

```julia
# Transform input with Map
o = Map(abs) |> Mean()
fit!(o, [-1, -2, -3])  # computes mean of [1, 2, 3]

# Filter observations
o = Filter(x -> x > 0) |> Mean()
fit!(o, [-1, 1, -2, 2, 3])  # computes mean of [1, 2, 3]

# Chain multiple transducers
o = Map(abs) |> Filter(x -> x > 1) |> Mean()
fit!(o, [-3, -1, 0, 2])  # abs -> [3, 1, 0, 2], filter -> [3, 2], mean -> 2.5

# Use with Series for multiple stats
o = Map(abs) |> Series(Mean(), Variance())
fit!(o, randn(1000))

# One-shot with transduce
result = transduce(Map(abs), Mean(), [-1, -2, -3])
value(result)  # 2.0
```
=#

abstract type Transducer end

# Helper for display
_xname(o::Transducer) = string(typeof(o))

#-----------------------------------------------------------------------# Concrete Transducer Types

"""
    Map(f)

Transducer that transforms each observation with `f` before passing it to the
wrapped stat.

# Example

    o = Map(abs) |> Mean()
    fit!(o, [-1, -2, -3])
    mean(o)  # 2.0

    o = Map(log) |> Series(Mean(), Variance())
    fit!(o, exp.(randn(1000)))
"""
struct Map{F} <: Transducer
    f::F
end
_xname(o::Map) = "Map($(o.f))"

"""
    Filter(pred)

Transducer that only passes observations where `pred(y)` is `true`.
Filtered observations are counted in the `nfiltered` field.

# Example

    o = Filter(x -> x > 0) |> Mean()
    fit!(o, [-1, 1, -2, 2, 3])
    mean(o)   # 2.0
    o.nfiltered  # 2
"""
struct Filter{F} <: Transducer
    f::F
end
_xname(o::Filter) = "Filter($(o.f))"

"""
    Scan(f, init)

Transducer that maintains a running accumulation.  For each input `y`, the
internal state is updated as `state = f(state, y)` and `state` is passed
downstream to the wrapped stat.

# Example

    # Running sum fed into a stat
    o = Scan(+, 0) |> Mean()
    fit!(o, [1, 2, 3])  # Mean sees [1, 3, 6]
    mean(o)  # 10/3

    # Running max
    o = Scan(max, -Inf) |> Lag(5)
    fit!(o, [3, 1, 4, 1, 5])
"""
mutable struct Scan{F, T} <: Transducer
    f::F
    state::T
    init::T
end
Scan(f, init) = Scan(f, init, init)
_xname(o::Scan) = "Scan($(o.f), $(o.init))"

"""
    Take(n)

Transducer that only passes the first `n` observations.  All subsequent
observations are counted as filtered.

# Example

    o = Take(3) |> Mean()
    fit!(o, 1:100)
    mean(o)  # 2.0  (mean of [1, 2, 3])
    nobs(o)  # 3
"""
mutable struct Take <: Transducer
    n::Int
    seen::Int
end
Take(n::Integer) = Take(Int(n), 0)
_xname(o::Take) = "Take($(o.n))"

"""
    Drop(n)

Transducer that skips the first `n` observations.

# Example

    o = Drop(2) |> Mean()
    fit!(o, [1, 2, 3, 4, 5])
    mean(o)  # 4.0  (mean of [3, 4, 5])
"""
mutable struct Drop <: Transducer
    n::Int
    seen::Int
end
Drop(n::Integer) = Drop(Int(n), 0)
_xname(o::Drop) = "Drop($(o.n))"

"""
    Dedupe()

Transducer that skips consecutive duplicate values (compared with `isequal`).

# Example

    o = Dedupe() |> Mean()
    fit!(o, [1, 1, 2, 2, 3])
    mean(o)  # 2.0  (mean of [1, 2, 3])
"""
mutable struct Dedupe <: Transducer
    last::Any
    hasval::Bool
end
Dedupe() = Dedupe(nothing, false)
_xname(::Dedupe) = "Dedupe()"

"""
    TCompose(outer, inner)

Composition of two transducers.  `outer` processes input first, then `inner`.
Created with `|>` (left-to-right) or `∘` (right-to-left).

# Example

    # These are equivalent:
    xf = Map(abs) |> Filter(x -> x > 0)
    xf = Filter(x -> x > 0) ∘ Map(abs)

    o = xf |> Mean()
    fit!(o, randn(100))
"""
struct TCompose{O<:Transducer, I<:Transducer} <: Transducer
    outer::O
    inner::I
end
_xname(o::TCompose) = _xname(o.outer) * " |> " * _xname(o.inner)

#-----------------------------------------------------------------------# TransducedStat
"""
    TransducedStat(xform, stat)

An `OnlineStat` wrapped with a `Transducer` that transforms input before processing.
Created by piping a transducer into a stat with `|>`.

# Example

    o = Map(abs) |> Mean()
    fit!(o, [-1, -2, -3])
    mean(o)  # 2.0
"""
mutable struct TransducedStat{X<:Transducer, S<:OnlineStat, N} <: OnlineStat{N}
    xform::X
    stat::S
    nfiltered::Int
end

function TransducedStat(xf::Transducer, stat::OnlineStat{T}) where T
    TransducedStat{typeof(xf), typeof(stat), T}(xf, stat, 0)
end

nobs(o::TransducedStat) = nobs(o.stat)
value(o::TransducedStat) = value(o.stat)

function Base.show(io::IO, o::TransducedStat)
    print(io, _xname(o.xform), " |> ", o.stat)
    o.nfiltered > 0 && print(io, " (", o.nfiltered, " filtered)")
end

function Base.copy(o::TransducedStat)
    TransducedStat(deepcopy(o.xform), copy(o.stat), o.nfiltered)
end

function _merge!(o::TransducedStat, o2::TransducedStat)
    _merge!(o.stat, o2.stat)
    o.nfiltered += o2.nfiltered
    o
end

# Forward common stat methods to inner stat
Statistics.mean(o::TransducedStat) = mean(o.stat)
Statistics.var(o::TransducedStat) = var(o.stat)

#-----------------------------------------------------------------------# Composition operators

# Transducer |> OnlineStat  -> TransducedStat
Base.:(|>)(xf::Transducer, s::OnlineStat) = TransducedStat(xf, s)

# TCompose |> OnlineStat  -> expand into nested TransducedStats
function Base.:(|>)(xf::TCompose, s::OnlineStat)
    TransducedStat(xf.outer, xf.inner |> s)
end

# Transducer |> Transducer  -> TCompose (left processes first)
Base.:(|>)(a::Transducer, b::Transducer) = TCompose(a, b)

# Mathematical composition: (a ∘ b) means b processes first
Base.:(∘)(a::Transducer, b::Transducer) = TCompose(b, a)

# Make transducers callable: xf(stat) creates TransducedStat
(xf::Transducer)(s::OnlineStat) = xf |> s

#-----------------------------------------------------------------------# _fit! methods

_fit!(o::TransducedStat{<:Map}, y) = _fit!(o.stat, o.xform.f(y))

function _fit!(o::TransducedStat{<:Filter}, y)
    if o.xform.f(y)
        _fit!(o.stat, y)
    else
        o.nfiltered += 1
    end
end

function _fit!(o::TransducedStat{<:Scan}, y)
    o.xform.state = o.xform.f(o.xform.state, y)
    _fit!(o.stat, o.xform.state)
end

function _fit!(o::TransducedStat{Take}, y)
    if o.xform.seen < o.xform.n
        o.xform.seen += 1
        _fit!(o.stat, y)
    else
        o.nfiltered += 1
    end
end

function _fit!(o::TransducedStat{Drop}, y)
    if o.xform.seen < o.xform.n
        o.xform.seen += 1
        o.nfiltered += 1
    else
        _fit!(o.stat, y)
    end
end

function _fit!(o::TransducedStat{Dedupe}, y)
    if !o.xform.hasval || !isequal(o.xform.last, y)
        o.xform.last = y
        o.xform.hasval = true
        _fit!(o.stat, y)
    else
        o.nfiltered += 1
    end
end

#-----------------------------------------------------------------------# transduce
"""
    transduce(xf::Transducer, stat::OnlineStat, data)

Apply transducer `xf` to `stat` and fit with `data`.  Returns the
`TransducedStat`.

# Example

    o = transduce(Map(abs), Mean(), [-1, -2, -3])
    value(o)   # 2.0
    nobs(o)    # 3
"""
function transduce(xf::Transducer, stat::OnlineStat, data)
    o = xf |> stat
    fit!(o, data)
    o
end

"""
    transduce(xf::Transducer, stat::OnlineStat)

Create a `TransducedStat` without fitting any data.  Equivalent to `xf |> stat`.

# Example

    o = transduce(Map(abs), Mean())
    fit!(o, [-1, -2, -3])
"""
transduce(xf::Transducer, stat::OnlineStat) = xf |> stat
