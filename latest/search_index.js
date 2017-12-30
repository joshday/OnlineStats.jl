var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Basics",
    "title": "Basics",
    "category": "page",
    "text": ""
},

{
    "location": "index.html#Basics-1",
    "page": "Basics",
    "title": "Basics",
    "category": "section",
    "text": "OnlineStats is a Julia package which provides online parallelizable algorithms for statistics.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all algorithms use O(1) memory."
},

{
    "location": "index.html#Installation-1",
    "page": "Basics",
    "title": "Installation",
    "category": "section",
    "text": "Pkg.add(\"OnlineStats\")"
},

{
    "location": "index.html#Summary-of-Usage-1",
    "page": "Basics",
    "title": "Summary of Usage",
    "category": "section",
    "text": ""
},

{
    "location": "index.html#Every-statistic/model-is-a-type-(:-OnlineStat)-1",
    "page": "Basics",
    "title": "Every statistic/model is a type (<: OnlineStat)",
    "category": "section",
    "text": "using OnlineStats \n\nm = Mean()\nv = Variance()"
},

{
    "location": "index.html#OnlineStats-are-grouped-by-Series-1",
    "page": "Basics",
    "title": "OnlineStats are grouped by Series",
    "category": "section",
    "text": "s = Series(m, v)"
},

{
    "location": "index.html#Updating-a-Series-updates-the-contained-OnlineStats-1",
    "page": "Basics",
    "title": "Updating a Series updates the contained OnlineStats",
    "category": "section",
    "text": "y = randn(1000)\n\n# for yi in y\n#     fit!(s, yi)\n# end\nfit!(s, y)"
},

{
    "location": "index.html#OnlineStats-have-a-value-1",
    "page": "Basics",
    "title": "OnlineStats have a value",
    "category": "section",
    "text": "value(m) ≈ mean(y)    \nvalue(v) ≈ var(y)  "
},

{
    "location": "index.html#Merging-a-Series-merges-the-contained-OnlineStats-1",
    "page": "Basics",
    "title": "Merging a Series merges the contained OnlineStats",
    "category": "section",
    "text": "See Parallel Computation.y2 = randn(123)\n\ns2 = Series(y2, Mean(), Variance())\n\nmerge!(s, s2)\n\nvalue(m) ≈ mean(vcat(y, y2))    \nvalue(v) ≈ var(vcat(y, y2))  "
},

{
    "location": "index.html#Much-more-than-means-and-variances-1",
    "page": "Basics",
    "title": "Much more than means and variances",
    "category": "section",
    "text": "OnlineStats can do a lot.  See Statistics and Models.<img width = 200 src = \"https://user-images.githubusercontent.com/8075494/32734476-260821d0-c860-11e7-8c91-49ba0b86397a.gif\">"
},

{
    "location": "series.html#",
    "page": "Series",
    "title": "Series",
    "category": "page",
    "text": ""
},

{
    "location": "series.html#Series-1",
    "page": "Series",
    "title": "Series",
    "category": "section",
    "text": "The Series type is the workhorse of OnlineStats.  A Series tracksA tuple of OnlineStats.\nA Weight."
},

{
    "location": "series.html#Creating-a-Series-1",
    "page": "Series",
    "title": "Creating a Series",
    "category": "section",
    "text": "The Series constructor accepts any number of OnlineStats, optionally preceded by data  to be fitted and/or a Weight.  When a Weight isn't specified, Series will use the default weight associated with the OnlineStats."
},

{
    "location": "series.html#Start-\"empty\"-1",
    "page": "Series",
    "title": "Start \"empty\"",
    "category": "section",
    "text": "Series(Mean(), Variance())\n\nSeries(ExponentialWeight(), Mean(), Variance())"
},

{
    "location": "series.html#Start-with-initial-data-1",
    "page": "Series",
    "title": "Start with initial data",
    "category": "section",
    "text": "y = randn(100)\n\nSeries(y, Mean(), Variance())\n\nSeries(y, ExponentialWeight(.01), Mean(), Variance())\n\nSeries(ExponentialWeight(.01), y, Mean(), Variance())"
},

{
    "location": "series.html#Updating-1",
    "page": "Series",
    "title": "Updating",
    "category": "section",
    "text": "Updating a Series updates the OnlineStats it contains.  A Series can be updated with a single observation or a collection of observations via the fit! function:fit!(series, data)See OnlineStatsBase.jl for a look under  the hood of the update machinery."
},

{
    "location": "series.html#Single-observation-1",
    "page": "Series",
    "title": "Single observation",
    "category": "section",
    "text": "note: Note\nA single observation depends on the OnlineStat.  For example, a single observation for a Mean is Real and for a CovMatrix is AbstractVector or Tuple.s = Series(Mean())\nfit!(s, randn())\n\ns = Series(CovMatrix(4))\nfit!(s, randn(4))"
},

{
    "location": "series.html#Single-observation,-override-Weight-1",
    "page": "Series",
    "title": "Single observation, override Weight",
    "category": "section",
    "text": "s = Series(Mean())\nfit!(s, randn(), .1)"
},

{
    "location": "series.html#Multiple-observations-1",
    "page": "Series",
    "title": "Multiple observations",
    "category": "section",
    "text": "note: Note\nIf a single observation is a Vector, a Matrix represents multiple observations, but this is ambiguous in how the observations are stored.  A Rows() (default) or Cols() argument can be added to the fit! call to specify observations are in rows or columns, respectively.s = Series(Mean())\nfit!(s, randn(100))\n\ns = Series(CovMatrix(4))\nfit!(s, randn(100, 4))          # Obs. in rows\nfit!(s, randn(4, 100), Cols())  # Obs. in columns"
},

