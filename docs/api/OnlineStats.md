# OnlineStats

## Exported
---

#### state

  `state(obj)`

View the current state of estimates in `obj`


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:31](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/OnlineStats.jl#L31)

---

#### update!

  `update!(obj, newdata, add = true)`

Updates estimates and either overwrites most recent estimate (`add = false`) or
adds a row (`add = true`)


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:24](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/OnlineStats.jl#L24)

---

#### update!(obj::Summary, newdata::Array{T, 1})
Update summary statistics with a new batch of data.


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:38](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/summary/summary.jl#L38)

---

#### update!(obj::Summary, newdata::Array{T, 1}, add::Bool)
Update summary statistics with a new batch of data.


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:38](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/summary/summary.jl#L38)

---

#### Summary
`Summary` stores analytical updates for mean, variance, maximum, and
minimum.


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:9](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/summary/summary.jl#L9)


