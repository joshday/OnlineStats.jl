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
    "text": "Decrease at a slow rate.gamma_t = frac1t^r"
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
    "location": "pages/weights.html#[Scaled(weight,-λ)](@ref)-1",
    "page": "Weighting",
    "title": "Scaled(weight, λ)",
    "category": "section",
    "text": "Wrapper for a weight which scales the weight by a constant.  This is only meant for use with stochastic gradient algorithms.gamma_t =  * gamma_t"
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
    "text": "Statistic/Model OnlineStat\nUnivariate Statistics: \nmean Mean\nvariance Variance\nquantiles QuantileMM, QuantileMSPI, QuantileSGD\nmax and min Extrema\nskewness and kurtosis Moments\nsum Sum\ndifference Diff\nhistogram OHistogram\napproximate order statistics OrderStats\nMultivariate Analysis: \ncovariance matrix CovMatrix\nk-means clustering KMeans\nmultiple univariate statistics MV{<:OnlineStat}\nDensity Estimation: \nBeta FitBeta\nCategorical FitCategorical\nCauchy FitCauchy\nGamma FitGamma\nLogNormal FitLogNormal\nNormal FitNormal\nMultinomial FitMultinomial\nMvNormal FitMvNormal\nStatistical Learning: \nGLMs with regularization StatLearn\nLinear (also ridge) regression LinReg\nOther: \nBootstrapping Bootstrap\napprox. count of distinct elements HyperLogLog\nReservoir Sampling ReservoirSample"
},

{
    "location": "pages/api.html#",
    "page": "API",
    "title": "API",
    "category": "page",
    "text": ""
},

