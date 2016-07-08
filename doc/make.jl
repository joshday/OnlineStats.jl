module MakeOnlineStatsDocs
reload("OnlineStats")
using OnlineStats

rootdir = Pkg.dir("OnlineStats")

#-------------------------------------------------------------------# Generate api.md
api = rootdir * "/doc/api.md"
rm(api)
touch(api)
file = open(api, "r+")
write(file, "<!--- Generated at " * string(now()) * ".  Don't edit --->\n")
write(file, "# API\n\n")
info("The following items are included in the output file:\n")
nms = setdiff(names(OnlineStats), [:OnlineStats])  # Vector{Symbol} of names
for nm in nms
    @eval obj = OnlineStats.$nm
    d = Docs.doc(obj)
    if d != nothing
        println(nm)
        write(file, "## " * string(nm) * "\n" * Markdown.plain(d) * "\n")
    end
end
close(file)


#----------------------------------------------------------------# Figure for Weights
# info("Figure for Weights")
# using Plots; pyplot()
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
# png(plt_wt, rootdir * "/doc/images/weights.png")

#-------------------------------------------------------------# push site to gh-pages
cd(rootdir)
run(`mkdocs gh-deploy --clean`)
end  # MakeOnlineStatsDocs
