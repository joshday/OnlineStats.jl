module TestSetup
export @title, @subtitle
macro title(s)
    return :("■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■ " * $s)
end
macro subtitle(s)
    return :("████████████████████████████████████████████████ " * $s)
end
end


include("testfiles/messy_output_test.jl")
include("testfiles/multivariate_test.jl")
include("testfiles/plots_test.jl")
include("testfiles/summary_test.jl")
include("testfiles/weight_test.jl")
include("testfiles/distributions_test.jl")
include("testfiles/modeling_test.jl")
include("testfiles/statlearn_test.jl")
include("testfiles/streamstats_test.jl")
