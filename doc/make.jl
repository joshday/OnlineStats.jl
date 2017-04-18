module MakeOnlineStatsDocs
using OnlineStats



#-------------------------------------------------------------------# Generate api.md
using APIGenerator
make_api("OnlineStats", Pkg.dir("OnlineStats", "doc", "api.md"); readme=false)



#----------------------------------------------------------------# Figure for Weights
# info("Figure for Weights")
# using Plots; gr()
# o1 = EqualWeight()
# o2 = ExponentialWeight(.2)
# o3 = BoundedEqualWeight(.2)
# o4 = LearningRate(.5)
# ovec = [o1, o2, o3, o4]
# map(OnlineStats.updatecounter!, ovec)
#
# plt_wt = plot([0], map(OnlineStats.weight, ovec)', w = 3,
# label = ["EqualWeight" "ExponentialWeight(.2)" "BoundedEqualWeight(.2)" "LearningRate(.5)"],
# xlabel = "nobs", ylabel = "weight value", layout = 4, ylims = (0, 1))
# for i in 1:50
#     for o in ovec
#         OnlineStats.updatecounter!(o)
#     end
#     push!(plt_wt, nobs(o1), map(OnlineStats.weight, ovec))
# end
# png(plt_wt, "/Users/joshday/Desktop/weights.png")

#-------------------------------------------------------------# push site to gh-pages
# cd(Pkg.dir("OnlineStats"))
# run(`mkdocs gh-deploy --clean`)
end  # MakeOnlineStatsDocs
