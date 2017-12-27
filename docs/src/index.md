# Basics

**OnlineStats** is a Julia package which provides *online parallelizable algorithms* for statistics and models.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

## Installation

```
Pkg.add("OnlineStats")
```

## Usage

```
using OnlineStats

#### Every statistic/model a type (<: OnlineStat)
m = Mean()
v = Variance()

#### OnlineStats are grouped by Series
s = Series(m, v)

#### Updating a series updates the OnlineStats in place
y = randn(100)

# for yi in y
#     fit!(s, yi)
# end
fit!(s, y)

#### OnlineStats have a `value`
value(m) ≈ mean(y)    
value(v) ≈ var(y)  
```

```@raw html
<img width = 200 src = "https://user-images.githubusercontent.com/8075494/32734476-260821d0-c860-11e7-8c91-49ba0b86397a.gif">
```

## Much more than means and variances

OnlineStats can do a lot.  See [Statistics and Models](@ref).