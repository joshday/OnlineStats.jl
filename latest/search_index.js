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
    "text": "y = randn(100)\n\nfor yi in y\n    fit!(s, yi)\nend\n\n# or more simply:\nfit!(s, y)<img width = 200 src = \"https://user-images.githubusercontent.com/8075494/32734476-260821d0-c860-11e7-8c91-49ba0b86397a.gif\">"
},

{
    "location": "weights.html#",
    "page": "Weighting",
    "title": "Weighting",
    "category": "page",
    "text": ""
},

{
    "location": "weights.html#Weighting-1",
    "page": "Weighting",
    "title": "Weighting",
    "category": "section",
    "text": "Series are parameterized by a Weight type that controls the influence of the next observation.Consider how weights affect the influence of the next observation on an online mean theta^(t), as many OnlineStats use updates of this form.  A larger weight  gamma_t puts higher influence on the new observation x_t:theta^(t) = (1-gamma_t)theta^(t-1) + gamma_t x_tnote: Note\nThe values produced by a weight must follow two rules:gamma_1 = 1\nThis guarantees theta^(1) = x_1\ngamma_t in (0 1) quad forall t  1\nThis guarantees theta^(t) stays inside a convex space<br>\n<img src=\"https://user-images.githubusercontent.com/8075494/29486708-a52b9de6-84ba-11e7-86c5-debfc5a80cca.png\" height=300>"
},

{
    "location": "weights.html#[EqualWeight()](@ref)-1",
    "page": "Weighting",
    "title": "EqualWeight()",
    "category": "section",
    "text": "Each observation has an equal amount of influence.gamma_t = frac1t"
},

{
    "location": "weights.html#[ExponentialWeight(λ-0.1)](@ref)-1",
    "page": "Weighting",
    "title": "ExponentialWeight(λ = 0.1)",
    "category": "section",
    "text": "Each observation is weighted with a constant, giving newer observations higher influence.gamma_t = lambda"
},

{
    "location": "weights.html#[LearningRate(r-0.6)](@ref)-1",
    "page": "Weighting",
    "title": "LearningRate(r = 0.6)",
    "category": "section",
    "text": "Decrease at a slow rate.gamma_t = frac1t^r"
},

{
    "location": "weights.html#[HarmonicWeight(a-10.0)](@ref)-1",
    "page": "Weighting",
    "title": "HarmonicWeight(a = 10.0)",
    "category": "section",
    "text": "Decrease at a slow rate.gamma_t = fracaa + t - 1"
},

{
    "location": "weights.html#[McclainWeight(a-0.1)](@ref)-1",
    "page": "Weighting",
    "title": "McclainWeight(a = 0.1)",
    "category": "section",
    "text": "Smoothed version of Bounded{EqualWeight}.  Weight approaches a in the limit.gamma_t = fracgamma_t-11 + gamma_t-1 - a"
},

{
    "location": "weights.html#[Bounded(weight,-λ)](@ref)-1",
    "page": "Weighting",
    "title": "Bounded(weight, λ)",
    "category": "section",
    "text": "Wrapper for a weight which provides a minimum bound.gamma_t = textmax(gamma_t )"
},

{
    "location": "weights.html#[Scaled(weight,-λ)](@ref)-1",
    "page": "Weighting",
    "title": "Scaled(weight, λ)",
    "category": "section",
    "text": "Wrapper for a weight which scales the weight by a constant.  This is only meant for use with subtypes of StochasticStat, as it violates the rule gamma_1 = 1.gamma_t =  * gamma_t"
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
    "text": "The Series type is the workhorse of OnlineStats.  A Series tracksThe Weight\nA tuple of OnlineStats."
},

{
    "location": "series.html#Creating-1",
    "page": "Series",
    "title": "Creating",
    "category": "section",
    "text": ""
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
    "text": "A Series can be updated with a single observation or a collection of observations.  The most common way to update a series is with:fit!(series, data)"
},