{
    "location": "pages/api.html#OnlineStats.ADADELTA",
    "page": "API",
    "title": "OnlineStats.ADADELTA",
    "category": "Type",
    "text": "ADADELTA(ρ = .95)\n\nADADELTA ignores weight.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.ADAGRAD",
    "page": "API",
    "title": "OnlineStats.ADAGRAD",
    "category": "Type",
    "text": "ADAGRAD()\n\nAdaptive (element-wise learning rate) stochastic proximal gradient descent.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.ADAM",
    "page": "API",
    "title": "OnlineStats.ADAM",
    "category": "Type",
    "text": "ADAM(α1, α2)\n\nAdaptive Moment Estimation with momentum parameters α1 and α2.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.ADAMAX",
    "page": "API",
    "title": "OnlineStats.ADAMAX",
    "category": "Type",
    "text": "ADAMAX(η, β1, β2)\n\nADAMAX with step size η and momentum parameters β1, β2\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitBeta",
    "page": "API",
    "title": "OnlineStats.FitBeta",
    "category": "Type",
    "text": "FitBeta()\n\nOnline parameter estimate of a Beta distribution (Method of Moments).\n\nusing Distributions, OnlineStats\ny = rand(Beta(3, 5), 1000)\ns = Series(y, FitBeta())\nBeta(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitCategorical",
    "page": "API",
    "title": "OnlineStats.FitCategorical",
    "category": "Type",
    "text": "FitCategorical(T)\n\nFit a categorical distribution where the inputs are of type T.\n\nusing Distributions\ns = Series(rand(1:10, 1000), FitCategorical(Int))\nvalue(s)\n\nvals = [\"small\", \"medium\", \"large\"]\ns = Series(rand(vals, 1000), FitCategorical(String))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitCauchy",
    "page": "API",
    "title": "OnlineStats.FitCauchy",
    "category": "Type",
    "text": "FitCauchy()\n\nOnline parameter estimate of a Cauchy distribution.\n\nusing Distributions\ny = rand(Cauchy(0, 10), 10_000)\ns = Series(y, FitCauchy())\nCauchy(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitGamma",
    "page": "API",
    "title": "OnlineStats.FitGamma",
    "category": "Type",
    "text": "FitGamma()\n\nOnline parameter estimate of a Gamma distribution (Method of Moments).\n\nusing Distributions\ny = rand(Gamma(5, 1), 1000)\ns = Series(y, FitGamma())\nGamma(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitLogNormal",
    "page": "API",
    "title": "OnlineStats.FitLogNormal",
    "category": "Type",
    "text": "FitLogNormal()\n\nOnline parameter estimate of a LogNormal distribution (MLE).\n\nusing Distributions\ny = rand(LogNormal(3, 4), 1000)\ns = Series(y, FitLogNormal())\nLogNormal(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitMultinomial",
    "page": "API",
    "title": "OnlineStats.FitMultinomial",
    "category": "Type",
    "text": "FitMultinomial(p)\n\nOnline parameter estimate of a Multinomial distribution.\n\nusing Distributions\ny = rand(Multinomial(10, [.2, .2, .6]), 1000)\ns = Series(y', FitMultinomial())\nMultinomial(value(s)...)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitMvNormal",
    "page": "API",
    "title": "OnlineStats.FitMvNormal",
    "category": "Type",
    "text": "FitMvNormal(d)\n\nOnline parameter estimate of a d-dimensional MvNormal distribution (MLE).\n\nusing Distributions\ny = rand(MvNormal(zeros(3), eye(3)), 1000)\ns = Series(y', FitMvNormal(3))\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.FitNormal",
    "page": "API",
    "title": "OnlineStats.FitNormal",
    "category": "Type",
    "text": "FitNormal()\n\nOnline parameter estimate of a Normal distribution (MLE).\n\nusing Distributions\ny = rand(Normal(-3, 4), 1000)\ns = Series(y, FitNormal())\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.MSPIC",
    "page": "API",
    "title": "OnlineStats.MSPIC",
    "category": "Type",
    "text": "MSPIC()\n\nMSPI-Q algorithm using a Lipschitz constant to majorize the objective.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.MSPIF",
    "page": "API",
    "title": "OnlineStats.MSPIF",
    "category": "Type",
    "text": "Experimental: MSPI-full matrix\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.NADAM",
    "page": "API",
    "title": "OnlineStats.NADAM",
    "category": "Type",
    "text": "NADAM(α1, α2)\n\nAdaptive Moment Estimation with momentum parameters α1 and α2.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.NSGD",
    "page": "API",
    "title": "OnlineStats.NSGD",
    "category": "Type",
    "text": "NSGD(α)\n\nNesterov accelerated Proximal Stochastic Gradient Descent.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.OMASQ",
    "page": "API",
    "title": "OnlineStats.OMASQ",
    "category": "Type",
    "text": "Experimental: OMM-constant\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.OMASQF",
    "page": "API",
    "title": "OnlineStats.OMASQF",
    "category": "Type",
    "text": "Experimental: OMM-full matrix\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.SGD",
    "page": "API",
    "title": "OnlineStats.SGD",
    "category": "Type",
    "text": "SGD()\n\nProximal Stochastic Gradient Descent.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.StatLearn",
    "page": "API",
    "title": "OnlineStats.StatLearn",
    "category": "Type",
    "text": "StatLearn(p, loss, penalty, λ, updater)\n\nFit a statistical learning model of p independent variables for a given loss, penalty, and λ.  Arguments are:\n\nloss: any Loss from LossFunctions.jl\npenalty: any Penalty from PenaltyFunctions.jl.\nλ: a Vector of element-wise regularization parameters\nupdater: SPGD(), ADAGRAD(), ADAM(), or ADAMAX()\nusing LossFunctions, PenaltyFunctions   x = randn(100_000, 10)   y = x * linspace(-1, 1, 10) + randn(100_000)   o = StatLearn(10, L2DistLoss(), L1Penalty(), fill(.1, 10), SPGD())   s = Series(o)   fit!(s, x, y)   coef(o)   predict(o, x)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStats.maprows-Tuple{Function,Integer,Vararg{Any,N} where N}",
    "page": "API",
    "title": "OnlineStats.maprows",
    "category": "Method",
    "text": "maprows(f::Function, b::Integer, data...)\n\nMap rows of data in batches of size b.  Most usage is done through do blocks.\n\ns = Series(Mean())\nmaprows(10, randn(100)) do yi\n    fit!(s, yi)\n    info(\"nobs: $(nobs(s))\")\nend\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.Bootstrap",
    "page": "API",
    "title": "OnlineStatsBase.Bootstrap",
    "category": "Type",
    "text": "Bootstrap(o::OnlineStat, nreps = 100, d = [0, 2], f = value)\n\nOnline Statistical Bootstrapping.  Create nreps replicates of the OnlineStat o. When fit! is called, each of the replicates will be updated rand(d) times. value(b::Bootstrap) returns f mapped to the replicates.\n\nb = Bootstrap(Mean())\nfit!(b, randn(1000))\nvalue(b)        # `f` mapped to replicates\nmean(value(b))  # mean\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.Bounded",
    "page": "API",
    "title": "OnlineStatsBase.Bounded",
    "category": "Type",
    "text": "Bounded(weight, λ)\n\nGive a Weight a lower bound.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.CovMatrix",
    "page": "API",
    "title": "OnlineStatsBase.CovMatrix",
    "category": "Type",
    "text": "CovMatrix(d)\n\nCovariance Matrix of d variables.\n\ny = randn(100, 5)\nSeries(y, CovMatrix(5))\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.Diff",
    "page": "API",
    "title": "OnlineStatsBase.Diff",
    "category": "Type",
    "text": "Diff()\n\nTrack the difference and the last value.\n\ns = Series(randn(1000), Diff())\nvalue(s)\n\n\n\n"
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
    "location": "pages/api.html#OnlineStatsBase.Extrema",
    "page": "API",
    "title": "OnlineStatsBase.Extrema",
    "category": "Type",
    "text": "Extrema()\n\nMaximum and minimum.\n\ns = Series(randn(100), Extrema())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.HarmonicWeight",
    "page": "API",
    "title": "OnlineStatsBase.HarmonicWeight",
    "category": "Type",
    "text": "HarmonicWeight(a = 10.0)\n\nDecreases at a slow rate\nWeight at observation t is γ = a / (a + t - 1)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.HyperLogLog",
    "page": "API",
    "title": "OnlineStatsBase.HyperLogLog",
    "category": "Type",
    "text": "HyperLogLog(b)  # 4 ≤ b ≤ 16\n\nApproximate count of distinct elements.\n\ns = Series(rand(1:10, 1000), HyperLogLog(12))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.KMeans",
    "page": "API",
    "title": "OnlineStatsBase.KMeans",
    "category": "Type",
    "text": "KMeans(p, k)\n\nApproximate K-Means clustering of k clusters and p variables.\n\nusing OnlineStats, Distributions\nd = MixtureModel([Normal(0), Normal(5)])\ny = rand(d, 100_000, 1)\ns = Series(y, LearningRate(.6), KMeans(1, 2))\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.LearningRate",
    "page": "API",
    "title": "OnlineStatsBase.LearningRate",
    "category": "Type",
    "text": "LearningRate(r = .6)\n\nMainly for stochastic approximation types\nDecreases at a \"slow\" rate\nWeight at observation t is γ = 1 / t ^ r\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.LearningRate2",
    "page": "API",
    "title": "OnlineStatsBase.LearningRate2",
    "category": "Type",
    "text": "LearningRate2(c = .5)\n\nMainly for stochastic approximation types\nDecreases at a \"slow\" rate\nWeight at observation t is γ = inv(1 + c * (t - 1))\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.LinReg",
    "page": "API",
    "title": "OnlineStatsBase.LinReg",
    "category": "Type",
    "text": "LinReg(p, λ::Float64 = 0.0)  # use λ for all parameters\nLinReg(p, λfactor::Vector{Float64})\n\nRidge regression of p variables with elementwise regularization.\n\nx = randn(100, 10)\ny = x * linspace(-1, 1, 10) + randn(100)\no = LinReg(10)\nSeries((x,y), o)\nvalue(o)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.MV",
    "page": "API",
    "title": "OnlineStatsBase.MV",
    "category": "Type",
    "text": "MV(p, o)\n\nTrack p univariate OnlineStats o     y = randn(1000, 5)     o = MV(5, Mean())     s = Series(y, o)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.McclainWeight",
    "page": "API",
    "title": "OnlineStatsBase.McclainWeight",
    "category": "Type",
    "text": "McclainWeight(ᾱ = 0.1)\n\n\"smoothed\" version of BoundedEqualWeight\nweights asymptotically approach ᾱ\nWeight at observation t is γ(t-1) / (1 + γ(t-1) - ᾱ)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.Mean",
    "page": "API",
    "title": "OnlineStatsBase.Mean",
    "category": "Type",
    "text": "Mean()\n\nUnivariate mean.\n\ns = Series(randn(100), Mean())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.Moments",
    "page": "API",
    "title": "OnlineStatsBase.Moments",
    "category": "Type",
    "text": "Moments()\n\nFirst four non-central moments.\n\ns = Series(randn(1000), Moments(10))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.OHistogram",
    "page": "API",
    "title": "OnlineStatsBase.OHistogram",
    "category": "Type",
    "text": "OHistogram(range)\n\nMake a histogram with bins given by range.  Uses left-closed bins.\n\ny = randn(100)\ns = Series(y, OHistogram(-4:.1:4))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.OrderStats",
    "page": "API",
    "title": "OnlineStatsBase.OrderStats",
    "category": "Type",
    "text": "OrderStats(b)\n\nAverage order statistics with batches of size b.\n\ns = Series(randn(1000), OrderStats(10))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.QuantileMM",
    "page": "API",
    "title": "OnlineStatsBase.QuantileMM",
    "category": "Type",
    "text": "QuantileMM(q = 0.5)\n\nApproximate quantiles via an online MM algorithm.\n\ns = Series(randn(1000), QuantileMM())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.ReservoirSample",
    "page": "API",
    "title": "OnlineStatsBase.ReservoirSample",
    "category": "Type",
    "text": "ReservoirSample(k, t = Float64)\n\nReservoir sample of k items.\n\no = ReservoirSample(k, Int)\ns = Series(o)\nfit!(s, 1:10000)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.Scaled",
    "page": "API",
    "title": "OnlineStatsBase.Scaled",
    "category": "Type",
    "text": "Scaled(weight, λ)\nλ * weight\n\nScale a weight by a constant.\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.Series",
    "page": "API",
    "title": "OnlineStatsBase.Series",
    "category": "Type",
    "text": "Series(stats...)\nSeries(weight, stats...)\nSeries(data, weight, stats...)\nSeries(weight, data, stats...)\n\nTrack any number of OnlineStats using a given weighting mechanism.\n\ns = Series(ExponentialWeight(.1), Mean(), Variance(), Moments())\nfit!(s, randn(1000))\nvalue(s)\n\nx, y = randn(1000, 10), randn(1000)\ns = Series(LinReg(10))\nfit!(s, (x,y))\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.Sum",
    "page": "API",
    "title": "OnlineStatsBase.Sum",
    "category": "Type",
    "text": "Sum()\n\nTrack the overall sum.\n\ns = Series(randn(1000), Sum())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.Variance",
    "page": "API",
    "title": "OnlineStatsBase.Variance",
    "category": "Type",
    "text": "Variance()\n\nUnivariate variance.\n\ns = Series(randn(100), Variance())\nvalue(s)\n\n\n\n"
},