{
    "location": "series.html#Multiple-observations,-use-the-same-weight-for-all-1",
    "page": "Series",
    "title": "Multiple observations, use the same weight for all",
    "category": "section",
    "text": "s = Series(Mean())\nfit!(s, randn(100), .01)"
},

{
    "location": "series.html#Multiple-observations,-provide-vector-of-weights-1",
    "page": "Series",
    "title": "Multiple observations, provide vector of weights",
    "category": "section",
    "text": "s = Series(Mean())\nw = StatsBase.Weights(rand(100))\nfit!(s, randn(100), w)"
},

{
    "location": "series.html#Merging-1",
    "page": "Series",
    "title": "Merging",
    "category": "section",
    "text": "Two Series can be merged if they track the same OnlineStats.merge(series1, series2, arg)\nmerge!(series1, series2, arg)Where series1/series2 are Series that contain the same OnlineStats and arg is used to determine how series2 should be merged into series1.y1 = randn(100)\ny2 = randn(100)\n\ns1 = Series(y1, Mean(), Variance())\ns2 = Series(y2, Mean(), Variance())\n\n# Treat s2 as a new batch of data using an `EqualWeight`.  Essentially:\n# s1 = Series(Mean(), Variance()); fit!(s1, y1); fit!(s1, y2)\nmerge!(s1, s2, :append)\n\n# Use weighted average based on nobs of each Series\nmerge!(s1, s2, :mean)\n\n# Treat s2 as a single observation.\nmerge!(s1, s2, :singleton)\n\n# Provide the ratio of influence s2 should have.\nmerge!(s1, s2, .5)"
},

{
    "location": "weights.html#",
    "page": "Weight",
    "title": "Weight",
    "category": "page",
    "text": ""
},

{
    "location": "weights.html#Weight-1",
    "page": "Weight",
    "title": "Weight",
    "category": "section",
    "text": "Series is parameterized by a Weight type that controls the influence new observations.Consider how weights affect the influence of the next observation on an online mean theta^(t), as many OnlineStats use updates of this form.  A larger weight  gamma_t puts higher influence on the new observation x_t:theta^(t) = (1-gamma_t)theta^(t-1) + gamma_t x_tnote: Note\nThe values produced by a Weight must follow two rules:gamma_1 = 1 (guarantees theta^(1) = x_1)\ngamma_t in (0 1) quad forall t  1 (guarantees theta^(t) stays inside a convex space)<br>\n<img src=\"https://user-images.githubusercontent.com/8075494/29486708-a52b9de6-84ba-11e7-86c5-debfc5a80cca.png\" height=450>"
},

{
    "location": "weights.html#[EqualWeight()](@ref)-1",
    "page": "Weight",
    "title": "EqualWeight()",
    "category": "section",
    "text": "Each observation has an equal amount of influence.  This is the default for subtypes of  EqualStat, which can be updated exactly as the corresponding offline algorithm .gamma_t = frac1t"
},

{
    "location": "weights.html#[ExponentialWeight(λ-0.1)](@ref)-1",
    "page": "Weight",
    "title": "ExponentialWeight(λ = 0.1)",
    "category": "section",
    "text": "Each observation is weighted with a constant, giving newer observations higher influence and behaves similar to a rolling window.  ExponentialWeight is a good choice for observing  real-time data streams where the true parameter may be changing over time.gamma_t = lambda"
},

{
    "location": "weights.html#[LearningRate(r-0.6)](@ref)-1",
    "page": "Weight",
    "title": "LearningRate(r = 0.6)",
    "category": "section",
    "text": "Weights decrease at a slower rate than EqualWeight (if r < 1).  This is the default for StochasticStat subtypes, which are based on stochastic approximation.  For .5 < r < 1, each weight is between 1 / t and 1 / sqrt(t).gamma_t = frac1t^r"
},

{
    "location": "weights.html#[HarmonicWeight(a-10.0)](@ref)-1",
    "page": "Weight",
    "title": "HarmonicWeight(a = 10.0)",
    "category": "section",
    "text": "Weights are based on a general harmonic series.gamma_t = fracaa + t - 1"
},

{
    "location": "weights.html#[McclainWeight(a-0.1)](@ref)-1",
    "page": "Weight",
    "title": "McclainWeight(a = 0.1)",
    "category": "section",
    "text": "Consider McclainWeight as a smoothed version of Bounded{EqualWeight}.  Weights approach a positive constant a in the limit.gamma_t = fracgamma_t-11 + gamma_t-1 - a"
},

{
    "location": "weights.html#Weight-Wrappers-1",
    "page": "Weight",
    "title": "Weight Wrappers",
    "category": "section",
    "text": "Several types can change the behavior of a Weight."
},

{
    "location": "weights.html#[Bounded(weight,-λ)](@ref)-1",
    "page": "Weight",
    "title": "Bounded(weight, λ)",
    "category": "section",
    "text": "Bounded adds a minimum weight value.gamma_t = textmax(gamma_t )"
},

{
    "location": "weights.html#[Scaled(weight,-λ)](@ref)-1",
    "page": "Weight",
    "title": "Scaled(weight, λ)",
    "category": "section",
    "text": "Weights are scaled by a constant.  This should only be used with the StochasticStats  based on stochastic gradient algorithms, as it violates the  weight rules at the top of this page.  OnlineStats based on stochastic gradient algorithms  are Quantile, KMeans, and StatLearn.gamma_t =  * gamma_t"
},