{
    "location": "series.html#Under-the-hood-1",
    "page": "Series",
    "title": "Under the hood",
    "category": "section",
    "text": "Each OnlineStat implements fit!(o::OnlineStat, data, w::Float64) where w is a weight in 0 1 which controls the amount of influence data has on o.  When fit!(series, data) is called, w is created by the Weight and passed to fit! for each of the OnlineStats in the Series.  See Extending OnlineStats for more details."
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
    "text": "note: Note\nIf a single observation is a Vector, a Matrix is ambiguous in how the observations are stored.  A Rows() (default) or Cols() argument can be added to the fit! call to specify observations are in rows or columns, respectively.s = Series(Mean())\nfit!(s, randn(100))\n\ns = Series(CovMatrix(4))\nfit!(s, randn(100, 4))          # Obs. in rows\nfit!(s, randn(4, 100), Cols())  # Obs. in columns"
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
    "text": "Two Series can be merged if they track the same OnlineStats and those OnlineStats are mergeable.merge(series1, series2, arg)\nmerge!(series1, series2, arg)Where series1/series2 are Series that contain the same OnlineStats and arg is used to determine how series2 should be merged into series1.y1 = randn(100)\ny2 = randn(100)\n\ns1 = Series(y1, Mean(), Variance())\ns2 = Series(y2, Mean(), Variance())\n\n# Treat s2 as a new batch of data.  Essentially:\n# s1 = Series(Mean(), Variance()); fit!(s1, y1); fit!(s1, y2)\nmerge!(s1, s2, :append)\n\n# Use weighted average based on nobs of each Series\nmerge!(s1, s2, :mean)\n\n# Treat s2 as a single observation.\nmerge!(s1, s2, :singleton)\n\n# Provide the ratio of influence s2 should have.\nmerge!(s1, s2, .5)"
},

{
    "location": "whatcan.html#",
    "page": "What Can OnlineStats Do?",
    "title": "What Can OnlineStats Do?",
    "category": "page",
    "text": ""
},

