# News

The master branch of OnlineStats has some considerable differences from the latest release (v0.16.0).  Here is a summary of the biggest changes:

- Stats no longer need to be wrapped in a `Series`.  `Series` still exists as a collection of stats that should be applied to the same data stream.  The `Series` constructor no longer accepts data.
    - Single stat:
        - Old: `Series(data, Mean())`
        - New: `fit!(Mean(), data)`
    - Multiple stats:
        - Old: `Series(data, Mean(), Variance())`
        - New: `fit!(Series(Mean(), Variance()), data)`
- Stats are now subtypes of `OnlineStat{T}` where `T` is the type of a single observation.  As a result, some constructors require additional information in order for `fit!` to dispatch correctly.
    - Example: `HyperLogLog(b)` is now `HyperLogLog(b, T=Number)`.
    - Example: `Mean` is now a subtype of `OnlineStat{Number}`.
- Some constructors no longer require size-of-the-input information.
    - Old: `Series(randn(10, 2), CovMatrix(2))`
    - New: `fit!(CovMatrix(), randn(10, 2))`
- If a stat can use a weighting mechanism, it will have one of the following keyword arguments:
    - `weight = EqualWeight()` for stats that can be calculated the same as offline counterparts.
    - `rate = LearningRate(.6)` for stats that use stochastic approximation.