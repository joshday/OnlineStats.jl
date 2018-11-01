using OnlineStats, Plots, Colors, Random, CSV
gr()
Random.seed!(123)

#-----------------------------------------------------------------------# readme plot
@info "Plot 1"
y = cumsum(randn(10^6)) + 100randn(10^6)
o = Partition(KHist(10))
fit!(o, y)
p1 = plot(o)

@info "Plot 2"
p2 = plot(
    plot(fit!(KHist(50), y[1:5_000])),
    plot(fit!(KHist(50), y[1:200_000])),
    plot(fit!(KHist(50), y[1:500_000])),
    plot(fit!(KHist(50), y))
)

@info "Plot 3"
p3 = plot(fit!(PlotNN(200), randn(10^5, 2)), colorbar=false)


@info "Plot 4"
df = CSV.read("/Users/joshday/datasets/diamonds.csv"; allowmissing=:none)
o = Partition(CountMap(String), 75)
p4 = plot(fit!(o, string.(df[:cut])), ylim = (0, df[1][end]))

@info "Joining Plots"
p = plot(p1, p2, p4, p3; xaxis=false, yaxis=false,xticks=[], yticks=[], size=(1000,800), legend=false)
png("/Users/joshday/Desktop/readme.png")
p

# #-----------------------------------------------------------------------# logo
# x = [0. 10. 20.]
# a = @animate for i in 0:.2:30
#     scatter(
#         mod.(x + i, 30), zeros(1, 3), ylim = (-.5, .5), xlim = (3, 20),
#         ms = 50,
#         # green, red, purple
#         color = [RGB(.22,.596,.149) RGB(.8,.361,.361) RGB(.702, .322, .8)],
#         markerstrokewidth = 10,
#         markerstrokecolor = [RGB(.133, .541, .133) RGB(.8, .2, .2) RGB(.584, .345, .698)],
#         grid = false, axis = false, legend = false
#     )
# end
# gif(a, @__DIR__() * "/logo.gif", fps=100)

#-----------------------------------------------------------------------# Weight animation
# n = 100
# Random.seed!(123)
# y = .5cumsum(rand(n)) + 3randn(n)

# s1 = Series(EqualWeight(),              Mean())
# s2 = Series(ExponentialWeight(.1),      Mean())
# s3 = Series(Bounded(EqualWeight(), .1), Mean())
# s4 = Series(LearningRate(.6),           Mean())
# s5 = Series(HarmonicWeight(10.),        Mean())
# s6 = Series(McclainWeight(.1),          Mean())

# p = plot(zeros(0), zeros(0, 7), seriestype = [:scatter :line :line :line :line :line :line], w=1,
#     label = ["data" "EqualWeight" "ExponentialWeight(.1)" "Bounded(EqualWeight(), .1)" "LearningRate(.6)" "HarmonicWeight(10)" "McclainWeight(.1)"], ms=2, linestyle=:auto,
#     grid=false, legend = :topleft, xlab = "Number of Observations", title="Means",
#     palette = :darktest, ylim = (-5, 30))

# s = [s1, s2, s3, s4, s5, s6]
# a = @animate for yi in y
#     for si in s
#         fit!(si, yi)
#     end
#     vals = vcat(yi, map(x -> value(x)[1], s)...)
#     # @show typeof(vals)
#     push!(p, nobs(s1), vals)
# end

# gif(a, @__DIR__() * "/weights.gif")


#-----------------------------------------------------------------------# readme animation
# Updated 3/31/18
# n = 100
# Random.seed!(123)
# y = .5cumsum(rand(n)) + 3randn(n)

# o1 = Mean()
# o2 = Mean(weight = x -> .1)
# p = plot(zeros(0), zeros(0, 3), seriestype = [:scatter :line :line], w=3,
#     label = ["data", "equally weighted", "exponentially weighted"],
#     grid=false, legend = :topleft, xlab = "Number of Observations",
#     title = "Means", ylim = (-5, 30), color = :viridis
# )

# a = @animate for yi in y
#     fit!(o1, yi)
#     fit!(o2, yi)
#     push!(p, nobs(o1), vcat(yi, value(o1), value(o2)))
# end

# gif(a, "/Users/joshday/Desktop/readme.gif")




#-----------------------------------------------------------------------# weight
# p1 = plot(EqualWeight())
# p2 = plot(ExponentialWeight(.1))
# p3 = plot(BoundedEqualWeight(.1))
# p4 = plot(LearningRate())
# p5 = plot(HarmonicWeight())
# p6 = plot(McclainWeight())
#
# p = plot(p1, p2, p3, p4, p5, p6, size = (1200, 800), legendfont = font(12))
#
# png(p, @__DIR__() * "/weights.png")


#-----------------------------------------------------------------------# Logo
# o = fit!(Partition(KHist(8)), sin.(0:.001:2π) + .4randn(length(0:.001:2π)))
# p = plot(o, color = :viridis, grid=false, axis=false, legend=false, ms=4
# png(p, "/Users/joshday/Desktop/logo.png")