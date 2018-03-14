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
    "text": "The Series constructor accepts any number of OnlineStats, optionally preceded by data  to be fitted and/or a Weight.  When a Weight isn\'t specified, Series will use the default weight associated with the OnlineStats."
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
    "location": "series.html#Multiple-observations-1",
    "page": "Series",
    "title": "Multiple observations",
    "category": "section",
    "text": "note: Note\nIf a single observation is a Vector, a Matrix represents multiple observations, but this is ambiguous in how the observations are stored.  A Rows() (default) or Cols() argument can be added to the fit! call to specify observations are in rows or columns, respectively.s = Series(Mean())\nfit!(s, randn(100))\n\ns = Series(CovMatrix(4))\nfit!(s, randn(100, 4))          # Obs. in rows\nfit!(s, randn(4, 100), Cols())  # Obs. in columns"
},

{
    "location": "series.html#Merging-1",
    "page": "Series",
    "title": "Merging",
    "category": "section",
    "text": "Two Series can be merged if they track the same OnlineStats.merge(series1, series2, arg)\nmerge!(series1, series2, arg)Where series1/series2 are Series that contain the same OnlineStats and arg is used to determine how series2 should be merged into series1.y1 = randn(100)\ny2 = randn(100)\n\ns1 = Series(y1, Mean(), Variance())\ns2 = Series(y2, Mean(), Variance())\n\n# Treat s2 as a new batch of data using an `EqualWeight`.  Essentially:\n# s1 = Series(Mean(), Variance()); fit!(s1, y1); fit!(s1, y2)\nmerge!(s1, s2, :append)\n\n# Treat s2 as a single observation.\nmerge!(s1, s2, :singleton)\n\n# Provide the ratio of influence s2 should have.\nmerge!(s1, s2, .5)"
},

{
    "location": "series.html#AugmentedSeries-1",
    "page": "Series",
    "title": "AugmentedSeries",
    "category": "section",
    "text": "AugmentedSeries adds methods for filtering and applying functions to a data stream. The simplest way to constract an AugmentedSeries is through the series function:s = series(Mean(), filter = !isnan, transform = abs)\n\nfit!(s, [-1, NaN, -3])For a new data point y, the value transform(y) will be fitted, but only if filter(y) == true ."
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
    "location": "weights.html#OnlineStatsBase.EqualWeight",
    "page": "Weight",
    "title": "OnlineStatsBase.EqualWeight",
    "category": "type",
    "text": "EqualWeight()\n\nEqually weighted observations.  \n\ngamma_t = frac1t\n\nExample\n\nseries(randn(100), EqualWeight(), Variance())\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.ExponentialWeight",
    "page": "Weight",
    "title": "OnlineStatsBase.ExponentialWeight",
    "category": "type",
    "text": "ExponentialWeight(λ::Float64)\nExponentialWeight(lookback::Int)\n\nExponentially weighted observations.  The first weight is 1.0 and all else are  λ = 2 / (lookback + 1).\n\ngamma_1 = 1 gamma_t = lambda\n\nExample\n\nseries(randn(100), ExponentialWeight(), Variance())\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.LearningRate",
    "page": "Weight",
    "title": "OnlineStatsBase.LearningRate",
    "category": "type",
    "text": "LearningRate(r = .6)\n\nSlowly decreasing weight.  Satisfies the standard stochastic approximation assumption  sum gamma_t = infty sum gamma_t^2  infty if rin(5 1.\n\ngamma_t = frac1t^r\n\nExample\n\nSeries(randn(1000), LearningRate(.7), QuantileMM(), QuantileMSPI(), QuantileSGD())\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.HarmonicWeight",
    "page": "Weight",
    "title": "OnlineStatsBase.HarmonicWeight",
    "category": "type",
    "text": "HarmonicWeight(a = 10.0)\n\nWeight determined by harmonic series.  \n\ngamma_t = fracaa + t - 1\n\nExample\n\nSeries(randn(1000), HarmonicWeight(), QuantileMSPI())\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.McclainWeight",
    "page": "Weight",
    "title": "OnlineStatsBase.McclainWeight",
    "category": "type",
    "text": "McclainWeight(α = .1)\n\nWeight which decreases into a constant.\n\ngamma_t = fracgamma_t-11 + gamma_t-1 - alpha\n\nExample\n\nSeries(randn(100), McclainWeight(), Mean())\n\n\n\n"
},

{
    "location": "weights.html#Weight-Types-1",
    "page": "Weight",
    "title": "Weight Types",
    "category": "section",
    "text": "EqualWeight\nExponentialWeight\nLearningRate\nHarmonicWeight\nMcclainWeight"
},