{
    "location": "whatcan.html#What-Can-OnlineStats-Do?-1",
    "page": "What Can OnlineStats Do?",
    "title": "What Can OnlineStats Do?",
    "category": "section",
    "text": "Statistic/Model OnlineStat\nUnivariate Statistics: \nMean Mean\nVariance Variance\nQuantiles QuantileMM, QuantileMSPI, QuantileSGD\nMaximum/Minimum Extrema\nSkewness and kurtosis Moments\nSum Sum\nDifference Diff\nMultivariate Analysis: \nCovariance/correlation matrix CovMatrix\nPrincipal components analysis CovMatrix\nK-means clustering (SGD) KMeans\nMultiple univariate statistics MV{<:OnlineStat}\nNonparametric Density Estimation: \nHistograms OHistogram, IHistogram\nApproximate order statistics OrderStats\nParametric Density Estimation: \nBeta FitBeta\nCategorical FitCategorical\nCauchy FitCauchy\nGamma FitGamma\nLogNormal FitLogNormal\nNormal FitNormal\nMultinomial FitMultinomial\nMvNormal FitMvNormal\nStatistical Learning: \nGLMs with regularization StatLearn\nLogistic regression StatLearn\nLinear SVMs StatLearn\nQuantile regression StatLearn\nAbsolute loss regression StatLearn\nDistance-weighted discrimination StatLearn\nHuber-loss regression StatLearn\nLinear (also ridge) regression LinReg, LinRegBuilder\nOther: \nBootstrapping Bootstrap\nApprox. count of distinct elements HyperLogLog\nReservoir sampling ReservoirSample\nCallbacks CallFun, mapblocks"
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
    "text": "ADAGRAD()\n\nAdaptive (element-wise learning rate) stochastic proximal gradient descent.\n\n\n\n"
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
    "location": "api.html#OnlineStats.FitCategorical",
    "page": "API",
    "title": "OnlineStats.FitCategorical",
    "category": "Type",
    "text": "FitCategorical(T)\n\nFit a categorical distribution where the inputs are of type T.\n\nusing Distributions\ns = Series(rand(1:10, 1000), FitCategorical(Int))\nvalue(s)\n\nvals = [\"small\", \"medium\", \"large\"]\no = FitCategorical(String)\ns = Series(rand(vals, 1000), o)\nvalue(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitCauchy",
    "page": "API",
    "title": "OnlineStats.FitCauchy",
    "category": "Type",
    "text": "FitCauchy()\n\nOnline parameter estimate of a Cauchy distribution.\n\nusing Distributions\ny = rand(Cauchy(0, 10), 10_000)\no = FitCauchy()\ns = Series(y, o)\nCauchy(value(o)...)\n\n\n\n"
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
    "location": "api.html#OnlineStats.HyperLogLog",
    "page": "API",
    "title": "OnlineStats.HyperLogLog",
    "category": "Type",
    "text": "HyperLogLog(b)  # 4 ≤ b ≤ 16\n\nApproximate count of distinct elements.\n\nExample\n\ns = Series(rand(1:10, 1000), HyperLogLog(12))\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.IHistogram",
    "page": "API",
    "title": "OnlineStats.IHistogram",
    "category": "Type",
    "text": "IHistogram(b)\n\nIncrementally build a histogram of b (not equally spaced) bins.  An IHistogram can be used as a \"surrogate\" for a dataset to get approximate summary statistics.\n\nExample\n\no = IHistogram(50)\nSeries(randn(1000), o)\n\n# approximate summary stats\nquantile(o)\nmean(o)\nvar(o)\nstd(o)\nextrema(o)\nmedian(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.KMeans",
    "page": "API",
    "title": "OnlineStats.KMeans",
    "category": "Type",
    "text": "KMeans(p, k)\n\nApproximate K-Means clustering of k clusters and p variables.\n\nExample\n\nusing OnlineStats, Distributions\nd = MixtureModel([Normal(0), Normal(5)])\ny = rand(d, 100_000, 1)\ns = Series(y, LearningRate(.6), KMeans(1, 2))\n\n\n\n"
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
    "text": "LinRegBuilder(p)\n\nCreate an object from which any variable can be regressed on any other set of variables.\n\nExample\n\nx = randn(1000, 10)\no = LinRegBuilder(10)\ns = Series(x, o)\n\n# let response = x[:, 3], predictors = x[:, setdiff(1:10, 3)]\ncoef(o, 3) \n\n# let response = x[:, 7], predictors = x[:, [2, 5, 4]]\ncoef(o, 7, [2, 5, 4])\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MSPIQ",
    "page": "API",
    "title": "OnlineStats.MSPIQ",
    "category": "Type",
    "text": "MSPIQ()\n\nMSPI-Q (Proximal mapping applied to majorization) algorithm using a Lipschitz constant to  majorize the objective.  \n\n\n\n"
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
    "location": "api.html#OnlineStats.NSGD",
    "page": "API",
    "title": "OnlineStats.NSGD",
    "category": "Type",
    "text": "NSGD(α)\n\nNesterov accelerated Proximal Stochastic Gradient Descent.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OHistogram",
    "page": "API",
    "title": "OnlineStats.OHistogram",
    "category": "Type",
    "text": "OHistogram(range)\n\nMake a histogram with bins given by range.  Uses left-closed bins.  OHistogram fits faster than IHistogram, but has the disadvantage of requiring specification of bins before data is observed.\n\nExample\n\ny = randn(100)\no = OHistogram(-5:.01:5)\ns = Series(y, o)\n\nvalue(o)  # return StatsBase.Histogram\nquantile(o)\nmean(o)\nvar(o)\nstd(o)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMASQ",
    "page": "API",
    "title": "OnlineStats.OMASQ",
    "category": "Type",
    "text": "Experimental: OMM-constant\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OrderStats",
    "page": "API",
    "title": "OnlineStats.OrderStats",
    "category": "Type",
    "text": "OrderStats(b)\n\nAverage order statistics with batches of size b.  Ignores weight.\n\nExample\n\ns = Series(randn(1000), OrderStats(10))\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.QuantileMM",
    "page": "API",
    "title": "OnlineStats.QuantileMM",
    "category": "Type",
    "text": "QuantileMM(q = [.25, .5, .75])\n\nApproximate quantiles via an online MM algorithm (OMAS).\n\nExample\n\ns = Series(randn(1000), QuantileMM())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.QuantileMSPI",
    "page": "API",
    "title": "OnlineStats.QuantileMSPI",
    "category": "Type",
    "text": "QuantileMSPI(q = [.25, .5, .75])\n\nApproximate quantiles via Majorized Stochastic Proximal Iteration (MSPI).\n\nExample\n\ns = Series(randn(1000), QuantileMSPI())\nvalue(s)\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.QuantileSGD",
    "page": "API",
    "title": "OnlineStats.QuantileSGD",
    "category": "Type",
    "text": "QuantileSGD(q = [.25, .5, .75])\n\nApproximate quantiles via an stochastic subgradient descent.\n\nExample\n\ns = Series(randn(1000), QuantileSGD())\nvalue(s)\n\n\n\n"
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
    "text": "SGD()\n\nProximal Stochastic Gradient Descent.\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Series",
    "page": "API",
    "title": "OnlineStats.Series",
    "category": "Type",
    "text": "Series(stats...)\nSeries(weight, stats...)\nSeries(data, weight, stats...)\nSeries(data, stats...)\nSeries(weight, data, stats...)\n\nTrack any number of OnlineStats.\n\nExample\n\nSeries(Mean())\nSeries(randn(100), Mean())\nSeries(randn(100), Weight.Exponential(), Mean())\n\ns = Series(QuantileMM([.25, .5, .75]))\nfit!(s, randn(1000))\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.StatLearn",
    "page": "API",
    "title": "OnlineStats.StatLearn",
    "category": "Type",
    "text": "StatLearn(p::Int, args...)\n\nFit a statistical learning model of p independent variables for a given loss, penalty, and λ.  Additional arguments can be given in any order (and is still type stable):\n\nloss = .5 * L2DistLoss(): any Loss from LossFunctions.jl\npenalty = L2Penalty(): any Penalty (which has a prox method) from PenaltyFunctions.jl.\nλ = fill(.1, p): a Vector of element-wise regularization parameters\nupdater = SGD(): SGD, ADAGRAD, ADAM, ADAMAX, MSPIQ\n\nDetails\n\nThe (offline) objective function which StatLearn approximately minimizes is\n\nfrac1nsum_i=1^n f_i(beta) + sum_j=1^p lambda_j g(beta_j)\n\nwhere the f_i's are loss functions evaluated on a single observation, g is a penalty function, and the lambda_js are nonnegative regularization parameters.\n\nExample\n\nusing LossFunctions, PenaltyFunctions\nx = randn(100_000, 10)\ny = x * linspace(-1, 1, 10) + randn(100_000)\no = StatLearn(10, .5 * L2DistLoss(), L1Penalty(), fill(.1, 10), SGD())\ns = Series(o)\nfit!(s, x, y)\ncoef(o)\npredict(o, x)\n\n\n\n"
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
    "location": "api.html#Base.merge!-Union{Tuple{T,T,Symbol}, Tuple{T,T}, Tuple{T}} where T<:OnlineStats.Series",
    "page": "API",
    "title": "Base.merge!",
    "category": "Method",
    "text": "merge!(s1::Series, s2::Series, arg)\n\nMerge s2 into s1 in place where s2's influence is determined by arg. Options for arg` are:\n\n:append (default)\nappend s2 to s1.  Essentially fit!(s1, data_which_s2_saw).\n:mean\nUse the average of the Series' generated weights.\n:singleton\ntreat s2 as a single observation.\nany Float64 in [0, 1]\n\n\n\n"
},