{
    "location": "weights.html#Custom-Weighting-1",
    "page": "Weight",
    "title": "Custom Weighting",
    "category": "section",
    "text": "You can implement your own Weight type via OnlineStatsBase.jl or pass in a function to a Series in place of a weight.using OnlineStats # hide\n\ny = randn(100);\n\no = Mean()\nSeries(y, n -> 1/n, o)\n\nvalue(o) ≈ mean(y)"
},

{
    "location": "stats_and_models.html#",
    "page": "Statistics and Models",
    "title": "Statistics and Models",
    "category": "page",
    "text": ""
},

{
    "location": "stats_and_models.html#Statistics-and-Models-1",
    "page": "Statistics and Models",
    "title": "Statistics and Models",
    "category": "section",
    "text": "Statistic/Model OnlineStat\nUnivariate Statistics: \nMean Mean\nVariance Variance\nQuantiles Quantile and PQuantile\nMaximum/Minimum Extrema\nSkewness and kurtosis Moments\nSum Sum\nCount Count\nTime Series: \nDifference Diff\nLag Lag\nAutocorrelation/autocovariance AutoCov\nMultivariate Analysis: \nCovariance/correlation matrix CovMatrix\nPrincipal components analysis CovMatrix\nK-means clustering (SGD) KMeans\nMultiple univariate statistics MV{<:OnlineStat}\nNonparametric Density Estimation: \nHistograms Hist\nApproximate order statistics OrderStats\nCount for each unique value CountMap\nParametric Density Estimation: \nBeta FitBeta\nCauchy FitCauchy\nGamma FitGamma\nLogNormal FitLogNormal\nNormal FitNormal\nMultinomial FitMultinomial\nMvNormal FitMvNormal\nStatistical Learning: \nGLMs with regularization StatLearn\nLogistic regression StatLearn\nLinear SVMs StatLearn\nQuantile regression StatLearn\nAbsolute loss regression StatLearn\nDistance-weighted discrimination StatLearn\nHuber-loss regression StatLearn\nLinear (also ridge) regression LinReg, LinRegBuilder\nOther: \nStatistical Bootstrap Bootstrap\nApprox. count of distinct elements HyperLogLog\nReservoir sampling ReservoirSample\nCallbacks CallFun, mapblocks\nSummary of partition Partition"
},

{
    "location": "parallel.html#",
    "page": "Parallel Computation",
    "title": "Parallel Computation",
    "category": "page",
    "text": ""
},

{
    "location": "parallel.html#Parallel-Computation-1",
    "page": "Parallel Computation",
    "title": "Parallel Computation",
    "category": "section",
    "text": "Two Series can be merged if they track the same OnlineStats, which facilitates embarassingly parallel computations.  Merging in OnlineStats is used by JuliaDB to run analytics in parallel on large persistent datasets.note: Note\nIn general, fit! is a cheaper operation than merge!."
},

{
    "location": "parallel.html#ExactStat-merges-1",
    "page": "Parallel Computation",
    "title": "ExactStat merges",
    "category": "section",
    "text": "Many OnlineStats are subtypes of ExactStat, meaning the value of interest can be calculated exactly (compared to the appropriate offline algorithm).  For these OnlineStats, the order of fit!-ting and merge!-ing does not matter.  See subtypes(OnlineStats.ExactStat) for a full list.y1 = randn(10_000)\ny2 = randn(10_000)\ny3 = randn(10_000)\n\ns1 = Series(Mean(), Variance(), Hist(50))\ns2 = Series(Mean(), Variance(), Hist(50))\ns3 = Series(Mean(), Variance(), Hist(50))\n\nfit!(s1, y1)\nfit!(s2, y2)\nfit!(s3, y3)\n\nmerge!(s1, s2)  # merge information from s2 into s1\nmerge!(s1, s3)  # merge information from s3 into s1<img width = 500 src = \"https://user-images.githubusercontent.com/8075494/32748459-519986e8-c88a-11e7-89b3-80dedf7f261b.png\">"
},

{
    "location": "parallel.html#Other-Merges-1",
    "page": "Parallel Computation",
    "title": "Other Merges",
    "category": "section",
    "text": "For OnlineStats that rely on approximations, merging isn't always a well-defined operation. In these cases, a warning will print that merging did not occur.  Please open an issue to discuss merging an OnlineStat if merging fails but you believe it should be merge-able."
},

{
    "location": "datasurrogates.html#",
    "page": "Data Surrogates",
    "title": "Data Surrogates",
    "category": "page",
    "text": ""
},

{
    "location": "datasurrogates.html#Data-Surrogates-1",
    "page": "Data Surrogates",
    "title": "Data Surrogates",
    "category": "section",
    "text": "Some OnlineStats are especially useful for out-of-core computations.  After they've been fit, they act as a data stand-in to get summaries, quantiles, regressions, etc, without the need to revisit the entire dataset again."
},

{
    "location": "datasurrogates.html#Data-Summary-1",
    "page": "Data Surrogates",
    "title": "Data Summary",
    "category": "section",
    "text": "See Partitionusing OnlineStats, Plots\n\ny = rand([\"a\", \"b\", \"c\", \"d\"], 10^6)\n\no = Partition(CountMap(String))\n\ns = Series(y, o)\n\nplot(s)\n\nsavefig(\"partition.png\")  # hide\nnothing(Image: )"
},

