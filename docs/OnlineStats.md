# OnlineStats

## Exported
---

#### state
  Usage: `state(obj)`

View the current state of estimates in `obj`


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:19](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/OnlineStats.jl#L19)

---

#### Summary(y::Array{T, 1})
Construct `Summary` from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:20](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/summary/summary.jl#L20)

---

#### Summary(y::DataArray{T, N})
Construct `Summary` from DataArray

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:28](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/summary/summary.jl#L28)

---

#### convert(::Type{DataFrame}, obj::Summary)
Convert 'obj' to type 'DataFrame'


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:109](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/summary/summary.jl#L109)

---

#### update!(obj::Summary, newdata::Array{T, 1})
Update summary statistics with a new batch of data.


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:41](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/summary/summary.jl#L41)

---

#### update!(obj::Summary, newdata::Array{T, 1}, add::Bool)
Update summary statistics with a new batch of data.


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:41](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/summary/summary.jl#L41)

---

#### Summary
Stores analytical updates for mean, variance, maximum, and
minimum.


**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:9](https://github.com/joshday/OnlineStats.jl/tree/31c9b9fc9cf6724c7096c7c27cc857d5c4899bda/src/summary/summary.jl#L9)