{
    "location": "api.html#Base.merge-Union{Tuple{T,T,Float64}, Tuple{T}} where T<:OnlineStats.Series",
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
    "text": "An OnlineStat which can be updated exactly.\n\n\n\n"
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
    "text": "An OnlineStat which must be updated approximately.\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase.Weight",
    "page": "API",
    "title": "OnlineStatsBase.Weight",
    "category": "Type",
    "text": "Weight is an abstract type.  Subtypes must be callable have a method to produce the weight given the current number of observations in an OnlineStat n and the number of  observations included in the update (n2).\n\nMyWeight(n, n2 = 1)\n\n\n\n"
},

{
    "location": "api.html#OnlineStatsBase._value-Tuple{OnlineStatsBase.OnlineStat}",
    "page": "API",
    "title": "OnlineStatsBase._value",
    "category": "Method",
    "text": "value(o::OnlineStat)\n\nReturn the value of the OnlineStat.\n\n\n\n"
},

{
    "location": "api.html#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": "Modules = [OnlineStats, OnlineStatsBase]"
},

{
    "location": "newstats.html#",
    "page": "Extending OnlineStats",
    "title": "Extending OnlineStats",
    "category": "page",
    "text": ""
},

{
    "location": "newstats.html#Extending-OnlineStats-1",
    "page": "Extending OnlineStats",
    "title": "Extending OnlineStats",
    "category": "section",
    "text": "New OnlineStats which work with the Series/Weight interface can be accomplished through the zero-dependency OnlineStatsBase.jl"
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
    "text": "Two Series can be merged if they track the same OnlineStats.  This facilitates embarassingly parallel computations.  In general, fit! is a cheaper operation than merge! and should be preferred."
},

