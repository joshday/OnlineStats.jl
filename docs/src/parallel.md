# Parallel Computation

Two Series can be merged if they track the same OnlineStats.  This facilitates [embarassingly parallel](https://en.wikipedia.org/wiki/Embarrassingly_parallel) computations.

```julia
y1 = randn(10_000)
y2 = randn(10_000)
y3 = randn(10_000)

s1 = Series(Mean(), Variance(), IHistogram(50))
s2 = Series(Mean(), Variance(), IHistogram(50))
s3 = Series(Mean(), Variance(), IHistogram(50))

fit!(s1, y1)
fit!(s1, y2)
fit!(s2, y3)

merge!(s1, s2)  # merge information from s2 into s1
merge!(s1, s3)  # merge information from s3 into s1
```

![](https://user-images.githubusercontent.com/8075494/32747944-8ca9e3e2-c888-11e7-8492-d333309793d9.png)