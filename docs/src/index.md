# Online algorithms for statistics

**OnlineStats** is a Julia package which provides online algorithms for statistical models.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all **algorithms use O(1) memory**.


## Basics

### Every OnlineStat is a type
```julia
m = Mean()
v = Variance()
```

### OnlineStats are grouped by [`Series`](@ref)
```julia
s = Series(m, v)
```

### Updating a Series updates the OnlineStats
```julia
y = randn(100)

for yi in y
    fit!(s, yi)
end

# or more simply:
fit!(s, y)
```
## Weighting

Series are parameterized by a `Weight` type that controls the influence the next observation
has on the OnlineStats contained in the Series.

```julia
s = Series(EqualWeight(), Mean())
```

Consider how weights affect the influence the next observation has on an online mean.  Many OnlineStats have an update which takes this form:


```math
\theta^{(t)} = (1-\gamma_t)\theta^{(t-1)} + \gamma_t x_t
```

| Constructor                     | Weight at Update `t`               |
|:-------------------------------:|:----------------------------------:|
| [`EqualWeight()`](@ref)         | `γ(t) = 1 / t`                     |
| [`ExponentialWeight(λ)`](@ref)  | `γ(t) = λ`                         |
| [`BoundedEqualWeight(λ)`](@ref) | `γ(t) = max(1 / t, λ)`             |
| [`LearningRate(r, λ)`](@ref)    | `γ(t) = max(1 / t ^ r, λ)`         |
| [`HarmonicWeight(a)`](@ref)     | `γ(t) = a / (a + t - 1)`           |
| [`McclainWeight(a)`](@ref)      | `γ(t) = γ(t-1) / (1 + γ(t-1) - a)` |

![](https://user-images.githubusercontent.com/8075494/27964520-908491d4-6306-11e7-9bef-0634359e5aa6.png)


## Series

The `Series` type is the workhorse of OnlineStats.  A Series tracks
1. The `Weight`
2. An OnlineStat or tuple of OnlineStats.

### Creating a Series
```julia
Series(Mean())
Series(Mean(), Variance())

Series(ExponentialWeight(), Mean())
Series(ExponentialWeight(), Mean(), Variance())

y = randn(100)

Series(y, Mean())
Series(y, Mean(), Variance())

Series(y, ExponentialWeight(.01), Mean())
Series(y, ExponentialWeight(.01), Mean(), Variance())
```

### Updating a Series
There are multiple ways to update the OnlineStats in a Series
- Single observation
  - Note: A single observation is a vector for OnlineStats such as `CovMatrix`
```julia
s = Series(Mean())
fit!(s, randn())

s = Series(CovMatrix(4))
fit!(s, randn(4))
fit!(s, randn(4))
```
- Single observation, override weight
```julia
s = Series(Mean())
fit!(s, randn(), rand())
```
- Multiple observations
  - Note: multiple observations are a matrix for OnlineStats such as `CovMatrix`.  By default, each *row* is considered an observation.  However, there exists `fit!` methods which use observations in *columns*.
```julia
s = Series(Mean())
fit!(s, randn(100))

s = Series(CovMatrix(4))
fit!(s, randn(100, 4))                 # Observations in rows
fit!(s, randn(4, 100), ObsDim.Last())  # Observations in columns
```

- Multiple observations, use the same weight for all
```julia
s = Series(Mean())
fit!(s, randn(100), .01)
```
- Multiple observations, provide vector of weights
```julia
s = Series(Mean())
fit!(s, randn(100), rand(100))
```
- Multiple observations, update in minibatches  
  OnlineStats which use stochastic approximation (`QuantileSGD`, `QuantileMM`, `KMeans`, etc.) have different behavior if they are updated in minibatches.  

  ```julia
  s = Series(QuantileSGD())
  fit!(s, randn(1000), 7)
  ```

[go to top](#readme-contents)
## Merging Series

Two Series can be merged if they track the same OnlineStats and those OnlineStats are
mergeable.  The syntax for in-place merging is

```julia
merge!(series1, series2, arg)
```

Where `series1`/`series2` are Series that contain the same OnlineStats and `arg` is used to determine how `series2` should be merged into `series1`.


```julia
using OnlineStats

y1 = randn(100)
y2 = randn(100)

s1 = Series(y1, Mean(), Variance())
s2 = Series(y2, Mean(), Variance())

# Treat s2 as a new batch of data.  Essentially:
# s1 = Series(Mean(), Variance()); fit!(s1, y1); fit!(s1, y2)
merge!(s1, s2, :append)

# Use weighted average based on nobs of each Series
merge!(s1, s2, :mean)

# Treat s2 as a single observation.
merge!(s1, s2, :singleton)

# Provide the ratio of influence s2 should have.
merge!(s1, s2, .5)
```


## Callbacks

While an OnlineStat is being updated, you may wish to perform an action like print intermediate results to a log file or update a plot.  For this purpose, OnlineStats exports a [`maprows`](@ref) function.

`maprows(f::Function, b::Integer, data...)`

`maprows` works similar to `Base.mapslices`, but maps `b` rows at a time.  It is best used with Julia's do block syntax.

### Example 1
- Input
```julia
y = randn(100)
s = Series(Mean())
maprows(20, y) do yi
    fit!(s, yi)
    info("value of mean is $(value(s))")
end
```
- Output
```
INFO: value of mean is 0.06340121912925167
INFO: value of mean is -0.06576995293439102
INFO: value of mean is 0.05374292238752276
INFO: value of mean is 0.008857939006120167
INFO: value of mean is 0.016199508928045905
```


## Low Level Details
### `OnlineStat{I, O, W}`
- The abstract type `OnlineStat` has two parameters:
  - `I`: The input dimension.  The size of one observation
  - `O`: The output dimension/object.  The size/object of `value`
  - `W`: The default weight.  OnlineStats that use stochastic approximation default to `LearningRate`.  Otherwise, the default is `EqualWeight`.
- A Series can only manage OnlineStats that share the same input type `I`.  This is because when you call a method like `fit!(s, randn(100))`, the Series needs to know whether `randn(100)` should be treated as 100 scalar observations or a single vector observation.


### `fit!` and `value`
- `fit!` updates the "sufficient statistics" of an OnlineStat, but does not necessarily update the parameter of interest.
- `value` creates the parameter of interest from the "sufficient statistics"
- This is the convention in order to avoid extra computation costs when the `value` is not needed while updating a chunk of data.