{
    "location": "parallel.html#ExactStat-merges-1",
    "page": "Parallel Computation",
    "title": "ExactStat merges",
    "category": "section",
    "text": "Many OnlineStats are subtypes of ExactStat, meaning the value of interest can be calculated exactly (compared to the appropriate offline algorithm).  For these OnlineStats, the order of fit!-ting and merge!-ing does not matter.  See subtypes(OnlineStats.ExactStat) for a full list.# NOTE: This code is not actually running in parallel\ny1 = randn(10_000)\ny2 = randn(10_000)\ny3 = randn(10_000)\n\ns1 = Series(Mean(), Variance(), IHistogram(50))\ns2 = Series(Mean(), Variance(), IHistogram(50))\ns3 = Series(Mean(), Variance(), IHistogram(50))\n\nfit!(s1, y1)\nfit!(s1, y2)\nfit!(s2, y3)\n\nmerge!(s1, s2)  # merge information from s2 into s1\nmerge!(s1, s3)  # merge information from s3 into s1(Image: )"
},

{
    "location": "parallel.html#Other-Merges-1",
    "page": "Parallel Computation",
    "title": "Other Merges",
    "category": "section",
    "text": "For OnlineStats which rely on approximations, merging isn't always a well-defined operation. A printed warning will occur for these cases.  Please open an issue to discuss merging an OnlineStat if merging fails but you believe it should be merge-able."
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
    "text": "Some OnlineStats are especially useful for out-of-core computations, as after they have run through the data, they can be used as a surrogate for the entire dataset for calculating approximate summary statistics or exact linear models."
},

{
    "location": "datasurrogates.html#IHistogram-1",
    "page": "Data Surrogates",
    "title": "IHistogram",
    "category": "section",
    "text": "IHistogram incrementally builds a histogram of unequally spaced bins.  It has a  Plots.jl recipe and can be used to get  approximate summary statistics, without the need to run through the data again.o = IHistogram(100)\ns = Series(o)\n\nfit!(s, randexp(100_000))\n\nquantile(o, .5)\nquantile(o, [.2, .8])\nmean(o)\nvar(o)\nstd(o)\n\nplot(o)(Image: )"
},

{
    "location": "datasurrogates.html#LinRegBuilder-1",
    "page": "Data Surrogates",
    "title": "LinRegBuilder",
    "category": "section",
    "text": "TODO"
},

]}