{
    "location": "pages/api.html#OnlineStatsBase.replicates-Tuple{OnlineStatsBase.Bootstrap}",
    "page": "API",
    "title": "OnlineStatsBase.replicates",
    "category": "Method",
    "text": "replicates(b)\n\nReturn the vector of replicates from Bootstrap b\n\n\n\n"
},

{
    "location": "pages/api.html#StatsBase.fit!",
    "page": "API",
    "title": "StatsBase.fit!",
    "category": "Function",
    "text": "fit!(s, y)\nfit!(s, y, w)\n\nUpdate a Series s with more data y and optional weighting w.     y = randn(100)     w = rand(100)\n\ns = Series(Mean())\nfit!(s, y[1])        # one observation: use Series weight\nfit!(s, y[1], w[1])  # one observation: override weight\nfit!(s, y)           # multiple observations: use Series weight\nfit!(s, y, w[1])     # multiple observations: override each weight with w[1]\nfit!(s, y, w)        # multiple observations: y[i] uses weight w[i]\n\n\n\n"
},

{
    "location": "pages/api.html#StatsBase.confint",
    "page": "API",
    "title": "StatsBase.confint",
    "category": "Function",
    "text": "confint(b, coverageprob = .95)\n\nReturn a confidence interval for a Bootstrap b.\n\n\n\n"
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
