module OnlineStatsTests
FactCheck.clear_results()

sev = OnlineStats.log_severity()
OnlineStats.log_severity!(OnlineStats.ErrorSeverity)  # turn off most logging

include("distributions_test/distribution_test.jl")
include("distributions_test/normalmix_test.jl")

include("matrix_test/matrix_test.jl")

include("linearmodel_test/linearmodel_test.jl")
include("linearmodel_test/sweep_test.jl")
include("linearmodel_test/quantregmm_test.jl")
include("linearmodel_test/logreg_test.jl")
include("linearmodel_test/opca_test.jl")
include("linearmodel_test/ofls_test.jl")

include("summary_test/mean_test.jl")
include("summary_test/var_test.jl")
include("summary_test/summary_test.jl")
include("summary_test/extrema_test.jl")
include("summary_test/moments_test.jl")
include("summary_test/fivenumber_test.jl")
include("summary_test/quantiles_test.jl")

include("multivariate_test/covmatrix_test.jl")

include("streamstats_test/bootstrap_test.jl")
include("streamstats_test/hyperloglog_test.jl")

include("stochasticmodel_test/stochasticmodel_test.jl")
include("stochasticmodel_test/sgd_test.jl")
include("stochasticmodel_test/proxgrad_test.jl")
include("stochasticmodel_test/rda_test.jl")
include("stochasticmodel_test/mmgrad_test.jl")
include("stochasticmodel_test/cv_test.jl")
include("stochasticmodel_test/sparse_test.jl")

include("common_test.jl")
include("react_test.jl")
include("plot_test.jl")



# put logging back the way it was
OnlineStats.log_severity!(sev)

FactCheck.exitstatus()

end # module
