module OnlineStatsTests
using FactCheck

@time include("mean_test.jl")
@time include("var_test.jl")
@time include("summary_test.jl")
@time include("extrema_test.jl")
# @time include("moments_test.jl")
@time include("quantiles_test.jl")

@time include("linearmodel_test.jl")
@time include("sweep_test.jl")
@time include("quantreg_test.jl")

@time include("distribution_test.jl")
@time include("normalmix_test.jl")

@time include("covmatrix_test.jl")
@time include("analyticalpca_test.jl")

FactCheck.exitstatus()
end # module

