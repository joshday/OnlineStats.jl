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
    "text": "OnlineStats is a Julia package for statistical analysis with algorithms that run both online and in parallel.  Online algorithms are well suited for streaming data or when data is too large to hold in memory.  Observations are processed one at a time and all algorithms use O(1) memory."
},

{
    "location": "index.html#Installation-1",
    "page": "Basics",
    "title": "Installation",
    "category": "section",
    "text": "import Pkg\nPkg.add(\"OnlineStats\")"
},

{
    "location": "index.html#Basics-2",
    "page": "Basics",
    "title": "Basics",
    "category": "section",
    "text": ""
},

{
    "location": "index.html#Every-Stat-is-:-OnlineStat-1",
    "page": "Basics",
    "title": "Every Stat is <: OnlineStat",
    "category": "section",
    "text": "using OnlineStats\n\nm = Mean()"
},

{
    "location": "index.html#Stats-Can-Be-Updated-1",
    "page": "Basics",
    "title": "Stats Can Be Updated",
    "category": "section",
    "text": "y = randn(100);\n\nfit!(m, y)"
},

{
    "location": "index.html#Stats-Can-Be-Merged-1",
    "page": "Basics",
    "title": "Stats Can Be Merged",
    "category": "section",
    "text": "y2 = randn(100);\n\nm2 = fit!(Mean(), y2)\n\nmerge!(m, m2)"
},

{
    "location": "index.html#Stats-Have-a-Value-1",
    "page": "Basics",
    "title": "Stats Have a Value",
    "category": "section",
    "text": "value(m)"
},

{
    "location": "collectionstats.html#",
    "page": "Collections of Stats",
    "title": "Collections of Stats",
    "category": "page",
    "text": ""
},

{
    "location": "collectionstats.html#Collections-of-Stats-1",
    "page": "Collections of Stats",
    "title": "Collections of Stats",
    "category": "section",
    "text": "(Image: )using OnlineStats"
},

{
    "location": "collectionstats.html#Series-1",
    "page": "Collections of Stats",
    "title": "Series",
    "category": "section",
    "text": "A Series tracks stats that should be applied to the same data stream.y = rand(1000)\n\ns = Series(Mean(), Variance())\nfit!(s, y)"
},

{
    "location": "collectionstats.html#FTSeries-1",
    "page": "Collections of Stats",
    "title": "FTSeries",
    "category": "section",
    "text": "An FTSeries tracks stats that should be applied to the same data stream, but filters and transforms (hence FT) the input data before it is sent to its stats. s = FTSeries(Mean(), Variance(); filter = x->true, transform = abs)\nfit!(s, -y)"
},

{
    "location": "collectionstats.html#Group-1",
    "page": "Collections of Stats",
    "title": "Group",
    "category": "section",
    "text": "A Group tracks stats that should be applied to different data streams.g = Group(Mean(), CountMap(Bool))\n\nitr = zip(randn(100), rand(Bool, 100))\n\nfit!(g, itr)"
},

{
    "location": "weights.html#",
    "page": "Weights",
    "title": "Weights",
    "category": "page",
    "text": ""
},

{
    "location": "weights.html#Weights-1",
    "page": "Weights",
    "title": "Weights",
    "category": "section",
    "text": "Many OnlineStats are parameterized by a Weight that controls the influence of new observations.  If the OnlineStat is capable of calculating the same result as a corresponding offline estimator, it will have a keyword argument weight.  If the OnlineStat uses stochastic approximation, it will have a keyword argument rate.  Consider how weights affect the influence of the next observation on an online mean theta^(t), as many OnlineStats use updates of this form.  A larger weight  gamma_t puts higher influence on the new observation x_t:theta^(t) = (1-gamma_t)theta^(t-1) + gamma_t x_tnote: Note\nThe values produced by a Weight must follow two rules:gamma_1 = 1 (guarantees theta^(1) = x_1)\ngamma_t in (0 1) quad forall t  1 (guarantees theta^(t) stays inside a convex space)<br>\n<img src=\"https://user-images.githubusercontent.com/8075494/29486708-a52b9de6-84ba-11e7-86c5-debfc5a80cca.png\" height=450>"
},

{
    "location": "weights.html#OnlineStatsBase.EqualWeight",
    "page": "Weights",
    "title": "OnlineStatsBase.EqualWeight",
    "category": "type",
    "text": "EqualWeight()\n\nEqually weighted observations.  \n\nγ(t) = 1  t\n\n\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.ExponentialWeight",
    "page": "Weights",
    "title": "OnlineStatsBase.ExponentialWeight",
    "category": "type",
    "text": "ExponentialWeight(λ::Float64)\nExponentialWeight(lookback::Int)\n\nExponentially weighted observations.  The first weight is 1.0 and all else are  λ = 2 / (lookback + 1).\n\nγ(t) = λ\n\n\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.LearningRate",
    "page": "Weights",
    "title": "OnlineStatsBase.LearningRate",
    "category": "type",
    "text": "LearningRate(r = .6)\n\nSlowly decreasing weight.  Satisfies the standard stochastic approximation assumption   γ(t) =   γ(t)^2   if r  (5 1.\n\nγ(t) = inv(t ^ r)\n\n\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.HarmonicWeight",
    "page": "Weights",
    "title": "OnlineStatsBase.HarmonicWeight",
    "category": "type",
    "text": "HarmonicWeight(a = 10.0)\n\nWeight determined by harmonic series.  \n\nγ(t) = a  (a + t - 1)\n\n\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.McclainWeight",
    "page": "Weights",
    "title": "OnlineStatsBase.McclainWeight",
    "category": "type",
    "text": "McclainWeight(α = .1)\n\nWeight which decreases into a constant.\n\nγ(t) = γ(t-1)  (1 + γ(t-1) - α)\n\n\n\n\n\n"
},