{
    "location": "datasurrogates.html#Linear-Regressions-1",
    "page": "Data Surrogates",
    "title": "Linear Regressions",
    "category": "section",
    "text": "See LinRegBuilder"
},

{
    "location": "datasurrogates.html#Histograms-1",
    "page": "Data Surrogates",
    "title": "Histograms",
    "category": "section",
    "text": "The Hist type for online histograms has a  Plots.jl recipe and can also be used to calculate  approximate summary statistics, without the need to revisit the actual data.o = Hist(100)\ns = Series(o)\n\nfit!(s, randexp(100_000))\n\nquantile(o, .5)\nquantile(o, [.2, .8])\nmean(o)\nvar(o)\nstd(o)\n\nusing Plots\nplot(o)(Image: )"
},

{
    "location": "api.html#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "api.html#OnlineStats.ADADELTA",
    "page": "API",
    "title": "OnlineStats.ADADELTA",
    "category": "Type",
    "text": "ADADELTA(ρ = .95)\n\nADADELTA ignores weight.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ADAGRAD",
    "page": "API",
    "title": "OnlineStats.ADAGRAD",
    "category": "Type",
    "text": "ADAGRAD()\n\nAdaptive (element-wise learning rate) stochastic gradient descent.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ADAM",
    "page": "API",
    "title": "OnlineStats.ADAM",
    "category": "Type",
    "text": "ADAM(α1 = .99, α2 = .999)\n\nAdaptive Moment Estimation with momentum parameters α1 and α2.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ADAMAX",
    "page": "API",
    "title": "OnlineStats.ADAMAX",
    "category": "Type",
    "text": "ADAMAX(η, β1 = .9, β2 = .999)\n\nADAMAX with step size η and momentum parameters β1, β2\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.AutoCov",
    "page": "API",
    "title": "OnlineStats.AutoCov",
    "category": "Type",
    "text": "AutoCov(b, T = Float64)\n\nCalculate the auto-covariance/correlation for lags 0 to b for a data stream of type T.\n\nExample\n\ny = cumsum(randn(100))\no = AutoCov(5)\nSeries(y, o)\nautocov(o)\nautocor(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Bootstrap",
    "page": "API",
    "title": "OnlineStats.Bootstrap",
    "category": "Type",
    "text": "Bootstrap(o::OnlineStat, nreps = 100, d = [0, 2])\n\nOnline statistical bootstrap.  Create nreps replicates of o.  For each call to fit!, a replicate will be updated rand(d) times.\n\nExample\n\no = Bootstrap(Variance())\nSeries(randn(1000), o)\nconfint(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CStat",
    "page": "API",
    "title": "OnlineStats.CStat",
    "category": "Type",
    "text": "CStat(stat)\n\nTrack a univariate OnlineStat for complex numbers.  A copy of stat is made to separately track the real and imaginary parts.\n\nExample\n\ny = randn(100) + randn(100)im\nSeries(y, CStat(Mean()))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CallFun",
    "page": "API",
    "title": "OnlineStats.CallFun",
    "category": "Type",
    "text": "CallFun(o::OnlineStat{0}, f::Function)\n\nCall f(o) every time the OnlineStat o gets updated.\n\nExample\n\nSeries(randn(5), CallFun(Mean(), info))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Count",
    "page": "API",
    "title": "OnlineStats.Count",
    "category": "Type",
    "text": "Count()\n\nThe number of things observed.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CountMap",
    "page": "API",
    "title": "OnlineStats.CountMap",
    "category": "Type",
    "text": "CountMap(T)\n\nMaintain a dictionary mapping unique values to its number of occurrences.  Ignores weight  and is equivalent to StatsBase.countmap.\n\nExample\n\ns = Series(rand(1:10, 1000), CountMap(Int))\nvalue(s)[1]\n\nvals = [\"small\", \"medium\", \"large\"]\no = CountMap(String)\ns = Series(rand(vals, 1000), o)\nvalue(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CovMatrix",
    "page": "API",
    "title": "OnlineStats.CovMatrix",
    "category": "Type",
    "text": "CovMatrix(d)\n\nCovariance Matrix of d variables.  Principal component analysis can be performed using eigen decomposition of the covariance or correlation matrix.\n\nExample\n\ny = randn(100, 5)\no = CovMatrix(5)\nSeries(y, o)\n\n# PCA\nevals, evecs = eig(cor(o))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Diff",
    "page": "API",
    "title": "OnlineStats.Diff",
    "category": "Type",
    "text": "Diff()\n\nTrack the difference and the last value.\n\nExample\n\ns = Series(randn(1000), Diff())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Extrema",
    "page": "API",
    "title": "OnlineStats.Extrema",
    "category": "Type",
    "text": "Extrema()\n\nMaximum and minimum.\n\nExample\n\ns = Series(randn(100), Extrema())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitBeta",
    "page": "API",
    "title": "OnlineStats.FitBeta",
    "category": "Type",
    "text": "FitBeta()\n\nOnline parameter estimate of a Beta distribution (Method of Moments).\n\nusing Distributions, OnlineStats\ny = rand(Beta(3, 5), 1000)\no = FitBeta()\ns = Series(y, o)\nBeta(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitCauchy",
    "page": "API",
    "title": "OnlineStats.FitCauchy",
    "category": "Type",
    "text": "FitCauchy(alg = SGD())\n\nApproximate parameter estimation of a Cauchy distribution.  Estimates are based on quantiles, so that alg will be passed to Quantile.\n\nusing Distributions\ny = rand(Cauchy(0, 10), 10_000)\no = FitCauchy(SGD())\ns = Series(y, o)\nCauchy(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitGamma",
    "page": "API",
    "title": "OnlineStats.FitGamma",
    "category": "Type",
    "text": "FitGamma()\n\nOnline parameter estimate of a Gamma distribution (Method of Moments).\n\nusing Distributions\ny = rand(Gamma(5, 1), 1000)\no = FitGamma()\ns = Series(y, o)\nGamma(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitLogNormal",
    "page": "API",
    "title": "OnlineStats.FitLogNormal",
    "category": "Type",
    "text": "FitLogNormal()\n\nOnline parameter estimate of a LogNormal distribution (MLE).\n\nusing Distributions\ny = rand(LogNormal(3, 4), 1000)\no = FitLogNormal()\ns = Series(y, o)\nLogNormal(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitMultinomial",
    "page": "API",
    "title": "OnlineStats.FitMultinomial",
    "category": "Type",
    "text": "FitMultinomial(p)\n\nOnline parameter estimate of a Multinomial distribution.  The sum of counts does not need to be consistent across observations.  Therefore, the n parameter of the Multinomial distribution is returned as 1.\n\nusing Distributions\ny = rand(Multinomial(10, [.2, .2, .6]), 1000)\no = FitMultinomial(3)\ns = Series(y', o)\nMultinomial(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitMvNormal",
    "page": "API",
    "title": "OnlineStats.FitMvNormal",
    "category": "Type",
    "text": "FitMvNormal(d)\n\nOnline parameter estimate of a d-dimensional MvNormal distribution (MLE).\n\nusing Distributions\ny = rand(MvNormal(zeros(3), eye(3)), 1000)\no = FitMvNormal(3)\ns = Series(y', o)\nMvNormal(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitNormal",
    "page": "API",
    "title": "OnlineStats.FitNormal",
    "category": "Type",
    "text": "FitNormal()\n\nOnline parameter estimate of a Normal distribution (MLE).\n\nusing Distributions\ny = rand(Normal(-3, 4), 1000)\no = FitNormal()\ns = Series(y, o)\nNormal(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Hist",
    "page": "API",
    "title": "OnlineStats.Hist",
    "category": "Type",
    "text": "Hist(r::Range)\nHist(b::Int)\n\nCalculate a histogram over bin edges fixed as r or adaptively find the best b bins.   The two options use KnownBins and AdaptiveBins, respectively.   KnownBins is much faster, but requires the range of the data to be known before it is  observed.  Hist objects can be used to return approximate summary statistics of the data.\n\nExample\n\no = Hist(-5:.1:5)\ny = randn(1000)\nSeries(y, o)\n\n# approximate summary statistics\nmean(o)\nvar(o)\nstd(o)\nmedian(o)\nextrema(o)\nquantile(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.HyperLogLog",
    "page": "API",
    "title": "OnlineStats.HyperLogLog",
    "category": "Type",
    "text": "HyperLogLog(b)  # 4 ≤ b ≤ 16\n\nApproximate count of distinct elements.\n\nExample\n\ns = Series(rand(1:10, 1000), HyperLogLog(12))\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.KMeans",
    "page": "API",
    "title": "OnlineStats.KMeans",
    "category": "Type",
    "text": "KMeans(p, k)\n\nApproximate K-Means clustering of k clusters and p variables.\n\nExample\n\nusing OnlineStats, Distributions\nd = MixtureModel([Normal(0), Normal(5)])\ny = rand(d, 100_000, 1)\ns = Series(y, LearningRate(.6), KMeans(1, 2))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Lag",
    "page": "API",
    "title": "OnlineStats.Lag",
    "category": "Type",
    "text": "Lag(b, T = Float64)\n\nStore the last b values for a data stream of type T.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.LinReg",
    "page": "API",
    "title": "OnlineStats.LinReg",
    "category": "Type",
    "text": "LinReg(p, λ::Float64 = 0.0)  # use λ for all parameters\nLinReg(p, λfactor::Vector{Float64})\n\nRidge regression of p variables with elementwise regularization.\n\nExample\n\nx = randn(100, 10)\ny = x * linspace(-1, 1, 10) + randn(100)\no = LinReg(10)\nSeries((x,y), o)\nvalue(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.LinRegBuilder",
    "page": "API",
    "title": "OnlineStats.LinRegBuilder",
    "category": "Type",
    "text": "LinRegBuilder(p)\n\nCreate an object from which any variable can be regressed on any other set of variables, optionally with ridge (PenaltyFunctions.L2Penalty) regularization.  The main function to use with LinRegBuilder is coef:\n\ncoef(o::LinRegBuilder, λ = 0; y=1, x=[2,3,...], bias=true, verbose=false)\n\nReturn the coefficients of a regressing column y on columns x with ridge (L2Penalty)  parameter λ.  An intercept (bias) term is added by default.\n\nExamples\n\nx = randn(1000, 10)\no = LinRegBuilder(10)\ns = Series(x, o)\n\n# let response = x[:, 3]\ncoef(o; y=3, verbose=true) \n\n# let response = x[:, 7], predictors = x[:, [2, 5, 4]]\ncoef(o; y = 7, x = [2, 5, 4]) \n\n#\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MSPI",
    "page": "API",
    "title": "OnlineStats.MSPI",
    "category": "Type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MV",
    "page": "API",
    "title": "OnlineStats.MV",
    "category": "Type",
    "text": "MV(p, o)\np * o\n\nTrack p univariate OnlineStats o.\n\nExample\n\ny = randn(1000, 5)\no = MV(5, Mean())\ns = Series(y, o)\n\nSeries(y, 5Mean())\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Mean",
    "page": "API",
    "title": "OnlineStats.Mean",
    "category": "Type",
    "text": "Mean()\n\nUnivariate mean.\n\nExample\n\ns = Series(randn(100), Mean())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Moments",
    "page": "API",
    "title": "OnlineStats.Moments",
    "category": "Type",
    "text": "Moments()\n\nFirst four non-central moments.\n\nExample\n\ns = Series(randn(1000), Moments(10))\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.NADAM",
    "page": "API",
    "title": "OnlineStats.NADAM",
    "category": "Type",
    "text": "NADAM(α1 = .99, α2 = .999)\n\nAdaptive Moment Estimation with momentum parameters α1 and α2.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.NBClassifier",
    "page": "API",
    "title": "OnlineStats.NBClassifier",
    "category": "Type",
    "text": "NBClassifier(p, T, b = 20)\n\nCreate a Naive Bayes classifier for p predictors for classes of type T.  Conditional probabilities are estimated using the Hist (with AdaptiveBins) type with b bins.\n\nExample\n\nx = randn(100, 5)\ny = rand(Bool, 100)\no = NBClassifier(5, Bool)\nSeries((x,y), o)\npredict(o, x)\nclassify(o,x)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.NSGD",
    "page": "API",
    "title": "OnlineStats.NSGD",
    "category": "Type",
    "text": "NSGD(α)\n\nNesterov accelerated Proximal Stochastic Gradient Descent.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAP",
    "page": "API",
    "title": "OnlineStats.OMAP",
    "category": "Type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAS",
    "page": "API",
    "title": "OnlineStats.OMAS",
    "category": "Type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OrderStats",
    "page": "API",
    "title": "OnlineStats.OrderStats",
    "category": "Type",
    "text": "OrderStats(b)\n\nAverage order statistics with batches of size b.  Ignores weight.\n\nExample\n\ns = Series(randn(1000), OrderStats(10))\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.PQuantile",
    "page": "API",
    "title": "OnlineStats.PQuantile",
    "category": "Type",
    "text": "PQuantile(τ = 0.5)\n\nCalculate the approximate quantile via the P^2 algorithm.  It is more computationally expensive than the algorithms used by Quantile, but also more exact.\n\nRef: https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf\n\nExample\n\ny = randn(10^6)\no1, o2, o3 = PQuantile(.25), PQuantile(.5), PQuantile(.75)\ns = Series(y, o1, o2, o3)\nvalue(s)\nquantile(y, [.25, .5, .75])\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Partition",
    "page": "API",
    "title": "OnlineStats.Partition",
    "category": "Type",
    "text": "Partition(o::OnlineStat, b = 50)\n\nSplit a data stream between b and 2b parts, using o to summarize each part.\n\nExample\n\ny = randn(1000)\no = Partition(Mean())\nSeries(y, o)\nm = merge(o)  # merge partitions into a single `Mean`\nvalue(m) ≈ mean(y)\n\nusing Plots\nplot(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Quantile",
    "page": "API",
    "title": "OnlineStats.Quantile",
    "category": "Type",
    "text": "Quantile(q = [.25, .5, .75], alg = OMAS())\n\nApproximate the quantiles q via the stochastic approximation algorithm alg.  Options are SGD, MSPI, and OMAS.  In practice, SGD and MSPI only work well when the variance of the data is small.\n\nExample\n\ny = randn(10_000)\nτ = collect(.1:.1:.0)\nSeries(y, Quantile(τ, SGD()), Quantile(τ, MSPI()), Quantile(τ, OMAS()))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.RMSPROP",
    "page": "API",
    "title": "OnlineStats.RMSPROP",
    "category": "Type",
    "text": "RMSPROP(α = .9)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ReservoirSample",
    "page": "API",
    "title": "OnlineStats.ReservoirSample",
    "category": "Type",
    "text": "ReservoirSample(k, t = Float64)\n\nReservoir sample of k items.\n\nExample\n\no = ReservoirSample(k, Int)\ns = Series(o)\nfit!(s, 1:10000)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.SGD",
    "page": "API",
    "title": "OnlineStats.SGD",
    "category": "Type",
    "text": "SGD()\n\nStochastic gradient descent.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Series",
    "page": "API",
    "title": "OnlineStats.Series",
    "category": "Type",
    "text": "Series(stats...)\nSeries(weight, stats...)\nSeries(data, weight, stats...)\nSeries(data, stats...)\nSeries(weight, data, stats...)\n\nTrack any number of OnlineStats.\n\nExample\n\nSeries(Mean())\nSeries(randn(100), Mean())\nSeries(randn(100), ExponentialWeight(), Mean())\n\ns = Series(Quantile([.25, .5, .75]))\nfit!(s, randn(1000))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.StatLearn",
    "page": "API",
    "title": "OnlineStats.StatLearn",
    "category": "Type",
    "text": "StatLearn(p::Int, args...)\n\nFit a statistical learning model of p independent variables for a given loss, penalty, and λ.  Additional arguments can be given in any order (and is still type stable):\n\nloss = .5 * L2DistLoss(): any Loss from LossFunctions.jl\npenalty = L2Penalty(): any Penalty (which has a prox method) from PenaltyFunctions.jl.\nλ = fill(.1, p): a Vector of element-wise regularization parameters\nupdater = SGD(): SGD, ADAGRAD, ADAM, ADAMAX, MSPI\n\nDetails\n\nThe (offline) objective function that StatLearn approximately minimizes is\n\nfrac1nsum_i=1^n f_i(beta) + sum_j=1^p lambda_j g(beta_j)\n\nwhere the f_i's are loss functions evaluated on a single observation, g is a penalty function, and the lambda_js are nonnegative regularization parameters.\n\nExample\n\nusing LossFunctions, PenaltyFunctions\nx = randn(100_000, 10)\ny = x * linspace(-1, 1, 10) + randn(100_000)\no = StatLearn(10, .5 * L2DistLoss(), L1Penalty(), fill(.1, 10), SGD())\ns = Series(o)\nfit!(s, x, y)\ncoef(o)\npredict(o, x)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Sum",
    "page": "API",
    "title": "OnlineStats.Sum",
    "category": "Type",
    "text": "Sum()\n\nTrack the overall sum.\n\nExample\n\ns = Series(randn(1000), Sum())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Variance",
    "page": "API",
    "title": "OnlineStats.Variance",
    "category": "Type",
    "text": "Variance()\n\nUnivariate variance.\n\nExample\n\ns = Series(randn(100), Variance())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#LearnBase.value-Tuple{OnlineStats.Series}",
    "page": "API",
    "title": "LearnBase.value",
    "category": "Method",
    "text": "value(s::Series)\n\nReturn a tuple of value mapped to the OnlineStats contained in the Series.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.mapblocks",
    "page": "API",
    "title": "OnlineStats.mapblocks",
    "category": "Function",
    "text": "mapblocks(f::Function, b::Int, data, dim::ObsDimension = Rows())\n\nMap data in batches of size b to the function f.  If data includes an AbstractMatrix, the batches will be based on rows or columns, depending on dim.  Most usage is through Julia's do block syntax.\n\nExamples\n\ns = Series(Mean())\nmapblocks(10, randn(100)) do yi\n    fit!(s, yi)\n    info(\"nobs: $(nobs(s))\")\nend\n\nx = [1 2 3 4; \n     1 2 3 4; \n     1 2 3 4;\n     1 2 3 4]\nmapblocks(println, 2, x)\nmapblocks(println, 2, x, Cols())\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.stats-Tuple{OnlineStats.Series}",
    "page": "API",
    "title": "OnlineStats.stats",
    "category": "Method",
    "text": "stats(s::Series)\n\nReturn a tuple of the OnlineStats contained in the Series.\n\nExample\n\ns = Series(randn(100), Mean(), Variance())\nm, v = stats(s)\n\n\n\n"
},

