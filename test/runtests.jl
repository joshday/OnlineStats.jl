module OnlineStatsTests
using FactCheck

@time include("mean_test.jl")
# @time include("var_test.jl")
# @time include("summary_test.jl")
@time include("extrema_test.jl")
# @time include("moments_test.jl")
# @time include("quantilesgd_test.jl")
# @time include("quantilemm_test.jl")

# @time include("linearmodel_test.jl")
@time include("sweep_test.jl")

# @time include("quantregmm_test.jl")
# @time include("quantregsgd_test.jl")

@time include("distribution_test.jl")

# @time include("covmatrix_test.jl")

FactCheck.exitstatus()
end # module