{
    "location": "weights.html#Weight-Types-1",
    "page": "Weights",
    "title": "Weight Types",
    "category": "section",
    "text": "EqualWeight\nExponentialWeight\nLearningRate\nHarmonicWeight\nMcclainWeight"
},

{
    "location": "weights.html#OnlineStatsBase.Bounded",
    "page": "Weights",
    "title": "OnlineStatsBase.Bounded",
    "category": "type",
    "text": "Bounded(w::Weight, λ::Float64)\n\nBound the weight by a constant.\n\nγ(t) = max(γ(t) λ)\n\n\n\n\n\n"
},

{
    "location": "weights.html#OnlineStatsBase.Scaled",
    "page": "Weights",
    "title": "OnlineStatsBase.Scaled",
    "category": "type",
    "text": "Scaled(w::Weight, λ::Float64)\n\nScale a weight by a constant.\n\nγ(t) = λ * γ(t)\n\n\n\n\n\n"
},

{
    "location": "weights.html#Weight-wrappers-1",
    "page": "Weights",
    "title": "Weight wrappers",
    "category": "section",
    "text": "OnlineStatsBase.Bounded\nOnlineStatsBase.Scaled"
},

{
    "location": "weights.html#Custom-Weighting-1",
    "page": "Weights",
    "title": "Custom Weighting",
    "category": "section",
    "text": "The Weight can be any callable object that receives the number of observations as its argument.  For example:weight = inv will have the same result as weight = EqualWeight().\nweight = x -> x == 1 ? 1.0 : .01 will have the same result as weight = ExponentialWeight(.01)using OnlineStats # hide\ny = randn(100);\n\nfit!(Mean(weight = EqualWeight()), y)\nfit!(Mean(weight = inv), y)\n\nfit!(Mean(weight = ExponentialWeight(.01)), y)\nfit!(Mean(weight = x -> x == 1 ? 1.0 : .01), y)"
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
    "text": "Statistic/Model OnlineStat\nUnivariate Statistics: \nMean Mean\nVariance Variance\nQuantiles Quantile and P2Quantile\nMaximum/Minimum Extrema\nSkewness and kurtosis Moments\nSum Sum\nTime Series: \nDifference Diff\nLag Lag\nAutocorrelation/autocovariance AutoCov\nTracked history StatHistory\nMultivariate Analysis: \nCovariance/correlation matrix CovMatrix\nPrincipal components analysis CovMatrix\nK-means clustering (SGD) KMeans\nMultiple univariate statistics Group\nNonparametric Density Estimation: \nHistograms/continuous density Hist and KHist\nApproximate order statistics OrderStats\nCount for each unique value CountMap\nParametric Density Estimation: \nBeta FitBeta\nCauchy FitCauchy\nGamma FitGamma\nLogNormal FitLogNormal\nNormal FitNormal\nMultinomial FitMultinomial\nMvNormal FitMvNormal\nStatistical Learning: \nGLMs with regularization StatLearn\nLogistic regression StatLearn\nLinear SVMs StatLearn\nQuantile regression StatLearn\nAbsolute loss regression StatLearn\nDistance-weighted discrimination StatLearn\nHuber-loss regression StatLearn\nLinear (also ridge) regression LinReg, LinRegBuilder\nDecision Trees FastTree\nRandom Forest FastForest\nNaive Bayes Classifier NBClassifier\nOther: \nStatistical Bootstrap Bootstrap\nApprox. count of distinct elements HyperLogLog\nReservoir sampling ReservoirSample\nCallbacks CallFun\nBig Data Viz Partition, IndexedPartition\nCollections of Stats: \nApplied to same data stream Series, FTSeries\nApplied to different data streams Group\nCalculated stat by group GroupBy"
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
    "text": "Two OnlineStats can be merged together, which facilitates Embarassingly parallel computations.  Merging in OnlineStats is used by JuliaDB to run analytics in parallel on large persistent datasets.note: Note\nIn general, fit! is a cheaper operation than merge!."
},

{
    "location": "parallel.html#ExactStat-merges-1",
    "page": "Parallel Computation",
    "title": "ExactStat merges",
    "category": "section",
    "text": "Many OnlineStats are capable of calculating the exact value as a corresponding offline estimator.  For these types, the order of fit!-ting and merge!-ing does not matter.y1 = randn(10_000)\ny2 = randn(10_000)\ny3 = randn(10_000)\n\ns1 = Series(Mean(), Variance(), KHist(50))\ns2 = Series(Mean(), Variance(), KHist(50))\ns3 = Series(Mean(), Variance(), KHist(50))\n\nfit!(s1, y1)\nfit!(s2, y2)\nfit!(s3, y3)\n\nmerge!(s1, s2)  # merge information from s2 into s1\nmerge!(s1, s3)  # merge information from s3 into s1<img width = 500 src = \"https://user-images.githubusercontent.com/8075494/32748459-519986e8-c88a-11e7-89b3-80dedf7f261b.png\">"
},

{
    "location": "parallel.html#Other-Merges-1",
    "page": "Parallel Computation",
    "title": "Other Merges",
    "category": "section",
    "text": "For OnlineStats that rely on approximations, merging isn\'t always a well-defined operation.  OnlineStats will either make a sane choice for merging or print a warning that merging did not occur.  Please open an issue to discuss a stat you believe you should be merge-able."
},