{
    "location": "weights.html#OnlineStatsBase.Bounded",
    "page": "Weight",
    "title": "OnlineStatsBase.Bounded",
    "category": "type",
    "text": "Bounded(w::Weight, λ::Float64)\n\nBound the weight by a constant.\n\ngamma_t^* = textmax(gamma_t lambda)\n\nExample\n\nBounded(EqualWeight(), .1)\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.Scaled",
    "page": "Weight",
    "title": "OnlineStatsBase.Scaled",
    "category": "type",
    "text": "Scaled(w::Weight, λ::Float64)\n\nScale a weight by a constant.\n\ngamma_t^* = lambda * gamma_t\n\nExample\n\nBounded(LearningRate(.5), .1)\n\nSeries(randn(1000), 2.0 * LearningRate(.9), QuantileMM())\n\n\n\n"
},

{
    "location": "weights.html#Weight-wrappers-1",
    "page": "Weight",
    "title": "Weight wrappers",
    "category": "section",
    "text": "Bounded\nScaled"
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
    "text": "Statistic/Model OnlineStat\nUnivariate Statistics: \nMean Mean\nVariance Variance\nQuantiles Quantile and PQuantile\nMaximum/Minimum Extrema\nSkewness and kurtosis Moments\nSum Sum\nCount Count\nTime Series: \nDifference Diff\nLag Lag\nAutocorrelation/autocovariance AutoCov\nMultivariate Analysis: \nCovariance/correlation matrix CovMatrix\nPrincipal components analysis CovMatrix\nK-means clustering (SGD) KMeans\nMultiple univariate statistics Group\nNonparametric Density Estimation: \nHistograms Hist\nApproximate order statistics OrderStats\nCount for each unique value CountMap\nParametric Density Estimation: \nBeta FitBeta\nCauchy FitCauchy\nGamma FitGamma\nLogNormal FitLogNormal\nNormal FitNormal\nMultinomial FitMultinomial\nMvNormal FitMvNormal\nStatistical Learning: \nGLMs with regularization StatLearn\nLogistic regression StatLearn\nLinear SVMs StatLearn\nQuantile regression StatLearn\nAbsolute loss regression StatLearn\nDistance-weighted discrimination StatLearn\nHuber-loss regression StatLearn\nLinear (also ridge) regression LinReg, LinRegBuilder\nOther: \nStatistical Bootstrap Bootstrap\nApprox. count of distinct elements HyperLogLog\nReservoir sampling ReservoirSample\nCallbacks CallFun, mapblocks\nSummary of partition Partition, IndexedPartition"
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
    "text": "For OnlineStats that rely on approximations, merging isn\'t always a well-defined operation. In these cases, a warning will print that merging did not occur.  Please open an issue to discuss merging an OnlineStat if merging fails but you believe it should be merge-able."
},

{
    "location": "datasurrogates.html#",
    "page": "Data Surrogates",
    "title": "Data Surrogates",
    "category": "page",
    "text": "Pkg.add(\"GR\")\nPkg.add(\"Plots\")\nENV[\"GKSwstype\"] = \"100\"\nusing OnlineStats\nusing Plots\nsrand(123)\ngr()"
},

{
    "location": "datasurrogates.html#Data-Surrogates-1",
    "page": "Data Surrogates",
    "title": "Data Surrogates",
    "category": "section",
    "text": "Some OnlineStats are especially useful for out-of-core computations.  After they\'ve been fit, they act as a data stand-in to get summaries, quantiles, regressions, etc, without the need to revisit the entire dataset again."
},

{
    "location": "datasurrogates.html#Linear-Regressions-1",
    "page": "Data Surrogates",
    "title": "Linear Regressions",
    "category": "section",
    "text": "The LinRegBuilder type allows you to fit any linear regression model where y can be any variable and the x\'s can be any subset of variables.# make some data\nx = randn(10^6, 10)\ny = x * linspace(-1, 1, 10) + randn(10^6)\n\no = LinRegBuilder(11)\n\ns = Series([x y], o)\n\n# adds intercept term by default as last coefficient\ncoef(o; y = 11, verbose = true)"
},

{
    "location": "datasurrogates.html#Histograms-1",
    "page": "Data Surrogates",
    "title": "Histograms",
    "category": "section",
    "text": "The Hist type for online histograms uses a different algorithm based on whether the argument to the constructor is the number of bins or the bin edges.  Hist can be used  to calculate approximate summary statistics, without the need to revisit the actual data.o = Hist(20)        # adaptively find bins\no2 = Hist(-5:.5:5)  # specify the bin edges\ns = Series(o, o2)\n\nfit!(s, randexp(100_000))\n\nquantile(o, .5)\nquantile(o, [.2, .8])\nmean(o)\nvar(o)\nstd(o)\n\nusing Plots\nplot(s)\nsavefig(\"hist.png\"); nothing # hide(Image: )"
},

{
    "location": "visualizations.html#",
    "page": "Visualizations",
    "title": "Visualizations",
    "category": "page",
    "text": "Pkg.add(\"GR\")\nPkg.add(\"Plots\")\nENV[\"GKSwstype\"] = \"100\"\nusing OnlineStats\nusing Plots\nsrand(1234)\ngr()"
},

{
    "location": "visualizations.html#Visualizations-1",
    "page": "Visualizations",
    "title": "Visualizations",
    "category": "section",
    "text": ""
},

