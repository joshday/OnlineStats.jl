# OnlineStats

## Exported
---

#### state
  Usage: `state(obj)`

View the current state of estimates in `obj`


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:18](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/OnlineStats.jl#L18)

---

#### QuantileMM(y::Array{T, 1})
Construct QuantileMM from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:38](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L38)

---

#### QuantileSGD(y::Array{T, 1})
Consturct QuantileSGD from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:18](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L18)

---

#### Summary(y::Array{T, 1})
Construct `Summary` from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:17](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/summary.jl#L17)

---

#### Summary(y::DataArray{T, N})
Construct `Summary` from DataArray

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:25](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/summary.jl#L25)

---

#### convert(::Type{DataFrame}, obj::QuantileMM)
Convert 'obj' to type 'DataFrame'

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:142](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L142)

---

#### convert(::Type{DataFrame}, obj::QuantileSGD)
Convert 'obj' to type 'DataFrame'

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:128](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L128)

---

#### convert(::Type{DataFrame}, obj::Summary)
Convert 'obj' to type 'DataFrame'

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:102](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/summary.jl#L102)

---

#### update!(obj::QuantileMM, newdata::Array{T, 1})
Update quantile estimates using a new batch of data

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:81](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L81)

---

#### update!(obj::QuantileMM, newdata::Array{T, 1}, addrow::Bool)
Update quantile estimates using a new batch of data

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:81](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L81)

---

#### update!(obj::QuantileSGD, newdata::Array{T, 1})
Update quantile estimates using a new batch of data

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:57](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L57)

---

#### update!(obj::QuantileSGD, newdata::Array{T, 1}, addrow::Bool)
Update quantile estimates using a new batch of data

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:57](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L57)

---

#### update!(obj::Summary, newdata::Array{T, 1})
Update summary statistics with a new batch of data.

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:36](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/summary.jl#L36)

---

#### update!(obj::Summary, newdata::Array{T, 1}, add::Bool)
Update summary statistics with a new batch of data.

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:36](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/summary.jl#L36)

---

#### QuantileMM
Stores quantile estimating using an online MM algorithm

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:26](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L26)

---

#### QuantileSGD
Stores quantile estimates using a stochastic gradient descent algorithm

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:9](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/quantile.jl#L9)

---

#### Summary
Stores analytical updates for mean, variance, maximum, and minimum.

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:6](https://github.com/joshday/OnlineStats.jl/tree/056f3a699ef1e64d61dd9216d42f054acf8b02a0/src/summary/summary.jl#L6)