{
    "location": "visualizations.html#",
    "page": "Visualizations",
    "title": "Visualizations",
    "category": "page",
    "text": "import Pkg, Random\nusing Dates\nPkg.add(\"GR\")\nPkg.add(\"Plots\")\nENV[\"GKSwstype\"] = \"100\"\nusing OnlineStats\nusing Plots\nRandom.seed!(1234)\ngr()"
},

{
    "location": "visualizations.html#Visualizations-1",
    "page": "Visualizations",
    "title": "Visualizations",
    "category": "section",
    "text": ""
},

{
    "location": "visualizations.html#Many-Stats-Can-Be-Plotted-via-Plot-Recipes-1",
    "page": "Visualizations",
    "title": "Many Stats Can Be Plotted via Plot Recipes",
    "category": "section",
    "text": "s = fit!(Series(KHist(25), Hist(-5:5)), randn(10^6))\nplot(s)\nsavefig(\"plot_series.png\") # hide(Image: )"
},

{
    "location": "visualizations.html#Naive-Bayes-Classifier-1",
    "page": "Visualizations",
    "title": "Naive Bayes Classifier",
    "category": "section",
    "text": "The NBClassifier type stores conditional histograms of the predictor variables, allowing you to plot approximate \"group by\" distributions:# make data\nx = randn(10^5, 5)\ny = x * [1,3,5,7,9] .> 0\n\no = NBClassifier(5, Bool)  # 5 predictors with Boolean categories\nfit!(o, (x, y))\nplot(o)\nsavefig(\"nbclassifier.png\"); nothing # hide(Image: )"
},

{
    "location": "visualizations.html#Mosaic-Plots-1",
    "page": "Visualizations",
    "title": "Mosaic Plots",
    "category": "section",
    "text": "The Mosaic type allows you to plot the relationship between two categorical variables.   It is typically more useful than a bar plot, as class probabilities are given by the horizontal widths.x = rand([true, true, false], 10^5)\ny = map(xi -> xi ? rand(1:3) : rand(1:4), x)\no = fit!(Mosaic(Bool, Int), [x y])\nplot(o)\nsavefig(\"mosaic.png\"); nothing # hide(Image: )"
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
    "text": "y = cumsum(randn(10^6)) + 100randn(10^6)\n\no = Partition(Hist(10))\n\nfit!(o, y)\n\nplot(o, xlab = \"Nobs\")\nsavefig(\"partition_hist.png\"); nothing # hide(Image: )o = Partition(Mean())\no2 = Partition(Extrema())\n\ns = Series(o, o2)\n\nfit!(s, y)\n\nplot(s, layout = 1, xlab = \"Nobs\")\nsavefig(\"partition_mean_ex.png\"); nothing # hide(Image: )"
},

{
    "location": "visualizations.html#Plot-a-custom-function-of-the-OnlineStats-(default-is-value)-1",
    "page": "Visualizations",
    "title": "Plot a custom function of the OnlineStats (default is value)",
    "category": "section",
    "text": "Plot of mean +/- standard deviation:o = Partition(Variance())\n\nfit!(o, y)\n\nplot(o, x -> [mean(x) - std(x), mean(x), mean(x) + std(x)], xlab = \"Nobs\")\nsavefig(\"partition_ci.png\"); nothing # hide  (Image: )"
},

{
    "location": "visualizations.html#Categorical-Data-1",
    "page": "Visualizations",
    "title": "Categorical Data",
    "category": "section",
    "text": "y = rand([\"a\", \"a\", \"b\", \"c\"], 10^6)\n\no = Partition(CountMap(String), 75)\n\nfit!(o, y)\n\nplot(o, xlab = \"Nobs\")\nsavefig(\"partition_countmap.png\"); nothing # hide(Image: )"
},

{
    "location": "visualizations.html#Indexed-Partitions-1",
    "page": "Visualizations",
    "title": "Indexed Partitions",
    "category": "section",
    "text": "The Partition type can only track the number of observations in the x-axis.  If you wish to plot one variable against another, you can use an IndexedPartition.  x = randn(10^5)\ny = x + randn(10^5)\n\no = fit!(IndexedPartition(Float64, Hist(10)), [x y])\n\nplot(o, ylab = \"Y\", xlab = \"X\")\nsavefig(\"indexpart2.png\"); nothing # hide(Image: )x = rand(\'a\':\'z\', 10^5)\ny = Float64.(x) + randn(10^5)\n\no = fit!(IndexedPartition(Char, Extrema()), [x y])\n\nplot(o, xlab = \"Category\")\nsavefig(\"indexpart3.png\"); nothing # hide(Image: )x = rand(10^5)\ny = rand(1:5, 10^5)\n\no = fit!(IndexedPartition(Float64, CountMap(Int)), zip(x,y))\n\nplot(o, xlab = \"X\", ylab = \"Y\")\nsavefig(\"indexpart4.png\"); nothing # hide(Image: )x = rand(1:1000, 10^5)\ny = x .+ 30randn(10^5)\n\no = fit!(IndexedPartition(Int, KHist(20)), zip(x,y))\n\nplot(o)\nsavefig(\"indexpartequal.png\"); nothing # hide\n(Image: )"
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
    "text": "A collection of jupyter notebooks are hosted at https://github.com/joshday/OnlineStatsDemos.  "
},

{
    "location": "howfitworks.html#",
    "page": "How fit! Works",
    "title": "How fit! Works",
    "category": "page",
    "text": "using OnlineStats"
},