{
    "location": "visualizations.html#Plotting-a-Series-plots-the-contained-OnlineStats-1",
    "page": "Visualizations",
    "title": "Plotting a Series plots the contained OnlineStats",
    "category": "section",
    "text": "s = Series(randn(10^6), Hist(25), Hist(-5:5))\nplot(s)\nsavefig(\"plot_series.png\"); nothing # hide(Image: )"
},

{
    "location": "visualizations.html#Naive-Bayes-Classifier-1",
    "page": "Visualizations",
    "title": "Naive Bayes Classifier",
    "category": "section",
    "text": "The NBClassifier type stores conditional histograms of the predictor variables, allowing you to plot approximate \"group by\" distributions:# make data\nx = randn(10^5, 5)\ny = x * [1,3,5,7,9] .> 0\n\no = NBClassifier(5, Bool)  # 5 predictors with Boolean categories\nseries((x,y), o)\nplot(o)\nsavefig(\"nbclassifier.png\"); nothing # hide(Image: )"
},

{
    "location": "visualizations.html#Partitions-1",
    "page": "Visualizations",
    "title": "Partitions",
    "category": "section",
    "text": "The Partition type summarizes sections of a data stream using any OnlineStat,  and is therefore extremely useful in visualizing huge datasets, as summaries are plotted rather than every single observation.  "
},

{
    "location": "visualizations.html#Continuous-Data-1",
    "page": "Visualizations",
    "title": "Continuous Data",
    "category": "section",
    "text": "y = cumsum(randn(10^6)) + 100randn(10^6)\n\no = Partition(Hist(50))\n\ns = Series(y, o)\n\nplot(s, xlab = \"Nobs\")\nsavefig(\"partition_hist.png\"); nothing # hide(Image: )o = Partition(Mean())\no2 = Partition(Extrema())\n\ns = Series(y, o, o2)\n\nplot(s, layout = 1, xlab = \"Nobs\")\nsavefig(\"partition_mean_ex.png\"); nothing # hide(Image: )"
},

{
    "location": "visualizations.html#Plot-a-custom-function-of-the-OnlineStats-(default-is-value)-1",
    "page": "Visualizations",
    "title": "Plot a custom function of the OnlineStats (default is value)",
    "category": "section",
    "text": "Plot of mean +/- standard deviation:o = Partition(Variance())\n\ns = Series(y, o)\n\nplot(o, x -> [mean(x) - std(x), mean(x), mean(x) + std(x)], xlab = \"Nobs\")\nsavefig(\"partition_ci.png\"); nothing # hide  (Image: )"
},

{
    "location": "visualizations.html#Categorical-Data-1",
    "page": "Visualizations",
    "title": "Categorical Data",
    "category": "section",
    "text": "y = rand([\"a\", \"a\", \"b\", \"c\"], 10^6)\n\no = Partition(CountMap(String), 75)\n\ns = Series(y, o)\n\nplot(o, xlab = \"Nobs\", bar_widths = nobs.(o.parts))\nsavefig(\"partition_countmap.png\"); nothing # hide(Image: )"
},

{
    "location": "visualizations.html#Indexed-Partitions-1",
    "page": "Visualizations",
    "title": "Indexed Partitions",
    "category": "section",
    "text": "The Partition type can only track the number of observations in the x-axis.  If you wish to plot one variable against another, you can use an IndexedPartition.  x = rand(Date(2000):Date(2020), 10^5)\ny = Dates.year.(x) + randn(10^5)\n\ns = Series([x y], IndexedPartition(Date, Hist(20)))\n\nplot(s, xlab = \"Date\")\nsavefig(\"indexpart1.png\"); nothing # hide(Image: )x = randn(10^5)\ny = x + randn(10^5)\n\ns = Series([x y], IndexedPartition(Float64, Hist(20)))\n\nplot(s, ylab = \"Y\", xlab = \"X\")\nsavefig(\"indexpart2.png\"); nothing # hide(Image: )x = rand(\'a\':\'z\', 10^5)\ny = Float64.(x) + randn(10^5)\n\ns = Series([x y], IndexedPartition(Char, Extrema()))\n\nplot(s, xlab = \"Category\")\nsavefig(\"indexpart3.png\"); nothing # hide(Image: )x = rand(1:5, 10^5)\ny = rand(1:5, 10^5)\n\ns = Series([x y], IndexedPartition(Int, CountMap(Int)))\n\nplot(s, bar_width = 1, xlab = \"X\", ylab = \"Y\")\nsavefig(\"indexpart4.png\"); nothing # hide(Image: )"
},

{
    "location": "demos.html#",
    "page": "Demos",
    "title": "Demos",
    "category": "page",
    "text": ""
},

