var documenterSearchIndex = {"docs": [

{
    "location": "index.html#",
    "page": "Basics",
    "title": "Basics",
    "category": "page",
    "text": "<img width = 200 src = \"https://user-images.githubusercontent.com/8075494/27987219-12fe7fc2-63d8-11e7-9869-8cfc5cb6e6c9.gif\">"
},

{
    "location": "index.html#Basics-1",
    "page": "Basics",
    "title": "Basics",
    "category": "section",
    "text": "OnlineStats is a Julia package which provides online algorithms for statistical models.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all algorithms use O(1) memory."
},

{
    "location": "index.html#Every-OnlineStat-is-a-type-1",
    "page": "Basics",
    "title": "Every OnlineStat is a type",
    "category": "section",
    "text": "m = Mean()\nv = Variance()"
},

{
    "location": "index.html#OnlineStats-are-grouped-by-[Series](@ref)-1",
    "page": "Basics",
    "title": "OnlineStats are grouped by Series",
    "category": "section",
    "text": "s = Series(m, v)"
},

{
    "location": "index.html#Updating-a-Series-updates-the-OnlineStats-1",
    "page": "Basics",
    "title": "Updating a Series updates the OnlineStats",
    "category": "section",
    "text": "y = randn(100)\n\nfor yi in y\n    fit!(s, yi)\nend\n\n# or more simply:\nfit!(s, y)"
},

{
    "location": "index.html#Callbacks-1",
    "page": "Basics",
    "title": "Callbacks",
    "category": "section",
    "text": "While an OnlineStat is being updated, you may wish to perform an action like print intermediate results to a log file or update a plot.  For this purpose, OnlineStats exports a maprows function.maprows(f::Function, b::Integer, data...)maprows works similar to Base.mapslices, but maps b rows at a time.  It is best used with Julia's do block syntax.Inputy = randn(100)\ns = Series(Mean())\nmaprows(20, y) do yi\n    fit!(s, yi)\n    info(\"value of mean is $(value(s))\")\nendOutputINFO: value of mean is 0.06340121912925167\nINFO: value of mean is -0.06576995293439102\nINFO: value of mean is 0.05374292238752276\nINFO: value of mean is 0.008857939006120167\nINFO: value of mean is 0.016199508928045905"
},

{
    "location": "pages/weights.html#",
    "page": "Weighting",
    "title": "Weighting",
    "category": "page",
    "text": ""
},

{
    "location": "pages/weights.html#Weighting-1",
    "page": "Weighting",
    "title": "Weighting",
    "category": "section",
    "text": "Series are parameterized by a Weight type that controls the influence of the next observation.Consider how the following weighting schemes affect the influence of the next observation on an online mean.  Many OnlineStats have an update of this form:theta^(t) = (1-gamma_t)theta^(t-1) + gamma_t x_t(Image: )"
},

{
    "location": "pages/weights.html#[EqualWeight()](@ref)-1",
    "page": "Weighting",
    "title": "EqualWeight()",
    "category": "section",
    "text": "Each observation has an equal amount of influence.gamma_t = frac1t"
},

{
    "location": "pages/weights.html#[ExponentialWeight(λ)](@ref)-1",
    "page": "Weighting",
    "title": "ExponentialWeight(λ)",
    "category": "section",
    "text": "Each observation is weighted with a constant, giving newer observations higher influence.gamma_t = lambda"
},

{
    "location": "pages/weights.html#[LearningRate(r)](@ref)-1",
    "page": "Weighting",
    "title": "LearningRate(r)",
    "category": "section",
    "text": "Decrease at a slow rate until a threshold is hit.gamma_t = frac1t^r"
},

{
    "location": "pages/weights.html#[HarmonicWeight(a)](@ref)-1",
    "page": "Weighting",
    "title": "HarmonicWeight(a)",
    "category": "section",
    "text": "Decrease at a slow rate.gamma_t = fracaa + t - 1"
},

{
    "location": "pages/weights.html#[McclainWeight(a)](@ref)-1",
    "page": "Weighting",
    "title": "McclainWeight(a)",
    "category": "section",
    "text": "Smoothed version of BoundedEqualWeight.gamma_t = fracgamma_t-11 + gamma_t-1 - a"
},

{
    "location": "pages/weights.html#[Bounded(weight,-λ)](@ref)-1",
    "page": "Weighting",
    "title": "Bounded(weight, λ)",
    "category": "section",
    "text": "Wrapper for a weight which provides a minimum boundgamma_t = textmax(gamma_t )"
},

{
    "location": "pages/series.html#",
    "page": "Series",
    "title": "Series",
    "category": "page",
    "text": ""
},

{
    "location": "pages/series.html#Series-1",
    "page": "Series",
    "title": "Series",
    "category": "section",
    "text": "The Series type is the workhorse of OnlineStats.  A Series tracksThe Weight\nAn OnlineStat or tuple of OnlineStats."
},

{
    "location": "pages/series.html#Creating-1",
    "page": "Series",
    "title": "Creating",
    "category": "section",
    "text": "Start \"empty\"Series(Mean())\nSeries(Mean(), Variance())\n\nSeries(ExponentialWeight(), Mean())\nSeries(ExponentialWeight(), Mean(), Variance())Start with initial datay = randn(100)\n\nSeries(y, Mean())\nSeries(y, Mean(), Variance())\n\nSeries(y, ExponentialWeight(.01), Mean())\nSeries(y, ExponentialWeight(.01), Mean(), Variance())\n\nSeries(ExponentialWeight(.01), y, Mean())\nSeries(ExponentialWeight(.01), y, Mean(), Variance())"
},

{
    "location": "pages/series.html#Updating-1",
    "page": "Series",
    "title": "Updating",
    "category": "section",
    "text": ""
},

{
    "location": "pages/series.html#Single-observation-1",
    "page": "Series",
    "title": "Single observation",
    "category": "section",
    "text": "note: Note\nThe input type of the OnlineStat(s) determines what a single observation is.  For a Mean, a single observation is a Real.  For OnlineStats such as CovMatrix, a single observation is an AbstractVector or NTuple.s = Series(Mean())\nfit!(s, randn())\n\ns = Series(CovMatrix(4))\nfit!(s, randn(4))\nfit!(s, randn(4))"
},

{
    "location": "pages/series.html#Single-observation,-override-weight-1",
    "page": "Series",
    "title": "Single observation, override weight",
    "category": "section",
    "text": "s = Series(Mean())\nfit!(s, randn(), .1)"
},

{
    "location": "pages/series.html#Multiple-observations-1",
    "page": "Series",
    "title": "Multiple observations",
    "category": "section",
    "text": "note: Note\nThe input type of the OnlineStat(s) determines what multiple observations are.  For a Mean, this would be an AbstractVector.  For a CovMatrix, this would be an AbstractMatrix.  By default, each row is considered an observation.  You can use column observations with ObsDim.Last() (see below).s = Series(Mean())\nfit!(s, randn(100))\n\ns = Series(CovMatrix(4))\nfit!(s, randn(100, 4))                 # Obs. in rows\nfit!(s, randn(4, 100), ObsDim.Last())  # Obs. in columns"
},

{
    "location": "pages/series.html#Multiple-observations,-use-the-same-weight-for-all-1",
    "page": "Series",
    "title": "Multiple observations, use the same weight for all",
    "category": "section",
    "text": "s = Series(Mean())\nfit!(s, randn(100), .01)"
},

{
    "location": "pages/series.html#Multiple-observations,-provide-vector-of-weights-1",
    "page": "Series",
    "title": "Multiple observations, provide vector of weights",
    "category": "section",
    "text": "s = Series(Mean())\nfit!(s, randn(100), rand(100))"
},

{
    "location": "pages/series.html#Merging-1",
    "page": "Series",
    "title": "Merging",
    "category": "section",
    "text": "Two Series can be merged if they track the same OnlineStats and those OnlineStats are mergeable.  The syntax for in-place merging ismerge!(series1, series2, arg)Where series1/series2 are Series that contain the same OnlineStats and arg is used to determine how series2 should be merged into series1.y1 = randn(100)\ny2 = randn(100)\n\ns1 = Series(y1, Mean(), Variance())\ns2 = Series(y2, Mean(), Variance())\n\n# Treat s2 as a new batch of data.  Essentially:\n# s1 = Series(Mean(), Variance()); fit!(s1, y1); fit!(s1, y2)\nmerge!(s1, s2, :append)\n\n# Use weighted average based on nobs of each Series\nmerge!(s1, s2, :mean)\n\n# Treat s2 as a single observation.\nmerge!(s1, s2, :singleton)\n\n# Provide the ratio of influence s2 should have.\nmerge!(s1, s2, .5)"
},

{
    "location": "pages/types.html#",
    "page": "What Can OnlineStats Do?",
    "title": "What Can OnlineStats Do?",
    "category": "page",
    "text": ""
},

{
    "location": "pages/types.html#What-Can-OnlineStats-Do?-1",
    "page": "What Can OnlineStats Do?",
    "title": "What Can OnlineStats Do?",
    "category": "section",
    "text": "Statistic/Model OnlineStat\nUnivariate Statistics: \nmean Mean\nvariance Variance\nquantiles via SGD QuantileSGD\nquantiles via Online MM QuantileMM\nmax and min Extrema\nskewness and kurtosis Moments\nsum Sum\ndifference Diff\nhistogram OHistogram\napproximate order statistics OrderStatistics\nMultivariate Analysis: \ncovariance matrix CovMatrix\nk-means clustering KMeans\nmultiple univariate statistics MV{<:OnlineStat}\nDensity Estimation: \nBeta FitBeta\nCategorical FitCategorical\nCauchy FitCauchy\nGamma FitGamma\nLogNormal FitLogNormal\nNormal FitNormal\nMultinomial FitMultinomial\nMvNormal FitMvNormal\nStatistical Learning: \nGLMs with regularization StatLearn\nLinear (also ridge) regression LinReg\nOther: \nBootstrapping Bootstrap\napproximate count of distinct elements HyperLogLog\nReservoir Sampling ReservoirSample"
},

{
    "location": "pages/api.html#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "pages/api.html#OnlineStats.Bootstrap",
    "page": "API",
    "title": "OnlineStats.Bootstrap",
    "category": "Type",
    "text": "Bootstrap(s::Series, nreps, d, f = value)\n\nOnline Statistical Bootstrapping.\n\nCreate nreps replicates of the OnlineStat in Series s.  When fit! is called, each of the replicates will be updated rand(d) times.  Standard choices for d are Distributions.Poisson(), [0, 2], etc.  value(b) returns f mapped to the replicates.\n\nExample\n\nb = Bootstrap(Series(Mean()), 100, [0, 2])\nfit!(b, randn(1000))\nvalue(b)        # `f` mapped to replicates\nmean(value(b))  # mean\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.Diff",
    "page": "API",
    "title": "OnlineStats.Diff",
    "category": "Type",
    "text": "Diff()\n\nTrack the difference and the last value.\n\nExample\n\ns = Series(randn(1000), Diff())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitCategorical",
    "page": "API",
    "title": "OnlineStats.FitCategorical",
    "category": "Type",
    "text": "FitCategorical(T)\n\nFit a categorical distribution where the inputs are of type T.\n\nExample\n\nusing Distributions\ns = Series(rand(1:10, 1000), FitCategorical(Int))\nvalue(s)\n\nvals = [\"small\", \"medium\", \"large\"]\ns = Series(rand(vals, 1000), FitCategorical(String))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.MV",
    "page": "API",
    "title": "OnlineStats.MV",
    "category": "Type",
    "text": "MV(p, o)\n\nTrack p univariate OnlineStats o\n\nExample\n\ny = randn(1000, 5)\no = MV(5, Mean())\ns = Series(y, o)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.OHistogram",
    "page": "API",
    "title": "OnlineStats.OHistogram",
    "category": "Type",
    "text": "OHistogram(range)\n\nMake a histogram with bins given by range.  Uses left-closed bins.\n\nExample\n\ny = randn(100)\ns = Series(y, OHistogram(-4:.1:4))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.ReservoirSample",
    "page": "API",
    "title": "OnlineStats.ReservoirSample",
    "category": "Type",
    "text": "ReservoirSample(k)\nReservoirSample(k, Float64)\n\nReservoir sample of k items.\n\nExample\n\no = ReservoirSample(k, Int)\ns = Series(o)\nfit!(s, 1:10000)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.Series",
    "page": "API",
    "title": "OnlineStats.Series",
    "category": "Type",
    "text": "Series(stats...)\nSeries(data, stats...)\nSeries(weight, stats...)\nSeries(weight, data, stats...)\n\nA Series is a container for a Weight and any number of OnlineStats.  Updating the Series with fit!(s, data) will update the OnlineStats it holds according to its Weight.\n\nExamples\n\nSeries(randn(100), Mean(), Variance())\nSeries(ExponentialWeight(.1), Mean())\n\ns = Series(Mean())\nfit!(s, randn(100))\ns2 = Series(randn(123), Mean())\nmerge(s, s2)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.StatLearn",
    "page": "API",
    "title": "OnlineStats.StatLearn",
    "category": "Type",
    "text": "StatLearn(p, loss, penalty, λ, updater)\n\nFit a statistical learning model of p independent variables for a given loss, penalty, and λ.  Arguments are:\n\nloss: any Loss from LossFunctions.jl\npenalty: any Penalty from PenaltyFunctions.jl.\nλ: a Vector of element-wise regularization parameters\nupdater: SPGD(), ADAGRAD(), ADAM(), or ADAMAX()\n\nExample\n\nusing LossFunctions, PenaltyFunctions\nx = randn(100_000, 10)\ny = x * linspace(-1, 1, 10) + randn(100_000)\no = StatLearn(10, L2DistLoss(), L1Penalty(), fill(.1, 10), SPGD())\ns = Series(o)\nfit!(s, x, y)\ncoef(o)\npredict(o, x)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.StochasticLoss",
    "page": "API",
    "title": "OnlineStats.StochasticLoss",
    "category": "Type",
    "text": "    s = Series(randn(1000), StochasticLoss(QuantileLoss(.7)))\n\nMinimize a loss (from LossFunctions.jl) using stochastic gradient descent.\n\nExample\n\no1 = StochasticLoss(QuantileLoss(.7))  # approx. .7 quantile\no2 = StochasticLoss(L2DistLoss())      # approx. mean\no3 = StochasticLoss(L1DistLoss())      # approx. median\ns = Series(randn(10_000), o1, o2, o3)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.Sum",
    "page": "API",
    "title": "OnlineStats.Sum",
    "category": "Type",
    "text": "Sum()\n\nTrack the overall sum.\n\nExample\n\ns = Series(randn(1000), Sum())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.ADAGRAD",
    "page": "API",
    "title": "OnlineStats.ADAGRAD",
    "category": "Type",
    "text": "ADAGRAD(η)\n\nAdaptive (element-wise learning rate) SPGD with step size η\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.ADAM",
    "page": "API",
    "title": "OnlineStats.ADAM",
    "category": "Type",
    "text": "ADAM(α1, α2, η)\n\nAdaptive Moment Estimation with step size η and momentum parameters α1, α2\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.ADAMAX",
    "page": "API",
    "title": "OnlineStats.ADAMAX",
    "category": "Type",
    "text": "ADAMAX(α1, α2, η)\n\nADAMAX with step size η and momentum parameters α1, α2\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.CovMatrix",
    "page": "API",
    "title": "OnlineStats.CovMatrix",
    "category": "Type",
    "text": "CovMatrix(d)\n\nCovariance Matrix of d variables.\n\nExample\n\ny = randn(100, 5)\nSeries(y, CovMatrix(5))\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.Extrema",
    "page": "API",
    "title": "OnlineStats.Extrema",
    "category": "Type",
    "text": "Extrema()\n\nMaximum and minimum.\n\nExample\n\ns = Series(randn(100), Extrema())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitBeta",
    "page": "API",
    "title": "OnlineStats.FitBeta",
    "category": "Type",
    "text": "FitBeta()\n\nOnline parameter estimate of a Beta distribution (Method of Moments)\n\nExample\n\nusing Distributions, OnlineStats\ny = rand(Beta(3, 5), 1000)\ns = Series(y, FitBeta())\nBeta(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitCauchy",
    "page": "API",
    "title": "OnlineStats.FitCauchy",
    "category": "Type",
    "text": "FitCauchy()\n\nOnline parameter estimate of a Cauchy distribution\n\nExample\n\nusing Distributions\ny = rand(Cauchy(0, 10), 10_000)\ns = Series(y, FitCauchy())\nCauchy(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitGamma",
    "page": "API",
    "title": "OnlineStats.FitGamma",
    "category": "Type",
    "text": "FitGamma()\n\nOnline parameter estimate of a Gamma distribution (Method of Moments)\n\nExample\n\nusing Distributions\ny = rand(Gamma(5, 1), 1000)\ns = Series(y, FitGamma())\nGamma(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitLogNormal",
    "page": "API",
    "title": "OnlineStats.FitLogNormal",
    "category": "Type",
    "text": "FitLogNormal()\n\nOnline parameter estimate of a LogNormal distribution (MLE)\n\nExample\n\nusing Distributions\ny = rand(LogNormal(3, 4), 1000)\ns = Series(y, FitLogNormal())\nLogNormal(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitMultinomial",
    "page": "API",
    "title": "OnlineStats.FitMultinomial",
    "category": "Type",
    "text": "FitMultinomial(p)\n\nOnline parameter estimate of a Multinomial distribution.\n\nExample\n\nusing Distributions\ny = rand(Multinomial(10, [.2, .2, .6]), 1000)\ns = Series(y', FitMultinomial())\nMultinomial(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitMvNormal",
    "page": "API",
    "title": "OnlineStats.FitMvNormal",
    "category": "Type",
    "text": "FitMvNormal(d)\n\nOnline parameter estimate of a d-dimensional MvNormal distribution (MLE)\n\nExample\n\nusing Distributions\ny = rand(MvNormal(zeros(3), eye(3)), 1000)\ns = Series(y', FitMvNormal(3))\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitNormal",
    "page": "API",
    "title": "OnlineStats.FitNormal",
    "category": "Type",
    "text": "FitNormal()\n\nOnline parameter estimate of a Normal distribution (MLE)\n\nExample\n\nusing Distributions\ny = rand(Normal(-3, 4), 1000)\ns = Series(y, FitNormal())\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.HyperLogLog",
    "page": "API",
    "title": "OnlineStats.HyperLogLog",
    "category": "Type",
    "text": "HyperLogLog(b)  # 4 ≤ b ≤ 16\n\nApproximate count of distinct elements.\n\nExample\n\ns = Series(rand(1:10, 1000), HyperLogLog(12))\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.KMeans",
    "page": "API",
    "title": "OnlineStats.KMeans",
    "category": "Type",
    "text": "KMeans(p, k)\n\nApproximate K-Means clustering of k clusters of p variables\n\nExample\n\nusing OnlineStats, Distributions\nd = MixtureModel([Normal(0), Normal(5)])\ny = rand(d, 100_000, 1)\ns = Series(y, LearningRate(.6), KMeans(1, 2))\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.LinReg",
    "page": "API",
    "title": "OnlineStats.LinReg",
    "category": "Type",
    "text": "LinReg(p)\nLinReg(p, λ)\n\nCreate a linear regression object with p predictors and optional ridge (L2-regularization) parameter λ.\n\nExample\n\nx = randn(1000, 5)\ny = x * linspace(-1, 1, 5) + randn(1000)\no = LinReg(5)\ns = Series(o)\nfit!(s, x, y)\ncoef(o)\npredict(o, x)\ncoeftable(o)\nvcov(o)\nconfint(o)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.MAXSPGD",
    "page": "API",
    "title": "OnlineStats.MAXSPGD",
    "category": "Type",
    "text": "MAXSPGD(η)\n\nSPGD where only the largest gradient element is used to update the parameter.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.MSPIC",
    "page": "API",
    "title": "OnlineStats.MSPIC",
    "category": "Type",
    "text": "Experimental: MSPI-constant\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.MSPIF",
    "page": "API",
    "title": "OnlineStats.MSPIF",
    "category": "Type",
    "text": "Experimental: MSPI-full matrix\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.Mean",
    "page": "API",
    "title": "OnlineStats.Mean",
    "category": "Type",
    "text": "Mean()\n\nUnivariate mean.\n\nExample\n\ns = Series(randn(100), Mean())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.Moments",
    "page": "API",
    "title": "OnlineStats.Moments",
    "category": "Type",
    "text": "Moments()\n\nFirst four non-central moments.\n\nExample\n\ns = Series(randn(1000), Moments(10))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.OMMC",
    "page": "API",
    "title": "OnlineStats.OMMC",
    "category": "Type",
    "text": "Experimental: OMM-constant\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.OMMF",
    "page": "API",
    "title": "OnlineStats.OMMF",
    "category": "Type",
    "text": "Experimental: OMM-full matrix\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.OrderStats",
    "page": "API",
    "title": "OnlineStats.OrderStats",
    "category": "Type",
    "text": "OrderStats(b)\n\nAverage order statistics with batches of size b.\n\nExample\n\ns = Series(randn(1000), OrderStats(10))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.QuantileISGD",
    "page": "API",
    "title": "OnlineStats.QuantileISGD",
    "category": "Type",
    "text": "QuantileISGD()\n\nApproximate quantiles via implicit stochastic gradient descent.\n\nExample\n\ns = Series(randn(1000), LearningRate(.7), QuantileISGD())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.QuantileMM",
    "page": "API",
    "title": "OnlineStats.QuantileMM",
    "category": "Type",
    "text": "QuantileMM()\n\nApproximate quantiles via an online MM algorithm.\n\nExample\n\ns = Series(randn(1000), LearningRate(.7), QuantileMM())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.QuantileSGD",
    "page": "API",
    "title": "OnlineStats.QuantileSGD",
    "category": "Type",
    "text": "QuantileSGD()\n\nApproximate quantiles via stochastic gradient descent.\n\nExample\n\ns = Series(randn(1000), LearningRate(.7), QuantileSGD())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.SPGD",
    "page": "API",
    "title": "OnlineStats.SPGD",
    "category": "Type",
    "text": "SPGD(η)\n\nStochastic Proximal Gradient Descent with step size η\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.SPI",
    "page": "API",
    "title": "OnlineStats.SPI",
    "category": "Type",
    "text": "Stochastic Proximal Iteration\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.Variance",
    "page": "API",
    "title": "OnlineStats.Variance",
    "category": "Type",
    "text": "Variance()\n\nUnivariate variance.\n\nExample\n\ns = Series(randn(100), Variance())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#LearnBase.value-Tuple{OnlineStats.Series}",
    "page": "API",
    "title": "LearnBase.value",
    "category": "Method",
    "text": "Map value to the stats field of a Series.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.maprows-Tuple{Function,Integer,Vararg{Any,N} where N}",
    "page": "API",
    "title": "OnlineStats.maprows",
    "category": "Method",
    "text": "maprows(f::Function, b::Integer, data...)\n\nMap rows of data in batches of size b.  Most usage is done through do blocks.\n\nExample\n\ns = Series(Mean())\nmaprows(10, randn(100)) do yi\n    fit!(s, yi)\n    info(\"nobs: $(nobs(s))\")\nend\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.replicates-Tuple{OnlineStats.Bootstrap}",
    "page": "API",
    "title": "OnlineStats.replicates",
    "category": "Method",
    "text": "replicates(b)\n\nReturn the vector of replicates from Bootstrap b\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.stats-Tuple{OnlineStats.Series}",
    "page": "API",
    "title": "OnlineStats.stats",
    "category": "Method",
    "text": "Return the stats field of a Series.\n\n\n\n"
},

{
    "location": "pages/api.html#StatsBase.confint",
    "page": "API",
    "title": "StatsBase.confint",
    "category": "Function",
    "text": "confint(b, coverageprob = .95)\n\nReturn a confidence interval for a Bootstrap b.\n\n\n\n"
},

{
    "location": "pages/api.html#StatsBase.fit!",
    "page": "API",
    "title": "StatsBase.fit!",
    "category": "Function",
    "text": "fit!(s, y)\nfit!(s, y, w)\n\nUpdate a Series s with more data y and optional weighting w.\n\nExamples\n\ny = randn(100)\nw = rand(100)\n\ns = Series(Mean())\nfit!(s, y[1])        # one observation: use Series weight\nfit!(s, y[1], w[1])  # one observation: override weight\nfit!(s, y)           # multiple observations: use Series weight\nfit!(s, y, w[1])     # multiple observations: override each weight with w[1]\nfit!(s, y, w)        # multiple observations: y[i] uses weight w[i]\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.AbstractSeries",
    "page": "API",
    "title": "OnlineStatsBase.AbstractSeries",
    "category": "Type",
    "text": "A container for a Weight and at least one OnlineStat\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.EqualWeight",
    "page": "API",
    "title": "OnlineStatsBase.EqualWeight",
    "category": "Type",
    "text": "EqualWeight()\n\nEqually weighted observations\nWeight at observation t is γ = 1 / t\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.ExponentialWeight",
    "page": "API",
    "title": "OnlineStatsBase.ExponentialWeight",
    "category": "Type",
    "text": "ExponentialWeight(λ::Real = 0.1)\nExponentialWeight(lookback::Integer)\n\nExponentially weighted observations (constant)\nWeight at observation t is γ = λ\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.HarmonicWeight",
    "page": "API",
    "title": "OnlineStatsBase.HarmonicWeight",
    "category": "Type",
    "text": "HarmonicWeight(a = 10.0)\n\nDecreases at a slow rate\nWeight at observation t is γ = a / (a + t - 1)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.LearningRate",
    "page": "API",
    "title": "OnlineStatsBase.LearningRate",
    "category": "Type",
    "text": "LearningRate(r = .6)\n\nMainly for stochastic approximation types (QuantileSGD, QuantileMM etc.)\nDecreases at a \"slow\" rate\nWeight at observation t is γ = 1 / t ^ r\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.LearningRate2",
    "page": "API",
    "title": "OnlineStatsBase.LearningRate2",
    "category": "Type",
    "text": "LearningRate2(c = .5)\n\nMainly for stochastic approximation types (QuantileSGD, QuantileMM etc.)\nDecreases at a \"slow\" rate\nWeight at observation t is γ = inv(1 + c * (t - 1))\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.McclainWeight",
    "page": "API",
    "title": "OnlineStatsBase.McclainWeight",
    "category": "Type",
    "text": "McclainWeight(ᾱ = 0.1)\n\n\"smoothed\" version of BoundedEqualWeight\nweights asymptotically approach ᾱ\nWeight at observation t is γ(t-1) / (1 + γ(t-1) - ᾱ)\n\n\n\n"
},

{
    "location": "pages/api.html#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": "Modules = [OnlineStats, OnlineStatsBase]"
},

{
    "location": "pages/newstats.html#",
    "page": "Extending OnlineStats",
    "title": "Extending OnlineStats",
    "category": "page",
    "text": ""
},

{
    "location": "pages/newstats.html#Extending-OnlineStats-1",
    "page": "Extending OnlineStats",
    "title": "Extending OnlineStats",
    "category": "section",
    "text": "Creating new OnlineStat types should be accomplished through OnlineStatsBase.jl, a zero-dependency package which defines the interface an OnlineStat uses."
},

]}
