# OnlineStats

## Exported
---

#### convert
  `convert(DataFrame, obj)`

Get `obj` results as `DataFrame`


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:34](https://github.com/joshday/OnlineStats.jl/tree/b3ffb64ad2ec89f08d103088fdc723368b714812/src/OnlineStats.jl#L34)

---

#### state
  `state(obj)`

Get current state of estimates in `obj`


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:28](https://github.com/joshday/OnlineStats.jl/tree/b3ffb64ad2ec89f08d103088fdc723368b714812/src/OnlineStats.jl#L28)

---

#### update!
  `update!(obj, newdata::Vector, add::Bool=true)`

Update object `obj` with observations in `newdata`.  Overwrite previous
estimates (`add = false`) or append new estimates (`add = true`)


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:22](https://github.com/joshday/OnlineStats.jl/tree/b3ffb64ad2ec89f08d103088fdc723368b714812/src/OnlineStats.jl#L22)

---

#### QuantileMM(y::Array{T, 1})
Create QuantileMM object

fields:

  - `est::Matrix`: quantile results

  - `τs::Vector`:  quantiles estimated

  - `r::Float64`:  learning rate

  - `s::Vector, t::Vector, and o::Float`:  sufficient statistics

  - `n::Vector`:   number of observations used

  - `nb::Vector`:  number of batches used


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:66](https://github.com/joshday/OnlineStats.jl/tree/b3ffb64ad2ec89f08d103088fdc723368b714812/src/summary/quantile.jl#L66)

---

#### QuantileSGD(y::Array{T, 1})
Create QuantileSGD object

fields:

  - `est::Matrix`: quantile results

  - `τs::Vector`:  quantiles estimated

  - `r::Float64`:  learning rate

  - `n::Vector`:   number of observations used

  - `nb::Vector`:  number of batches used


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:31](https://github.com/joshday/OnlineStats.jl/tree/b3ffb64ad2ec89f08d103088fdc723368b714812/src/summary/quantile.jl#L31)

---

#### Summary(y::Array{T, 1})
Create Summary object

fields (each is Vector): `mean`, `var`, `max`, `min`, `n`, `nb`


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:20](https://github.com/joshday/OnlineStats.jl/tree/b3ffb64ad2ec89f08d103088fdc723368b714812/src/summary/summary.jl#L20)