{
    "location": "api.html#StatsBase.confint",
    "page": "API",
    "title": "StatsBase.confint",
    "category": "Function",
    "text": "confint(b::Bootstrap, coverageprob = .95)\n\nReturn a confidence interval for a Bootstrap b.\n\n\n\n"
},

{
    "location": "api.html#StatsBase.fit!-Tuple{OnlineStats.Series{0,T,W} where W where T<:Tuple,Union{AbstractString, Number, Symbol}}",
    "page": "API",
    "title": "StatsBase.fit!",
    "category": "Method",
    "text": "fit!(s::Series, data, args...)\n\nUpdate a Series with more data.  Additional arguments can be used to \n\noverride the weight\nuse the columns of a matrix as observations (default is rows)\n\nExamples\n\n# Univariate Series \ns = Series(Mean())\nfit!(s, randn(100))\n\n# Multivariate Series\nx = randn(100, 3)\ns = Series(CovMatrix(3))\nfit!(s, x)  # Same as fit!(s, x, Rows())\nfit!(s, x', Cols())\n\n# overriding the weight\nfit!(s, x, .1)  # use .1 for every observation's weight\nw = rand(100)\nfit!(s, x, w)  # use w[i] as the weight for observation x[i, :]\n\n# Model Series\nx, y = randn(100, 10), randn(100)\ns = Series(LinReg(10))\nfit!(s, (x, y))\n\n\n\n"
},