{
    "location": "howfitworks.html#How-fit!-Works-1",
    "page": "How fit! Works",
    "title": "How fit! Works",
    "category": "section",
    "text": "Stats are subtypes of OnlineStat{T} where T is the type of a single observation.\nE.g. Mean <: OnlineStat{Number}\nWhen you try to fit!(o::OnlineStat{T}, data::T), o will be updated with the single observation data.\nWhen you try to fit!(o::OnlineStat{T}, data::S), OnlineStats will attempt to iterate through data and fit! each item."
},

{
    "location": "howfitworks.html#Why-is-Fitting-Based-on-Iteration?-1",
    "page": "How fit! Works",
    "title": "Why is Fitting Based on Iteration?",
    "category": "section",
    "text": ""
},

{
    "location": "howfitworks.html#Reason-1:-OnlineStats-doesn\'t-want-to-make-assumptions-on-the-shape-of-your-data-1",
    "page": "How fit! Works",
    "title": "Reason 1: OnlineStats doesn\'t want to make assumptions on the shape of your data",
    "category": "section",
    "text": "Consider CovMatrix, for which a single observation is an AbstractVector, Tuple, or NamedTuple. If I try to update it with a Matrix, it\'s ambiguous whether I want rows or columns of  the matrix to be treated as individual observations.  By default, OnlineStats will try observations-in-rows, but you can alternately/explicitly  use the OnlineStatsBase.eachrow and OnlineStatsBase.eachcol functions, which efficiently iterate over  the rows or columns of the matrix, respectively.fit!(CovMatrix(), eachrow(randn(1000,2)))\n\nfit!(CovMatrix(), eachcol(randn(2,1000)))"
},

{
    "location": "howfitworks.html#Reason-2:-OnlineStats-naturally-works-out-of-the-box-with-many-data-structures-1",
    "page": "How fit! Works",
    "title": "Reason 2: OnlineStats naturally works out-of-the-box with many data structures",
    "category": "section",
    "text": "Tabular data structures such as those in JuliaDB iterate over named tuples of rows, so things like this just work:using JuliaDB\n\nt = table(randn(100), randn(100))\n\nfit!(2Mean(), t)"
},

