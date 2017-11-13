# Parallel Computation

Two Series can be merged if they track the same OnlineStats.  This facilitates [embarassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel) computations.

```julia
y1 = randn(100)
y2 = randn(100)
y3 = randn(100)

s1 = Series(Mean())
s2 = Series(Mean())
s3 = Series(Mean())

fit!(s1, y1)
fit!(s2, y2)
fit!(s3, y3)

merge!(s1, s2)  # merge information from s2 into s1
merge!(s1, s3)  # merge information from s3 into s1
```

![](https://user-images.githubusercontent.com/8075494/32733928-978bc52a-c85e-11e7-9505-993804b8f3c4.png)