using OnlineStats, Plots, PlotThemes, Colors, Random, CSV
gr()
theme(:juno)
Random.seed!(123)

logo_colors = hcat(
    RGB(135/255, 222/255, 183/255),  # not in logo
    RGB(64/255, 191/255, 169/255),
    RGB(64/255, 169/255, 191/255),
    RGB(64/255, 124/255, 191/255),
    RGB(64/255, 79/255, 191/255),
)

# #-----------------------------------------------------------------------# readme plot
# @info "Plot 1"
# y = cumsum(randn(10^6)) + 100randn(10^6)
# o = Partition(KHist(10))
# fit!(o, y)
# p1 = plot(o)

# @info "Plot 2"
# p2 = plot(
#     plot(fit!(KHist(50), y[1:5_000])),
#     plot(fit!(KHist(50), y[1:200_000])),
#     plot(fit!(KHist(50), y[1:500_000])),
#     plot(fit!(KHist(50), y))
# )

# @info "Plot 3"
# p3 = plot(fit!(PlotNN(200), randn(10^5, 2)), colorbar=false)


# @info "Plot 4"
# df = CSV.read("/Users/joshday/datasets/diamonds.csv"; allowmissing=:none)
# o = Partition(CountMap(String), 75)
# p4 = plot(fit!(o, string.(df[:cut])), ylim = (0, df[1][end]))

# @info "Joining Plots"
# p = plot(p1, p2, p4, p3; xaxis=false, yaxis=false,xticks=[], yticks=[], size=(1000,800), legend=false)
# png("/Users/joshday/Desktop/readme.png")
# p

#-----------------------------------------------------------------------# Weight animation
# n = 100
# Random.seed!(123)
# y = .5cumsum(rand(n)) + 3randn(n)

# os = (
#     Mean(weight = EqualWeight()),
#     Mean(weight = ExponentialWeight(.1)),
#     Mean(weight = LearningRate(.6)),
#     Mean(weight = HarmonicWeight(10.)),
#     Mean(weight = McclainWeight(.1))
# )



# p = plot(zeros(0), zeros(0, 6), seriestype = [:scatter :line :line :line :line :line], w=3,
#     label = ["data" "EqualWeight" "ExponentialWeight(.1)" "LearningRate(.6)" "HarmonicWeight(10)" "McclainWeight(.1)"], ms=3,
#     linestyle=:auto,
#     grid=false, legend = :topleft, xlab = "Number of Observations", title="Means",
#     color = hcat(:black, logo_colors...), ylim = (-5, 30))

# a = @animate for yi in y
#     for o in os
#         fit!(o, yi)
#     end
#     vals = vcat(yi, map(x -> value(x)[1], os)...)
#     push!(p, nobs(os[1]), vals)
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
p1 = plot(EqualWeight())
p2 = plot(ExponentialWeight(.1))
p4 = plot(LearningRate())
p5 = plot(HarmonicWeight())
p6 = plot(McclainWeight())

p = plot(p1, p2, p4, p5, p6, size = (1200, 800), font = font("Bangla MN", 12), linecolor=logo_colors[2])

png(p, @__DIR__() * "/weights.png")


#-----------------------------------------------------------------------# Logo
# o = fit!(Partition(KHist(8)), sin.(0:.001:2π) + .4randn(length(0:.001:2π)))
# p = plot(o, color = :viridis, grid=false, axis=false, legend=false, ms=4
# png(p, "/Users/joshday/Desktop/logo.png")