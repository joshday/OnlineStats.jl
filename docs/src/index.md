# Basics

**OnlineStats** is a Julia package which provides *online parallelizable algorithms* for statistics.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

## Installation

```
Pkg.add("OnlineStats")
```

## Usage

### Every Stat is `<: OnlineStat`

```@example index
using OnlineStats

m = Mean()
```

### Stats Can Be Updated

```@example index
y = randn(100)

fit!(m, y)
```

### Stats Can Be Merged 

```@example index 
y2 = randn(100)

m2 = fit!(Mean(), y2)

merge!(m, m2)
```

### Stats Have a Value 

```@example index
value(m)
```

```@raw html
<img width = 200 src = "https://user-images.githubusercontent.com/8075494/32734476-260821d0-c860-11e7-8c91-49ba0b86397a.gif">
```