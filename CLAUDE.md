# Development

- Run tests: `julia --project -e 'using Pkg; Pkg.test()'`
- Build docs: `julia -e 'include("docs/make.jl")'` (requires Documenter.jl and OnlineStatsBase)
- `docs/` uses Documenter.jl with HTML output. See `docs/make.jl` for page structure.
- This package uses a legacy `REQUIRE` file (no `Project.toml`). Dependencies are managed through `REQUIRE`.
- Never edit `REQUIRE` manually for adding test-only deps -- use `test/REQUIRE` if needed.

# Architecture

- **Entry point**: `src/OnlineStats.jl` -- main module that imports dependencies, defines exports, and includes all subfiles.
- **Base types**: Extends `OnlineStat{T}` from `OnlineStatsBase`. All statistics are subtypes of `OnlineStat{T}` where `T` indicates the input type.
- **Core interface**: Every stat implements `_fit!(stat, observation)` and optionally `_merge!(stat1, stat2)`. Users call `fit!` and `merge!` (from OnlineStatsBase/LearnBase).
- **Re-exports**: Uses `@reexport` to re-export `OnlineStatsBase`, `LossFunctions`, `PenaltyFunctions`, `LearnBase`.

## Source Layout

```
src/
    OnlineStats.jl          # Module definition, imports, exports
    utils.jl                # Type aliases (Tup, XY, VectorOb), smooth(), BiasVec, fit! overloads
    algorithms.jl           # SGD algorithm hierarchy: SGD, ADAM, ADAGRAD, ADADELTA, RMSPROP, etc.
    stats/
        stats.jl            # Core stats: Mean, Variance, Extrema, Sum, Moments, AutoCov, Bootstrap,
                            #   CallFun, Count, CountMap, CovMatrix, CStat, Diff, Group, GroupBy,
                            #   HeatMap, HyperLogLog, IndexedPartition, KMeans, Lag, MovingTimeWindow,
                            #   MovingWindow, OrderStats, Partition, ProbMap, ReservoirSample, Series,
                            #   StatHistory, FTSeries
        distributions.jl    # FitBeta, FitCauchy, FitGamma, FitLogNormal, FitNormal, FitMultinomial, FitMvNormal
        histograms.jl       # HistogramStat abstract type, Hist, KHist, P2Quantile, Quantile
        ml.jl               # ModelingType (Numerical, Categorical), DataPreprocessor, ModelSchema
        nbclassifier.jl     # NBClassifier (Naive Bayes)
        fasttree.jl         # FastNode, FastTree, FastForest (online decision trees)
        linreg.jl           # LinReg, LinRegBuilder (online linear regression via sweep operator)
        statlearn.jl        # StatLearn (online linear models with loss/penalty/algorithm)
    viz/
        recipes.jl          # RecipesBase plot recipes for Plots.jl
        partition.jl        # Partition and FTSeries visualization
        plotbivariate.jl    # 2D scatter plot recipes
        mosaicplot.jl       # Mosaic plot for categorical data
```

## Key Type Hierarchy

```
OnlineStat{T}                       # Abstract base (from OnlineStatsBase)
    ├── Mean, Variance{W}, Sum, Extrema, Moments, Count, Diff
    ├── AutoCov{T,W}, Lag
    ├── CovMatrix{W}, CountMap{T,D}, ProbMap{T,D}
    ├── Hist{T,R}, KHist, P2Quantile, Quantile{A}  (<: HistogramStat{T})
    ├── Series, Group, FTSeries       # Stat collections
    ├── GroupBy                        # Keyed stat collections
    ├── Bootstrap{T,O,D}
    ├── FastNode{G}, FastTree, FastForest
    ├── NBClassifier, LinReg, LinRegBuilder, StatLearn{A,L,P,W}
    └── HyperLogLog, KMeans, ReservoirSample, HeatMap, Partition, ...

Algorithm                            # Abstract base for SGD variants
    └── SGAlgorithm
        ├── SGD, ADAGRAD, RMSPROP, ADADELTA
        ├── ADAM, ADAMAX
        └── MSPI, OMAS, OMAP
```

## Design Patterns

- **Single-observation updates**: `_fit!(stat, single_obs)` processes one observation. Batch `fit!` methods in `utils.jl` handle matrices/iterables by calling `_fit!` per row.
- **Mergeability**: `_merge!(stat_into, stat_from)` combines two stats of the same type. Enables parallel/distributed computation.
- **Weight functions**: `EqualWeight`, `ExponentialWeight`, `LearningRate`, `HarmonicWeight`, `McclainWeight` control how new observations are weighted. `Bounded` and `Scaled` are weight wrappers.
- **`value(stat)`**: Returns the current computed value of a stat.
- **`nobs(stat)`**: Returns the number of observations seen.

# Tests

- Test file: `test/runtests.jl` (single file, ~586 lines)
- Tests are wrapped in a `module OnlineStatsTests` to avoid polluting the global namespace.
- Test data: `const y = randn(1000)`, `const x = randn(1000, 5)`, `const z = Complex.(randn(10000, 5), ...)` defined at module level.
- Helper functions:
    - `test_merge(o, y1, y2)`: Verifies that `fit!` + `merge!` produces the same result as `fit!` on concatenated data.
    - `test_exact(o, y, f)`: Verifies that the online stat matches the exact batch computation `f(y)`.
    - `nrows(y)`: Returns row count for both vectors and matrices.
- Tests are organized in `@testset` blocks by stat type.

# Style

- 4-space indentation
- Docstrings on all exports
- Use `### Examples` for inline docs examples
- Section separators in code: `#-----------------------------------------------------------------------# Section Title`

# CI

- **Travis CI** (`.travis.yml`): Linux + macOS, Julia 0.7 / 1.0 / nightly. Nightly failures allowed.
- **AppVeyor** (`appveyor.yml`): Windows, Julia 0.7 / 1.0 / nightly, x86 + x64.
- After-success hooks: Documenter.jl doc generation, Codecov coverage upload.

# Dependencies

Key dependencies (from `REQUIRE`):
- `OnlineStatsBase` (0.9-0.10): Abstract types and core `fit!`/`merge!` interface
- `LearnBase`: `fit!`, `nobs`, `value`, `predict`, `transform`
- `StatsBase`: `autocov`, `autocor`, `confint`, `skewness`, `kurtosis`, `Histogram`
- `DataStructures`: `OrderedDict`, `CircularBuffer`
- `SweepOperator`: Matrix sweep for linear regression
- `LossFunctions`: Loss functions for StatLearn
- `PenaltyFunctions`: Regularization penalties for StatLearn
- `RecipesBase`: Plot recipe definitions
- `Reexport`: Re-export dependent packages

# Releases

- Preflight: tests must pass and git status must be clean
- If current version has no git tag, release it as-is (don't bump)
- If current version is already tagged, bump based on commit log:
    - **Major**: major rewrites (ask user if major bump is ok)
    - **Minor**: new features, exports, or API additions
    - **Patch**: fixes, docs, refactoring, dependency updates (default)
- Commit message: `bump version for new release: {x} to {y}`
- Generate release notes from commits since last tag (group by features, fixes, etc.)
- For major/minor bumps, release notes must include "breaking changes" section
- Update CHANGELOG.md with each release
- Register via:
    ```
    gh api repos/{owner}/{repo}/commits/{sha}/comments -f body='@JuliaRegistrator register

    Release notes:

    <release notes here>'
    ```
