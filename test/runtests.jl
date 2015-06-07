module OnlineStatsTests
using FactCheck

include("common_test.jl")
include("mean_test.jl")
include("var_test.jl")
 include("summary_test.jl")
 include("extrema_test.jl")
#  include("moments_test.jl")
 include("quantiles_test.jl")

 include("linearmodel_test.jl")
 include("sweep_test.jl")
 include("quantreg_test.jl")

 include("distribution_test.jl")
 include("normalmix_test.jl")

 include("covmatrix_test.jl")
 include("analyticalpca_test.jl")

include("plotmethods_test.jl")

FactCheck.exitstatus()
end # module

