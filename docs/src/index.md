# Basics

**OnlineStats** is a Julia package for statistical analysis with algorithms that run both **online** and **in parallel**.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.

## Installation

```
import Pkg
Pkg.add("OnlineStats")
```

## Basics

### Every Stat is `<: OnlineStat`

```@repl index
using OnlineStats

m = Mean()
```

### Stats Can Be Updated

```@repl index
y = randn(100);

fit!(m, y)
```

### Stats Can Be Merged 

```@repl index 
y2 = randn(100);

m2 = fit!(Mean(), y2)

merge!(m, m2)
```

### Stats Have a Value 

```@repl index
value(m)
```