{
    "location": "api.html#StatsBase.nobs-Tuple{OnlineStats.Series}",
    "page": "API",
    "title": "StatsBase.nobs",
    "category": "Method",
    "text": "nobs(s::Series)\n\nReturn the number of observations the Series has fit!-ted.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.AdaptiveBins",
    "page": "API",
    "title": "OnlineStats.AdaptiveBins",
    "category": "Type",
    "text": "Calculate a histogram adaptively.\n\nRef: http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.BiasVec",
    "page": "API",
    "title": "OnlineStats.BiasVec",
    "category": "Type",
    "text": "BiasVec(x, bias = 1.0)\n\nLightWeight wrapper of a vector which adds a \"bias\" term at the end.\n\nExample\n\nOnlineStats.BiasVec(rand(5), 10)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.KnownBins",
    "page": "API",
    "title": "OnlineStats.KnownBins",
    "category": "Type",
    "text": "Calculate a histogram over a fixed range.  \n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MSPI2",
    "page": "API",
    "title": "OnlineStats.MSPI2",
    "category": "Type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAP2",
    "page": "API",
    "title": "OnlineStats.OMAP2",
    "category": "Type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAS2",
    "page": "API",
    "title": "OnlineStats.OMAS2",
    "category": "Type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Part",
    "page": "API",
    "title": "OnlineStats.Part",
    "category": "Type",
    "text": "Part(o::OnlineStat, start::Int)\n\nSummary for a section of data.  o is an unfitted OnlineStat to be fitted on observations  beginning with observation start.\n\n\n\n"
},