{
    "location": "demos.html#Demos-1",
    "page": "Demos",
    "title": "Demos",
    "category": "section",
    "text": "A collection of jupyter notebooks are hosted at https://github.com/joshday/OnlineStatsDemos.   To sync the notebooks to JuliaBox:Sign into https://next.juliabox.com\nClick Git in the toolbar\nAdd the git clone url https://github.com/joshday/OnlineStatsDemos.git"
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
    "category": "type",
    "text": "ADADELTA(ρ = .95)\n\nADADELTA ignores weight.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ADAGRAD",
    "page": "API",
    "title": "OnlineStats.ADAGRAD",
    "category": "type",
    "text": "ADAGRAD()\n\nAdaptive (element-wise learning rate) stochastic gradient descent.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ADAM",
    "page": "API",
    "title": "OnlineStats.ADAM",
    "category": "type",
    "text": "ADAM(α1 = .99, α2 = .999)\n\nAdaptive Moment Estimation with momentum parameters α1 and α2.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ADAMAX",
    "page": "API",
    "title": "OnlineStats.ADAMAX",
    "category": "type",
    "text": "ADAMAX(η, β1 = .9, β2 = .999)\n\nADAMAX with step size η and momentum parameters β1, β2\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.AdaptiveBins",
    "page": "API",
    "title": "OnlineStats.AdaptiveBins",
    "category": "type",
    "text": "Calculate a histogram adaptively.\n\nRef: http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.AugmentedSeries",
    "page": "API",
    "title": "OnlineStats.AugmentedSeries",
    "category": "type",
    "text": "AugmentedSeries(s::Series; filter = x->true, transform = identity)\n\nWrapper around a Series so that for new data, fitting occurs on transform(data), but  only if filter(data) == true.  See series.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.AutoCov",
    "page": "API",
    "title": "OnlineStats.AutoCov",
    "category": "type",
    "text": "AutoCov(b, T = Float64)\n\nCalculate the auto-covariance/correlation for lags 0 to b for a data stream of type T.\n\nExample\n\ny = cumsum(randn(100))\no = AutoCov(5)\nSeries(y, o)\nautocov(o)\nautocor(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Bootstrap",
    "page": "API",
    "title": "OnlineStats.Bootstrap",
    "category": "type",
    "text": "Bootstrap(o::OnlineStat, nreps = 100, d = [0, 2])\n\nOnline statistical bootstrap.  Create nreps replicates of o.  For each call to fit!, a replicate will be updated rand(d) times.\n\nExample\n\no = Bootstrap(Variance())\nSeries(randn(1000), o)\nconfint(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CStat",
    "page": "API",
    "title": "OnlineStats.CStat",
    "category": "type",
    "text": "CStat(stat)\n\nTrack a univariate OnlineStat for complex numbers.  A copy of stat is made to separately track the real and imaginary parts.\n\nExample\n\ny = randn(100) + randn(100)im\nSeries(y, CStat(Mean()))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CallFun",
    "page": "API",
    "title": "OnlineStats.CallFun",
    "category": "type",
    "text": "CallFun(o::OnlineStat, f::Function)\n\nCall f(o) every time the OnlineStat o gets updated.\n\nExample\n\nSeries(randn(5), CallFun(Mean(), info))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Count",
    "page": "API",
    "title": "OnlineStats.Count",
    "category": "type",
    "text": "Count()\n\nThe number of things observed.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CountMap",
    "page": "API",
    "title": "OnlineStats.CountMap",
    "category": "type",
    "text": "CountMap(T)\n\nMaintain a dictionary mapping unique values to its number of occurrences.  Equivalent to  StatsBase.countmap.  Ignores weight.\n\nMethods\n\nvalue(o): Dict of raw counts\nkeys(o): Unique values \nvalues(o): Counts\nprobs(o): Probabilities\n\nExample\n\nvals = [\"small\", \"medium\", \"large\"]\no = CountMap(String)\ns = Series(rand(vals, 1000), o)\nvalue(o)\nprobs(o)\nprobs(o, [\"small\", \"large\"])\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CovMatrix",
    "page": "API",
    "title": "OnlineStats.CovMatrix",
    "category": "type",
    "text": "CovMatrix(d)\n\nCovariance Matrix of d variables.  Principal component analysis can be performed using eigen decomposition of the covariance or correlation matrix.\n\nExample\n\ny = randn(100, 5)\no = CovMatrix(5)\nSeries(y, o)\n\n# PCA\nevals, evecs = eig(cor(o))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Diff",
    "page": "API",
    "title": "OnlineStats.Diff",
    "category": "type",
    "text": "Diff()\n\nTrack the difference and the last value.\n\nExample\n\ns = Series(randn(1000), Diff())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Extrema",
    "page": "API",
    "title": "OnlineStats.Extrema",
    "category": "type",
    "text": "Extrema(T::Type = Float64)\n\nMaximum and minimum.\n\nExample\n\ns = Series(randn(100), Extrema())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FastNode",
    "page": "API",
    "title": "OnlineStats.FastNode",
    "category": "type",
    "text": "FastNode(p, nclasses; stat = FitNormal())\n\nNode of a decision tree.  Assumes each predictor variable, conditioned on any  class, has a normal distribution.  Internal structure for FastTree. Observations must be a Pair/Tuple/NamedTuple of (VectorOb, Int)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FastTree",
    "page": "API",
    "title": "OnlineStats.FastTree",
    "category": "type",
    "text": "FastTree(npredictors, nclasses; maxsize=5000, splitsize=2000)\n\nCreate an online decision tree under the assumption that the distribution of any predictor  conditioned on any class is Normal.  The classes must be Ints beginning at one (1, 2, 3, ...). When a node hits splitsize observations, it will be given two children.  When the number of  nodes in the tree reaches maxsize, no more splits will occur.\n\nExample\n\nx = randn(10^5, 10)\ny = (x[:, 1] .> 0) .+ 1\n\ns = series((x,y), FastTree(10, 2))\n\nyhat = classify(s.stats[1], x)\nmean(y .== yhat)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitBeta",
    "page": "API",
    "title": "OnlineStats.FitBeta",
    "category": "type",
    "text": "FitBeta()\n\nOnline parameter estimate of a Beta distribution (Method of Moments).\n\nusing Distributions, OnlineStats\ny = rand(Beta(3, 5), 1000)\no = FitBeta()\ns = Series(y, o)\nBeta(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitCauchy",
    "page": "API",
    "title": "OnlineStats.FitCauchy",
    "category": "type",
    "text": "FitCauchy(alg = SGD())\n\nApproximate parameter estimation of a Cauchy distribution.  Estimates are based on quantiles, so that alg will be passed to Quantile.\n\nusing Distributions\ny = rand(Cauchy(0, 10), 10_000)\no = FitCauchy(SGD())\ns = Series(y, o)\nCauchy(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitGamma",
    "page": "API",
    "title": "OnlineStats.FitGamma",
    "category": "type",
    "text": "FitGamma()\n\nOnline parameter estimate of a Gamma distribution (Method of Moments).\n\nusing Distributions\ny = rand(Gamma(5, 1), 1000)\no = FitGamma()\ns = Series(y, o)\nGamma(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitLogNormal",
    "page": "API",
    "title": "OnlineStats.FitLogNormal",
    "category": "type",
    "text": "FitLogNormal()\n\nOnline parameter estimate of a LogNormal distribution (MLE).\n\nusing Distributions\ny = rand(LogNormal(3, 4), 1000)\no = FitLogNormal()\ns = Series(y, o)\nLogNormal(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitMultinomial",
    "page": "API",
    "title": "OnlineStats.FitMultinomial",
    "category": "type",
    "text": "FitMultinomial(p)\n\nOnline parameter estimate of a Multinomial distribution.  The sum of counts does not need to be consistent across observations.  Therefore, the n parameter of the Multinomial distribution is returned as 1.\n\nusing Distributions\ny = rand(Multinomial(10, [.2, .2, .6]), 1000)\no = FitMultinomial(3)\ns = Series(y\', o)\nMultinomial(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitMvNormal",
    "page": "API",
    "title": "OnlineStats.FitMvNormal",
    "category": "type",
    "text": "FitMvNormal(d)\n\nOnline parameter estimate of a d-dimensional MvNormal distribution (MLE).\n\nusing Distributions\ny = rand(MvNormal(zeros(3), eye(3)), 1000)\no = FitMvNormal(3)\ns = Series(y\', o)\nMvNormal(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitNormal",
    "page": "API",
    "title": "OnlineStats.FitNormal",
    "category": "type",
    "text": "FitNormal()\n\nOnline parameter estimate of a Normal distribution (MLE).\n\nusing Distributions\ny = rand(Normal(-3, 4), 1000)\no = FitNormal()\ns = Series(y, o)\nNormal(value(o)...)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Group",
    "page": "API",
    "title": "OnlineStats.Group",
    "category": "type",
    "text": "Group(stats...)\nGroup(n::Int, stat)\n[stat1 stat2 stat3 ...]\n\nCreate a vector-input stat from several scalar-input stats.  For a new observation y,  y[i] is sent to stats[i]. \n\nExamples\n\nSeries(randn(1000, 3), Group(3, Mean()))\n\ny = [randn(100) rand(Bool, 100)]\nSeries(y, [Mean() CountMap(Bool)])\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Hist",
    "page": "API",
    "title": "OnlineStats.Hist",
    "category": "type",
    "text": "Hist(e::AbstractVector)\nHist(b::Int)\n\nCalculate a histogram over bin edges fixed as e or adaptively find the best b bins.   The two options use FixedBins and AdaptiveBins, respectively.   FixedBins is much faster, but requires the range of the data to be known before it is  observed.  Hist objects can be used to return approximate summary statistics of the data.\n\nExample\n\no = Hist(-5:.1:5)\ny = randn(1000)\nSeries(y, o)\n\n# approximate summary statistics\nmean(o)\nvar(o)\nstd(o)\nmedian(o)\nextrema(o)\nquantile(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.HyperLogLog",
    "page": "API",
    "title": "OnlineStats.HyperLogLog",
    "category": "type",
    "text": "HyperLogLog(b)  # 4 ≤ b ≤ 16\n\nApproximate count of distinct elements.\n\nExample\n\ns = Series(rand(1:10, 1000), HyperLogLog(12))\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.KMeans",
    "page": "API",
    "title": "OnlineStats.KMeans",
    "category": "type",
    "text": "KMeans(p, k)\n\nApproximate K-Means clustering of k clusters and p variables.\n\nExample\n\nusing OnlineStats, Distributions\nd = MixtureModel([Normal(0), Normal(5)])\ny = rand(d, 100_000, 1)\ns = Series(y, LearningRate(.6), KMeans(1, 2))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Lag",
    "page": "API",
    "title": "OnlineStats.Lag",
    "category": "type",
    "text": "Lag(b, T = Float64)\n\nStore the last b values for a data stream of type T.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.LinReg",
    "page": "API",
    "title": "OnlineStats.LinReg",
    "category": "type",
    "text": "LinReg(p, λ::Float64 = 0.0)  # use λ for all parameters\nLinReg(p, λfactor::Vector{Float64})\n\nRidge regression of p variables with elementwise regularization.\n\nExample\n\nx = randn(100, 10)\ny = x * linspace(-1, 1, 10) + randn(100)\no = LinReg(10)\nSeries((x,y), o)\nvalue(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.LinRegBuilder",
    "page": "API",
    "title": "OnlineStats.LinRegBuilder",
    "category": "type",
    "text": "LinRegBuilder(p)\n\nCreate an object from which any variable can be regressed on any other set of variables, optionally with ridge (PenaltyFunctions.L2Penalty) regularization.  The main function to use with LinRegBuilder is coef:\n\ncoef(o::LinRegBuilder, λ = 0; y=1, x=[2,3,...], bias=true, verbose=false)\n\nReturn the coefficients of a regressing column y on columns x with ridge (L2Penalty)  parameter λ.  An intercept (bias) term is added by default.\n\nExamples\n\nx = randn(1000, 10)\no = LinRegBuilder(10)\ns = Series(x, o)\n\n# let response = x[:, 3]\ncoef(o; y=3, verbose=true) \n\n# let response = x[:, 7], predictors = x[:, [2, 5, 4]]\ncoef(o; y = 7, x = [2, 5, 4]) \n\n#\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MSPI",
    "page": "API",
    "title": "OnlineStats.MSPI",
    "category": "type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MV",
    "page": "API",
    "title": "OnlineStats.MV",
    "category": "type",
    "text": "MV is deprecated.  Use Group instead.\n\nMV(p, o)\np * o\n\nTrack p univariate OnlineStats o.\n\nExample\n\ny = randn(1000, 5)\no = MV(5, Mean())\ns = Series(y, o)\n\nSeries(y, 5Mean())\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Mean",
    "page": "API",
    "title": "OnlineStats.Mean",
    "category": "type",
    "text": "Mean()\n\nUnivariate mean.\n\nExample\n\ns = Series(randn(100), Mean())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Moments",
    "page": "API",
    "title": "OnlineStats.Moments",
    "category": "type",
    "text": "Moments()\n\nFirst four non-central moments.\n\nExample\n\ns = Series(randn(1000), Moments(10))\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Mosaic",
    "page": "API",
    "title": "OnlineStats.Mosaic",
    "category": "type",
    "text": "Mosaic(T::Type, S::Type)\n\nData structure for generating a mosaic plot, a comparison between two categorical variables.\n\nExample\n\nusing OnlineStats, Plots \nx = [rand() > .8 for i in 1:10^5]\ny = rand([1,2,2,3,3,3], 10^5)\ns = series([x y], Mosaic(Bool, Int))\nplot(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.NADAM",
    "page": "API",
    "title": "OnlineStats.NADAM",
    "category": "type",
    "text": "NADAM(α1 = .99, α2 = .999)\n\nAdaptive Moment Estimation with momentum parameters α1 and α2.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.NBClassifier",
    "page": "API",
    "title": "OnlineStats.NBClassifier",
    "category": "type",
    "text": "NBClassifier(p, label_type::Type)\n\nNaive Bayes Classifier of p predictors for classes of type label_type.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.NSGD",
    "page": "API",
    "title": "OnlineStats.NSGD",
    "category": "type",
    "text": "NSGD(α)\n\nNesterov accelerated Proximal Stochastic Gradient Descent.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAP",
    "page": "API",
    "title": "OnlineStats.OMAP",
    "category": "type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAS",
    "page": "API",
    "title": "OnlineStats.OMAS",
    "category": "type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OrderStats",
    "page": "API",
    "title": "OnlineStats.OrderStats",
    "category": "type",
    "text": "OrderStats(b::Int, T::Type = Float64)\n\nAverage order statistics with batches of size b.  Ignores weight.\n\nExample\n\ns = Series(randn(1000), OrderStats(10))\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.PQuantile",
    "page": "API",
    "title": "OnlineStats.PQuantile",
    "category": "type",
    "text": "PQuantile(τ = 0.5)\n\nCalculate the approximate quantile via the P^2 algorithm.  It is more computationally expensive than the algorithms used by Quantile, but also more exact.\n\nRef: https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf\n\nExample\n\ny = randn(10^6)\no1, o2, o3 = PQuantile(.25), PQuantile(.5), PQuantile(.75)\ns = Series(y, o1, o2, o3)\nvalue(s)\nquantile(y, [.25, .5, .75])\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Partition",
    "page": "API",
    "title": "OnlineStats.Partition",
    "category": "type",
    "text": "Partition(o::OnlineStat, b::Int)\n\nIncrementally partition a data stream where between b and 2b sections are summarized  by o. \n\nExample\n\nusing Plots\ns = Series(cumsum(randn(10^6)), Partition(Mean()))\nplot(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ProbMap",
    "page": "API",
    "title": "OnlineStats.ProbMap",
    "category": "type",
    "text": "ProbMap(T)\n\nMaintain a dictionary mapping unique values to its probability.  Similar to CountMap,  but tracks probabilities instead of counts and can incorporate different weights.  \n\nNOTE: Use only when weights other than EqualWeight are desired as ProbMap is slower  than CountMap.\n\nExample\n\ny = vcat(zeros(Int, 100), ones(Int, 100), 2ones(Int, 100))\n\n# give each observation an influence of 0.01\ns = Series(y, x -> .01, ProbMap(Int))\nsort(value(s.stats[1]))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Quantile",
    "page": "API",
    "title": "OnlineStats.Quantile",
    "category": "type",
    "text": "Quantile(q = [.25, .5, .75], alg = OMAS())\n\nApproximate the quantiles q via the stochastic approximation algorithm alg.  Options are SGD, MSPI, and OMAS.  In practice, SGD and MSPI only work well when the variance of the data is small.\n\nExample\n\ny = randn(10_000)\nτ = collect(.1:.1:.0)\nSeries(y, Quantile(τ, SGD()), Quantile(τ, MSPI()), Quantile(τ, OMAS()))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.RMSPROP",
    "page": "API",
    "title": "OnlineStats.RMSPROP",
    "category": "type",
    "text": "RMSPROP(α = .9)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ReservoirSample",
    "page": "API",
    "title": "OnlineStats.ReservoirSample",
    "category": "type",
    "text": "ReservoirSample(k, t = Float64)\n\nReservoir sample of k items.\n\nExample\n\no = ReservoirSample(k, Int)\ns = Series(o)\nfit!(s, 1:10000)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.SGD",
    "page": "API",
    "title": "OnlineStats.SGD",
    "category": "type",
    "text": "SGD()\n\nStochastic gradient descent.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Series",
    "page": "API",
    "title": "OnlineStats.Series",
    "category": "type",
    "text": "Series(stats...)\nSeries(weight, stats...)\nSeries(data, weight, stats...)\nSeries(data, stats...)\nSeries(weight, data, stats...)\n\nTrack any number of OnlineStats.\n\nExample\n\nSeries(Mean())\nSeries(randn(100), Mean())\nSeries(randn(100), ExponentialWeight(), Mean())\n\ns = Series(Quantile([.25, .5, .75]))\nfit!(s, randn(1000))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.StatLearn",
    "page": "API",
    "title": "OnlineStats.StatLearn",
    "category": "type",
    "text": "StatLearn(p::Int, args...)\n\nFit a statistical learning model of p independent variables for a given loss, penalty, and λ.  Additional arguments can be given in any order (and is still type stable):\n\nloss = .5 * L2DistLoss(): any Loss from LossFunctions.jl\npenalty = L2Penalty(): any Penalty (which has a prox method) from PenaltyFunctions.jl.\nλ = fill(.1, p): a Vector of element-wise regularization parameters\nupdater = SGD(): SGD, ADAGRAD, ADAM, ADAMAX, MSPI\n\nDetails\n\nThe (offline) objective function that StatLearn approximately minimizes is\n\nfrac1nsum_i=1^n f_i(beta) + sum_j=1^p lambda_j g(beta_j)\n\nwhere the f_i\'s are loss functions evaluated on a single observation, g is a penalty function, and the lambda_js are nonnegative regularization parameters.\n\nExample\n\nusing LossFunctions, PenaltyFunctions\nx = randn(100_000, 10)\ny = x * linspace(-1, 1, 10) + randn(100_000)\no = StatLearn(10, .5 * L2DistLoss(), L1Penalty(), fill(.1, 10), SGD())\ns = Series(o)\nfit!(s, x, y)\ncoef(o)\npredict(o, x)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Sum",
    "page": "API",
    "title": "OnlineStats.Sum",
    "category": "type",
    "text": "Sum()\n\nTrack the overall sum.\n\nExample\n\ns = Series(randn(1000), Sum())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Unique",
    "page": "API",
    "title": "OnlineStats.Unique",
    "category": "type",
    "text": "Unique(T::Type)\n\nTrack the unique values. \n\nExample\n\nseries(rand(1:5, 100), Unique(Int))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Variance",
    "page": "API",
    "title": "OnlineStats.Variance",
    "category": "type",
    "text": "Variance()\n\nUnivariate variance.\n\nExample\n\ns = Series(randn(100), Variance())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.mapblocks",
    "page": "API",
    "title": "OnlineStats.mapblocks",
    "category": "function",
    "text": "mapblocks(f::Function, b::Int, data, dim::ObsDimension = Rows())\n\nMap data in batches of size b to the function f.  If data includes an AbstractMatrix, the batches will be based on rows or columns, depending on dim.  Most usage is through Julia\'s do block syntax.\n\nExamples\n\ns = Series(Mean())\nmapblocks(10, randn(100)) do yi\n    fit!(s, yi)\n    info(\"nobs: $(nobs(s))\")\nend\n\nx = [1 2 3 4; \n     1 2 3 4; \n     1 2 3 4;\n     1 2 3 4]\nmapblocks(println, 2, x)\nmapblocks(println, 2, x, Cols())\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.series-Tuple{Vararg{Union{OnlineStatsBase.OnlineStat, OnlineStatsBase.Weight},N} where N}",
    "page": "API",
    "title": "OnlineStats.series",
    "category": "method",
    "text": "series(o::OnlineStat...; kw...)\nseries(wt::Weight, o::OnlineStat...; kw...)\nseries(data, o::OnlineStat...; kw...)\nseries(data, wt::Weight, o::OnlineStat...; kw...)\n\nCreate a Series or AugmentedSeries based on whether keyword arguments filter and transform are present.  \n\nExample\n\nseries(-rand(100), Mean(), Variance(); filter = isfinite, transform = abs)\n\n\n\n"
},