{
    "location": "howfitworks.html#A-Common-Error-1",
    "page": "How fit! Works",
    "title": "A Common Error",
    "category": "section",
    "text": "Consider the following example:fit!(Mean(), \"asdf\")This causes an error because:\"asdf\" is not a Number, so OnlineStats attempts to iterate through it\nIterating through \"asdf\" begins with the character \'a\'"
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
    "text": "ADADELTA(ρ = .95)\n\nAn extension of ADAGRAD.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ADAGRAD",
    "page": "API",
    "title": "OnlineStats.ADAGRAD",
    "category": "type",
    "text": "ADAGRAD()\n\nA variation of SGD with element-wise weights generated by the average of the squared gradients.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ADAM",
    "page": "API",
    "title": "OnlineStats.ADAM",
    "category": "type",
    "text": "ADAM(β1 = .99, β2 = .999)\n\nA variant of SGD with element-wise learning rates generated by exponentially weighted first and second moments of the gradient.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ADAMAX",
    "page": "API",
    "title": "OnlineStats.ADAMAX",
    "category": "type",
    "text": "ADAMAX(η, β1 = .9, β2 = .999)\n\nADAMAX with momentum parameters β1, β2.  ADAMAX is an extension of ADAM.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.AutoCov",
    "page": "API",
    "title": "OnlineStats.AutoCov",
    "category": "type",
    "text": "AutoCov(b, T = Float64; weight=EqualWeight())\n\nCalculate the auto-covariance/correlation for lags 0 to b for a data stream of type T.\n\nExample\n\ny = cumsum(randn(100))\no = AutoCov(5)\nfit!(o, y)\nautocov(o)\nautocor(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.BiasVec",
    "page": "API",
    "title": "OnlineStats.BiasVec",
    "category": "type",
    "text": "BiasVec(x)\n\nLightweight wrapper of a vector which adds a \"bias\" term at the end.\n\nExample\n\nBiasVec(rand(5))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Bootstrap",
    "page": "API",
    "title": "OnlineStats.Bootstrap",
    "category": "type",
    "text": "Bootstrap(o::OnlineStat, nreps = 100, d = [0, 2])\n\nCalculate an online statistical bootstrap of nreps replicates of o.  For each call to fit!, any given replicate will be updated rand(d) times (default is double or nothing).\n\nExample\n\no = Bootstrap(Variance())\nfit!(o, randn(1000))\nconfint(o, .95)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CStat",
    "page": "API",
    "title": "OnlineStats.CStat",
    "category": "type",
    "text": "CStat(stat)\n\nTrack a univariate OnlineStat for complex numbers.  A copy of stat is made to separately track the real and imaginary parts.\n\nExample\n\ny = randn(100) + randn(100)im\nfit!(CStat(Mean()), y)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CallFun",
    "page": "API",
    "title": "OnlineStats.CallFun",
    "category": "type",
    "text": "CallFun(o::OnlineStat, f::Function)\n\nCall f(o) every time the OnlineStat o gets updated.\n\nExample\n\no = CallFun(Mean(), println)\nfit!(o, [0,0,1,1])\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CountMap",
    "page": "API",
    "title": "OnlineStats.CountMap",
    "category": "type",
    "text": "CountMap(T::Type)\nCountMap(dict::AbstractDict{T, Int})\n\nTrack a dictionary that maps unique values to its number of occurrences.  Similar to StatsBase.countmap.\n\nExample\n\no = fit!(CountMap(Int), rand(1:10, 1000))\nvalue(o)\nprobs(o)\nOnlineStats.pdf(o, 1)\ncollect(keys(o))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.CovMatrix",
    "page": "API",
    "title": "OnlineStats.CovMatrix",
    "category": "type",
    "text": "CovMatrix(p=0; weight=EqualWeight())\nCovMatrix(::Type{T}, p=0; weight=EqualWeight())\n\nCalculate a covariance/correlation matrix of p variables.  If the number of variables is unknown, leave the default p=0.\n\nExample\n\no = fit!(CovMatrix(), randn(100, 4))\ncor(o)\ncov(o)\nmean(o)\nvar(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Diff",
    "page": "API",
    "title": "OnlineStats.Diff",
    "category": "type",
    "text": "Diff(T::Type = Float64)\n\nTrack the difference and the last value.\n\nExample\n\no = Diff()\nfit!(o, [1.0, 2.0])\nlast(o)\ndiff(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Extrema",
    "page": "API",
    "title": "OnlineStats.Extrema",
    "category": "type",
    "text": "Extrema(T::Type = Float64)\n\nMaximum and minimum.\n\nExample\n\no = fit!(Extrema(), rand(10^5))\nextrema(o)\nmaximum(o)\nminimum(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FTSeries",
    "page": "API",
    "title": "OnlineStats.FTSeries",
    "category": "type",
    "text": "FTSeries(stats...; filter=x->true, transform=identity)\n\nTrack multiple stats for one data stream that is filtered and transformed before being fitted.\n\nFTSeries(T, stats...; filter, transform)\n\nCreate an FTSeries and specify the type T of the transformed values.\n\nExample\n\no = FTSeries(Mean(), Variance(); transform=abs)\nfit!(o, -rand(1000))\n\n# Remove missing values represented as DataValues\nusing DataValues\ny = DataValueArray(randn(100), rand(Bool, 100))\no = FTSeries(DataValue, Mean(); transform=get, filter=!isna)\nfit!(o, y)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FastForest",
    "page": "API",
    "title": "OnlineStats.FastForest",
    "category": "type",
    "text": "FastForest(p, nkeys=2; stat=FitNormal(), kw...)\n\nCalculate a random forest where each variable is summarized by stat.  \n\nKeyword Arguments\n\nnt=100): Number of trees in the forest\nb=floor(Int, sqrt(p)): Number of random features for each tree to receive\nmaxsize=1000: Maximum size for any tree in the forest\nsplitsize=5000: Number of observations in any given node before splitting\nλ = .05: Probability that each tree is updated on a new observation\n\nExample\n\nx, y = randn(10^5, 10), rand(1:2, 10^5)\n\no = fit!(FastForest(10), (x,y))\n\nclassify(o, x[1,:])\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FastTree",
    "page": "API",
    "title": "OnlineStats.FastTree",
    "category": "type",
    "text": "FastTree(p::Int, nclasses=2; stat=FitNormal(), maxsize=5000, splitsize=1000)\n\nCalculate a decision tree of p predictors variables and classes 1, 2, …, nclasses.   Nodes split when they reach splitsize observations until maxsize nodes are in the tree. Each variable is summarized by stat, which can be FitNormal() or Hist(nbins).\n\nExample\n\nx = randn(10^5, 10)\ny = rand([1,2], 10^5)\n\no = fit!(FastTree(10), (x,y))\n\nxi = randn(10)\nclassify(o, xi)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitBeta",
    "page": "API",
    "title": "OnlineStats.FitBeta",
    "category": "type",
    "text": "FitBeta(; weight)\n\nOnline parameter estimate of a Beta distribution (Method of Moments).\n\nExample\n\no = fit!(FitBeta(), rand(1000))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitCauchy",
    "page": "API",
    "title": "OnlineStats.FitCauchy",
    "category": "type",
    "text": "FitCauchy(; alg, rate)\n\nApproximate parameter estimation of a Cauchy distribution.  Estimates are based on quantiles, so that alg will be passed to Quantile.\n\nExample\n\no = fit!(FitCauchy(), randn(1000))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitGamma",
    "page": "API",
    "title": "OnlineStats.FitGamma",
    "category": "type",
    "text": "FitGamma(; weight)\n\nOnline parameter estimate of a Gamma distribution (Method of Moments).\n\nExample\n\nusing Random\no = fit!(FitGamma(), randexp(10^5))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitLogNormal",
    "page": "API",
    "title": "OnlineStats.FitLogNormal",
    "category": "type",
    "text": "FitLogNormal()\n\nOnline parameter estimate of a LogNormal distribution (MLE).\n\nExample\n\no = fit!(FitLogNormal(), exp.(randn(10^5)))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitMultinomial",
    "page": "API",
    "title": "OnlineStats.FitMultinomial",
    "category": "type",
    "text": "FitMultinomial(p)\n\nOnline parameter estimate of a Multinomial distribution.  The sum of counts does not need to be consistent across observations.  Therefore, the n parameter of the Multinomial distribution is returned as 1.\n\nExample\n\nx = [1 2 3; 4 8 12]\nfit!(FitMultinomial(3), x)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitMvNormal",
    "page": "API",
    "title": "OnlineStats.FitMvNormal",
    "category": "type",
    "text": "FitMvNormal(d)\n\nOnline parameter estimate of a d-dimensional MvNormal distribution (MLE).\n\nExample\n\ny = randn(100, 2)\no = fit!(FitMvNormal(2), y)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.FitNormal",
    "page": "API",
    "title": "OnlineStats.FitNormal",
    "category": "type",
    "text": "FitNormal()\n\nCalculate the parameters of a normal distribution via maximum likelihood.\n\nExample\n\no = fit!(FitNormal(), randn(1000))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Group",
    "page": "API",
    "title": "OnlineStats.Group",
    "category": "type",
    "text": "Group(stats::OnlineStat...)\nGroup(; stats...)\nGroup(collection)\n\nCreate a vector-input stat from several scalar-input stats.  For a new observation y, y[i] is sent to stats[i].\n\nExamples\n\nx = randn(100, 2)\n\nfit!(Group(Mean(), Mean()), x)\nfit!(Group(Mean(), Variance()), x)\n\no = fit!(Group(m1 = Mean(), m2 = Mean()), x)\no.stats.m1\no.stats.m2\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.GroupBy",
    "page": "API",
    "title": "OnlineStats.GroupBy",
    "category": "type",
    "text": "GroupBy{T}(stat)\n\nUpdate stat for each group (of type T).\n\nExample\n\nx = rand(1:10, 10^5)\ny = x .+ randn(10^5)\nfit!(GroupBy{Int}(Extrema()), zip(x,y))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.HeatMap",
    "page": "API",
    "title": "OnlineStats.HeatMap",
    "category": "type",
    "text": "Heatmap(xedges, yedges; left = true, closed = true)\n\nCreate a two dimensional histogram with the bin partition created by xedges and yedges.   When fitting a new observation, the first value will be associated with X, the second with Y.\n\nIf left, the bins will be left-closed.\nIf closed, the bins on the ends will be closed.  See Hist.\n\nExample\n\no = fit!(HeatMap(-5:.1:5, -5:.1:5), eachrow(randn(10^5, 2)))\n\nusing Plots\nplot(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Hist",
    "page": "API",
    "title": "OnlineStats.Hist",
    "category": "type",
    "text": "Hist(edges; left = true, closed = true)\n\nCreate a histogram with bin partition defined by edges.\n\nIf left, the bins will be left-closed.\nIf closed, the bin on the end will be closed.\nE.g. for a two bin histogram a b) b c) vs. a b) b c\n\nExample\n\no = fit!(Hist(-5:.1:5), randn(10^6))\n\n# approximate statistics \nusing Statistics\n\nmean(o)\nvar(o)\nstd(o)\nquantile(o)\nmedian(o)\nextrema(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.HyperLogLog",
    "page": "API",
    "title": "OnlineStats.HyperLogLog",
    "category": "type",
    "text": "HyperLogLog(b, T::Type = Number)  # 4 ≤ b ≤ 16\n\nApproximate count of distinct elements.\n\nExample\n\nfit!(HyperLogLog(12), rand(1:10,10^5))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.IndexedPartition",
    "page": "API",
    "title": "OnlineStats.IndexedPartition",
    "category": "type",
    "text": "IndexedPartition(T, stat, b=100)\n\nSummarize data with stat over a partition of size b where the data is indexed by a  variable of type T.\n\nExample\n\no = IndexedPartition(Float64, Hist(10))\nfit!(o, randn(10^4, 2))\n\nusing Plots \nplot(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.KHist",
    "page": "API",
    "title": "OnlineStats.KHist",
    "category": "type",
    "text": "KHist(k::Int)\n\nEstimate the probability density of a univariate distribution at k approximately  equally-spaced points.\n\nRef: http://www.jmlr.org/papers/volume11/ben-haim10a/ben-haim10a.pdf\n\nExample\n\no = fit!(KHist(25), randn(10^6))\n\n# Approximate statistics\nusing Statistics\nmean(o)\nvar(o)\nstd(o)\nquantile(o)\nmedian(o)\n\nusing Plots\nplot(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.KMeans",
    "page": "API",
    "title": "OnlineStats.KMeans",
    "category": "type",
    "text": "KMeans(p, k; rate=LearningRate(.6))\n\nApproximate K-Means clustering of k clusters and p variables.\n\nExample\n\nclusters = rand(Bool, 10^5)\n\nx = [clusters[i] > .5 ? randn() : 5 + randn() for i in 1:10^5, j in 1:2]\n\no = fit!(KMeans(2, 2), x)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.KahanMean",
    "page": "API",
    "title": "OnlineStats.KahanMean",
    "category": "type",
    "text": "KahanMean(; T=Float64, weight=EqualWeight())\n\nTrack a univariate mean. Uses a compensation term for the update.\n\n#Note\n\nThis should be more accurate as Mean in most cases but the guarantees of KahanSum do not apply. merge! can have some accuracy issues.\n\nUpdate\n\nμ = (1 - γ) * μ + γ * x\n\nExample\n\n@time fit!(KahanMean(), randn(10^6))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.KahanSum",
    "page": "API",
    "title": "OnlineStats.KahanSum",
    "category": "type",
    "text": "KahanSum(T::Type = Float64)\n\nTrack the overall sum. Includes a compensation term that effectively doubles precision, see Wikipedia for details.\n\nExample\n\nfit!(KahanSum(Float64), fill(1, 100))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.KahanVariance",
    "page": "API",
    "title": "OnlineStats.KahanVariance",
    "category": "type",
    "text": "KahanVariance(; T=Float64, weight=EqualWeight())\n\nTrack the univariate variance. Uses compensation terms for a higher accuracy.\n\n#Note\n\nThis should be more accurate as Variance in most cases but the guarantees of KahanSum do not apply. merge! can have accuracy issues.\n\nExample\n\no = fit!(KahanVariance(), randn(10^6))\nmean(o)\nvar(o)\nstd(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Lag",
    "page": "API",
    "title": "OnlineStats.Lag",
    "category": "type",
    "text": "Lag{T}(b::Integer)\n\nStore the last b values for a data stream of type T.  Values are stored as\n\nv(t) v(t-1) v(t-2)  v(t-b+1)\n\nExample\n\no = fit!(Lag{Int}(10), 1:12)\no[1]\no[end]\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.LinReg",
    "page": "API",
    "title": "OnlineStats.LinReg",
    "category": "type",
    "text": "LinReg()\n\nLinear regression, optionally with element-wise ridge regularization.\n\nExample\n\nx = randn(100, 5)\ny = x * (1:5) + randn(100)\no = fit!(LinReg(), (x,y))\ncoef(o)\ncoef(o, .1)\ncoef(o, [0,0,0,0,Inf])\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.LinRegBuilder",
    "page": "API",
    "title": "OnlineStats.LinRegBuilder",
    "category": "type",
    "text": "LinRegBuilder(p)\n\nCreate an object from which any variable can be regressed on any other set of variables, optionally with element-wise ridge regularization.  The main function to use with  LinRegBuilder is coef:\n\ncoef(o::LinRegBuilder, λ = 0; y=1, x=[2,3,...], bias=true, verbose=false)\n\nReturn the coefficients of a regressing column y on columns x with ridge (L2Penalty)  parameter λ.  An intercept (bias) term is added by default.\n\nExamples\n\nx = randn(1000, 10)\no = fit!(LinRegBuilder(), x)\n\ncoef(o; y=3, verbose=true)\n\ncoef(o; y=7, x=[2,5,4])\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MSPI",
    "page": "API",
    "title": "OnlineStats.MSPI",
    "category": "type",
    "text": "MSPI()\n\nMajorized Stochastic Proximal Iteration.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Mean",
    "page": "API",
    "title": "OnlineStats.Mean",
    "category": "type",
    "text": "Mean(; weight=EqualWeight())\n\nTrack a univariate mean.\n\nUpdate\n\nμ = (1 - γ) * μ + γ * x\n\nExample\n\n@time fit!(Mean(), randn(10^6))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Moments",
    "page": "API",
    "title": "OnlineStats.Moments",
    "category": "type",
    "text": "Moments(; weight=EqualWeight())\n\nFirst four non-central moments.\n\nExample\n\no = fit!(Moments(), randn(1000))\nmean(o)\nvar(o)\nstd(o)\nskewness(o)\nkurtosis(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Mosaic",
    "page": "API",
    "title": "OnlineStats.Mosaic",
    "category": "type",
    "text": "Mosaic(T::Type, S::Type)\n\nData structure for generating a mosaic plot, a comparison between two categorical variables.\n\nExample\n\nusing OnlineStats, Plots \nx = [rand() > .8 for i in 1:10^5]\ny = rand([1,2,2,3,3,3], 10^5)\no = fit!(Mosaic(Bool, Int), zip(x, y))\nplot(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MovingTimeWindow",
    "page": "API",
    "title": "OnlineStats.MovingTimeWindow",
    "category": "type",
    "text": "MovingTimeWindow{T<:TimeType, S}(window::DatePeriod)\nMovingTimeWindow(window::DatePeriod; valtype=Float64, timetype=Date)\n\nFit a moving window of data based on time stamps.  Each observation must be a Tuple, NamedTuple, or Pair where the first item is <: Dates.TimeType.  Only observations with time stamps in the range\n\nmost_recent_datetime - window = time_stamp = most_recent_datetime\n\nare kept track of.\n\nExample\n\nusing Dates\ndts = Date(2010):Day(1):Date(2011)\ny = rand(length(dts))\n\no = MovingTimeWindow(Day(4); timetype=Date, valtype=Float64)\nfit!(o, zip(dts, y))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.MovingWindow",
    "page": "API",
    "title": "OnlineStats.MovingWindow",
    "category": "type",
    "text": "MovingWindow(b, T)\nMovingWindow(T, b)\n\nTrack a moving window of b items of type T.\n\nExample\n\no = MovingWindow(10, Int)\nfit!(o, 1:14)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.NBClassifier",
    "page": "API",
    "title": "OnlineStats.NBClassifier",
    "category": "type",
    "text": "NBClassifier(p::Int, T::Type; stat = Hist(15))\n\nCalculate a naive bayes classifier for classes of type T and p predictors.  For each class K, predictor variables are summarized by the stat.\n\nExample\n\nx, y = randn(10^4, 10), rand(Bool, 10^4)\n\no = fit!(NBClassifier(10, Bool), (x,y))\ncollect(keys(o))\nprobs(o)\n\nxi = randn(10)\npredict(o, xi)\nclassify(o, xi)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAP",
    "page": "API",
    "title": "OnlineStats.OMAP",
    "category": "type",
    "text": "OMAP()\n\nOnline MM via Averaged Parameter.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OMAS",
    "page": "API",
    "title": "OnlineStats.OMAS",
    "category": "type",
    "text": "OMAS()\n\nOnline MM via Averaged Surrogate.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.OrderStats",
    "page": "API",
    "title": "OnlineStats.OrderStats",
    "category": "type",
    "text": "OrderStats(b::Int, T::Type = Float64; weight=EqualWeight())\n\nAverage order statistics with batches of size b.\n\nExample\n\no = fit!(OrderStats(100), randn(10^5))\nquantile(o, [.25, .5, .75])\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.P2Quantile",
    "page": "API",
    "title": "OnlineStats.P2Quantile",
    "category": "type",
    "text": "P2Quantile(τ = 0.5)\n\nCalculate the approximate quantile via the P^2 algorithm.  It is more computationally expensive than the algorithms used by Quantile, but also more exact.\n\nRef: https://www.cse.wustl.edu/~jain/papers/ftp/psqr.pdf\n\nExample\n\nfit!(P2Quantile(.5), rand(10^5))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Partition",
    "page": "API",
    "title": "OnlineStats.Partition",
    "category": "type",
    "text": "Partition(stat, nparts=100)\n\nSplit a data stream into nparts where each part is summarized by stat.\n\nExample\n\no = Partition(Extrema())\nfit!(o, cumsum(randn(10^5)))\n\nusing Plots\nplot(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.PlotNN",
    "page": "API",
    "title": "OnlineStats.PlotNN",
    "category": "type",
    "text": "PlotNN(b=300)\n\nApproximate scatterplot of b centers.  This implementation is too slow to be useful.\n\nExample\n\nx = randn(10^4)\ny = x + randn(10^4)\nplot(fit!(PlotNN(), zip(x, y)))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ProbMap",
    "page": "API",
    "title": "OnlineStats.ProbMap",
    "category": "type",
    "text": "ProbMap(T::Type; weight=EqualWeight())\nProbMap(A::AbstractDict{T, Float64}; weight=EqualWeight())\n\nTrack a dictionary that maps unique values to its probability.  Similar to CountMap, but uses a weighting mechanism.\n\nExample\n\no = ProbMap(Int)\nfit!(o, rand(1:10, 1000))\nprobs(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Quantile",
    "page": "API",
    "title": "OnlineStats.Quantile",
    "category": "type",
    "text": "Quantile(q = [.25, .5, .75]; alg=OMAS(), rate=LearningRate(.6))\n\nCalculate quantiles via a stochastic approximation algorithm OMAS, SGD, ADAGRAD, or MSPI.  For better (although slower) approximations, see P2Quantile and  Hist.\n\nExample\n\nfit!(Quantile(), randn(10^5))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.RMSPROP",
    "page": "API",
    "title": "OnlineStats.RMSPROP",
    "category": "type",
    "text": "RMSPROP(α = .9)\n\nA Variation of ADAGRAD that uses element-wise weights generated by an exponentially  weighted mean of the squared gradients.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.ReservoirSample",
    "page": "API",
    "title": "OnlineStats.ReservoirSample",
    "category": "type",
    "text": "ReservoirSample(k::Int, T::Type = Float64)\n\nCreate a sample without replacement of size k.  After running through n observations, the probability of an observation being in the sample is 1 / n.\n\nExample\n\nfit!(ReservoirSample(100, Int), 1:1000)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.SGD",
    "page": "API",
    "title": "OnlineStats.SGD",
    "category": "type",
    "text": "SGD()\n\nStochastic Gradient Descent.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Series",
    "page": "API",
    "title": "OnlineStats.Series",
    "category": "type",
    "text": "Series(stats)\nSeries(stats...)\nSeries(; stats...)\n\nTrack a collection stats for one data stream.\n\nExample\n\ns = Series(Mean(), Variance())\nfit!(s, randn(1000))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.StatHistory",
    "page": "API",
    "title": "OnlineStats.StatHistory",
    "category": "type",
    "text": "StatHistory(stat, b)\n\nTrack a moving window (previous b copies) of stat.\n\nExample\n\nfit!(StatHistory(Mean(), 10), 1:20)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.StatLearn",
    "page": "API",
    "title": "OnlineStats.StatLearn",
    "category": "type",
    "text": "StatLearn(p, args...; rate=LearningRate())\n\nFit a model that is linear in the parameters.  \n\nThe (offline) objective function that StatLearn approximately minimizes is\n\n(1n) ᵢ f(yᵢ xᵢβ) + ⱼ λⱼ g(βⱼ)\n\nwhere fᵢ are loss functions of a single response and linear predictor, λⱼs are  nonnegative regularization parameters, and g is a penalty function. \n\nArguments\n\nloss = .5 * L2DistLoss()\npenalty = NoPenalty()\nalgorithm = SGD()\nrate = LearningRate(.6) (keyword arg)\n\nExample\n\nx = randn(1000, 5)\ny = x * range(-1, stop=1, length=5) + randn(1000)\n\no = fit!(StatLearn(5, MSPI()), (x, y))\ncoef(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Sum",
    "page": "API",
    "title": "OnlineStats.Sum",
    "category": "type",
    "text": "Sum(T::Type = Float64)\n\nTrack the overall sum.\n\nExample\n\nfit!(Sum(Int), fill(1, 100))\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Variance",
    "page": "API",
    "title": "OnlineStats.Variance",
    "category": "type",
    "text": "Variance(; weight=EqualWeight())\n\nUnivariate variance.\n\nExample\n\no = fit!(Variance(), randn(10^6))\nmean(o)\nvar(o)\nstd(o)\n\n\n\n\n\n"
},

{
    "location": "api.html#StatsBase.confint",
    "page": "API",
    "title": "StatsBase.confint",
    "category": "function",
    "text": "confint(b::Bootstrap, coverageprob = .95)\n\nReturn a confidence interval for a Bootstrap b.\n\n\n\n\n\n"
},

{
    "location": "api.html#OnlineStats.Part",
    "page": "API",
    "title": "OnlineStats.Part",
    "category": "type",
    "text": "Part(stat, a, b)\n\nstat summarizes a Y variable over an X variable\'s range a to b.\n\n\n\n\n\n"
},

{
    "location": "api.html#API-1",
    "page": "API",
    "title": "API",
    "category": "section",
    "text": "Modules = [OnlineStats]"
},

]}
