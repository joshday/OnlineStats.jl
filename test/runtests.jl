module OnlineStatsTests

import OnlineStats
import FactCheck
FactCheck.clear_results()

sev = OnlineStats.log_severity()
OnlineStats.log_severity!(OnlineStats.ErrorSeverity)  # turn off most logging

include("common_test.jl")
include("mean_test.jl")
include("var_test.jl")
include("summary_test.jl")
include("extrema_test.jl")
include("moments_test.jl")
include("fivenumber_test.jl")
include("quantiles_test.jl")

include("linearmodel_test.jl")
include("sweep_test.jl")
include("quantregmm_test.jl")
include("logreg_test.jl")

include("distribution_test.jl")
include("normalmix_test.jl")

include("covmatrix_test.jl")
include("opca_test.jl")


include("bootstrap_test.jl")
include("ofls_test.jl")
include("adagrad_test.jl")
include("sgd_test.jl")

include("react_test.jl")

# put logging back the way it was
OnlineStats.log_severity!(sev)

FactCheck.exitstatus()

end # module