{
    "location": "api.html#StatsBase.confint",
    "page": "API",
    "title": "StatsBase.confint",
    "category": "function",
    "text": "confint(b::Bootstrap, coverageprob = .95)\n\nReturn a confidence interval for a Bootstrap b.\n\n\n\n"
},

{
    "location": "api.html#StatsBase.fit!-Tuple{OnlineStats.Series{0,T,W} where W where T<:Tuple,Union{AbstractArray{T,1} where T, NamedTuples.NamedTuple, Tuple}}",
    "page": "API",
    "title": "StatsBase.fit!",
    "category": "method",
    "text": "fit!(s::Series, data)\n\nUpdate a Series with more data. \n\nExamples\n\n# Univariate Series \ns = Series(Mean())\nfit!(s, randn(100))\n\n# Multivariate Series\nx = randn(100, 3)\ns = Series(CovMatrix(3))\nfit!(s, x)  # Same as fit!(s, x, Rows())\nfit!(s, x\', Cols())\n\n# Model Series\nx, y = randn(100, 10), randn(100)\ns = Series(LinReg(10))\nfit!(s, (x, y))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.BiasVec",
    "page": "API",
    "title": "OnlineStats.BiasVec",
    "category": "type",
    "text": "BiasVec(x, bias = 1.0)\n\nLightweight wrapper of a vector which adds a \"bias\" term at the end.\n\nExample\n\nOnlineStats.BiasVec(rand(5), 10)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MSPI2",
    "page": "API",
    "title": "OnlineStats.MSPI2",
    "category": "type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAP2",
    "page": "API",
    "title": "OnlineStats.OMAP2",
    "category": "type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAS2",
    "page": "API",
    "title": "OnlineStats.OMAS2",
    "category": "type",
    "text": "MSPI()  # Majorized stochastic proximal iteration\nMSPI2()\nOMAS()  # Online MM - Averaged Surrogate\nOMAS2()\nOMAP()  # Online MM - Averaged Parameter\nOMAP2()\n\nUpdaters based on majorizing functions.  MSPI/OMAS/OMAP define a family of  algorithms and not a specific update, thus each type has two possible versions.\n\nSee https://arxiv.org/abs/1306.4650 for OMAS\nAsk @joshday for details on OMAP and MSPI\n\n\n\n"
},

{
    "location": "api.html#Base.merge!-Union{Tuple{T,T,Symbol}, Tuple{T,T}, Tuple{T}} where T<:OnlineStats.Series",
    "page": "API",
    "title": "Base.merge!",
    "category": "method",
    "text": "merge!(s1::Series, s2::Series, arg)\n\nMerge s2 into s1 in place where s2\'s influence is determined by arg. Options for arg` are:\n\n:append (default)\nappends2tos1` with influence determined by number of observations.  For \nEqualWeight, this is equivalent to fit!(s1, data2) where s2 = Series(data2, o...).\n:singleton\ntreat s2 as a single observation.\nany Float64 in [0, 1]\n\n\n\n"
},

{
    "location": "api.html#Base.merge-Union{Tuple{T,T,Float64}, Tuple{T}} where T<:OnlineStats.AbstractSeries",
    "page": "API",
    "title": "Base.merge",
    "category": "method",
    "text": "See merge!\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.always-Tuple",
    "page": "API",
    "title": "OnlineStats.always",
    "category": "method",
    "text": "always returns true\n\n\n\n"
},

{
    "location": "api.html#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": "Modules = [OnlineStats]"
},

]}