{
    "location": "api.html#Base.merge!-Union{Tuple{T,T,Symbol}, Tuple{T,T}, Tuple{T}} where T<:OnlineStats.Series",
    "page": "API",
    "title": "Base.merge!",
    "category": "Method",
    "text": "merge!(s1::Series, s2::Series, arg)\n\nMerge s2 into s1 in place where s2's influence is determined by arg. Options for arg` are:\n\n:append (default)\nappends2tos1` with influence determined by number of observations.  For \nEqualWeight, this is equivalent to fit!(s1, data2) where s2 = Series(data2, o...).\n:mean\nUse the average (weighted by nobs) of the Series' generated weights.\n:singleton\ntreat s2 as a single observation.\nany Float64 in [0, 1]\n\n\n\n"
},

{
    "location": "api.html#Base.merge-Tuple{OnlineStats.Series,OnlineStats.Series,Float64}",
    "page": "API",
    "title": "Base.merge",
    "category": "Method",
    "text": "See merge!\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.Bounded",
    "page": "API",
    "title": "OnlineStatsBase.Bounded",
    "category": "Type",
    "text": "Bounded(w::Weight, λ::Float64)\n\nBound the weight by a constant.\n\n_bounded(t) = max((t) )\n\nExample\n\nBounded(EqualWeight(), .1)\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.EqualWeight",
    "page": "API",
    "title": "OnlineStatsBase.EqualWeight",
    "category": "Type",
    "text": "EqualWeight()\n\nEqually weighted observations.  \n\n(t) = 1  t\n\nExample\n\nSeries(randn(100), EqualWeight(), Variance())\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.ExactStat",
    "page": "API",
    "title": "OnlineStatsBase.ExactStat",
    "category": "Type",
    "text": "An OnlineStat which can be updated exactly.  Subtypes of ExactStat use EqualWeight() as the default weight.\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.ExponentialWeight",
    "page": "API",
    "title": "OnlineStatsBase.ExponentialWeight",
    "category": "Type",
    "text": "ExponentialWeight(λ::Float64)\nExponentialWeight(lookback::Int)\n\nExponentially weighted observations.  \n\n(t) =  = 2  (lookback + 1)\n\nExample\n\nSeries(randn(100), ExponentialWeight(), Variance())\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.HarmonicWeight",
    "page": "API",
    "title": "OnlineStatsBase.HarmonicWeight",
    "category": "Type",
    "text": "HarmonicWeight(a = 10.0)\n\nWeight determined by harmonic series.  \n\n(t) = a  (a + t - 1)\n\nExample\n\nSeries(randn(1000), HarmonicWeight(), QuantileMSPI())\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.LearningRate",
    "page": "API",
    "title": "OnlineStatsBase.LearningRate",
    "category": "Type",
    "text": "LearningRate(r = .6)\n\nSlowly decreasing weight.  \n\n(t) = 1  t^r\n\nExample\n\nSeries(randn(1000), LearningRate(.7), QuantileMM(), QuantileMSPI(), QuantileSGD())\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.LearningRate2",
    "page": "API",
    "title": "OnlineStatsBase.LearningRate2",
    "category": "Type",
    "text": "LearningRate2(c = .5)\n\nSlowly decreasing weight.  \n\n(t) = 1  (1 + c * (t - 1))\n\nExample\n\nSeries(randn(1000), LearningRate2(.3), QuantileMM(), QuantileMSPI(), QuantileSGD())\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.McclainWeight",
    "page": "API",
    "title": "OnlineStatsBase.McclainWeight",
    "category": "Type",
    "text": "McclainWeight(α = .1)\n\nWeight which decreases into a constant.\n\n(t) = (t-1)  (1 + (t) - )\n\nExample\n\nSeries(randn(100), McclainWeight(), Mean())\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.Scaled",
    "page": "API",
    "title": "OnlineStatsBase.Scaled",
    "category": "Type",
    "text": "Scaled(w::Weight, λ::Float64)\n\nScale a weight by a constant.\n\n_scaled(t) =  * (t)\n\nExample\n\nBounded(LearningRate(.5), .1)\n\nSeries(randn(1000), 2.0 * LearningRate(.9), QuantileMM())\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.StochasticStat",
    "page": "API",
    "title": "OnlineStatsBase.StochasticStat",
    "category": "Type",
    "text": "An OnlineStat which must be approximated.  Subtypes of StochasticStat use  LearningRate() as the default weight.  Additionally, subtypes should be parameterized by an algorithm, which is an optional last argument.  For example:\n\nstruct Quantile{T <: Updater} <: StochasticStat{0}\n    value::Vector{Float64}\n    τ::Vector{Float64}\n    updater::T \nend\nQuantile(τ::AbstractVector = [.25, .5, .75], u::Updater = SGD()) = ...\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.Weight",
    "page": "API",
    "title": "OnlineStatsBase.Weight",
    "category": "Type",
    "text": "Subtypes of Weight must be callable to produce the weight given the current number of  observations in an OnlineStat n and the number of new observations (n2).\n\nMyWeight(n, n2 = 1)\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase._fit!",
    "page": "API",
    "title": "OnlineStatsBase._fit!",
    "category": "Function",
    "text": "_fit!(o::OnlineStat, observation::TypeOfObservation, γ::Float64)\n\nUpdate an OnlineStat with a single observation by a weight γ.  TypeOfObservation depends on typof(o).\n\n\n\n"
},

{
    "location": "api.html#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": "Modules = [OnlineStats, OnlineStatsBase]"
},

]}
