# OnlineStats

## Exported
---

#### state
  Usage: `state(obj)`

View the current state of estimates in `obj`


**source:**
[/Users/jtday/.julia/OnlineStats/src/OnlineStats.jl:19](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/OnlineStats.jl#L19)

---

#### QuantileMM(y::Array{T, 1})
Construct QuantileMM from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:33](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L33)

---

#### QuantileMM(y::Array{T, 1}, τs::Array{T, 1})
Construct QuantileMM from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:33](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L33)

---

#### QuantileMM(y::Array{T, 1}, τs::Array{T, 1}, r::Float64)
Construct QuantileMM from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:33](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L33)

---

#### QuantileSGD(y::Array{T, 1})
Consturct QuantileSGD from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:16](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L16)

---

#### QuantileSGD(y::Array{T, 1}, τs::Array{T, 1})
Consturct QuantileSGD from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:16](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L16)

---

#### QuantileSGD(y::Array{T, 1}, τs::Array{T, 1}, r::Float64)
Consturct QuantileSGD from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:16](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L16)

---

#### Summary(y::Array{T, 1})
Construct `Summary` from Vector

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:17](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/summary.jl#L17)

---

#### Summary(y::DataArray{T, N})
Construct `Summary` from DataArray

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:25](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/summary.jl#L25)

---

#### convert(::Type{DataFrame}, obj::Summary)
Convert 'obj' to type 'DataFrame'

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:102](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/summary.jl#L102)

---

#### update!(obj::QuantileSGD, newdata::Array{T, 1})
Update quantile estimates using a new batch of data

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:48](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L48)

---

#### update!(obj::QuantileSGD, newdata::Array{T, 1}, addrow::Bool)
Update quantile estimates using a new batch of data

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:48](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L48)

---

#### update!(obj::Summary, newdata::Array{T, 1})
Update summary statistics with a new batch of data.

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:36](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/summary.jl#L36)

---

#### update!(obj::Summary, newdata::Array{T, 1}, add::Bool)
Update summary statistics with a new batch of data.

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:36](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/summary.jl#L36)

---

#### QuantileMM
Stores quantile estimating using an online MM algorithm

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:21](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L21)

---

#### QuantileSGD
Stores quantile estimates using a stochastic gradient descent algorithm

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/quantile.jl:7](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/quantile.jl#L7)

---

#### Summary
Stores analytical updates for mean, variance, maximum, and minimum.

**source:**
[/Users/jtday/.julia/OnlineStats/src/summary/summary.jl:6](https://github.com/joshday/OnlineStats.jl/tree/5fe4b1519450639988032b8e124eb5a95c0c4c70/src/summary/summary.jl#L6)


