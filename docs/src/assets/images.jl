
using OnlineStats, Plots, Colors

#-----------------------------------------------------------------------# logo
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
#
# gif(a, @__DIR__() * "/logo.gif", fps=100)

#-----------------------------------------------------------------------# readme animation
n = 100
srand(123)
y = .5cumsum(rand(n)) + 3randn(n)

s1 = Series(EqualWeight(), Mean())
s2 = Series(ExponentialWeight(), Mean())
p = plot(zeros(0), zeros(0, 3), seriestype = [:scatter :line :line], w=4,
    label = ["data" "EqualWeight" "ExponentialWeight(.1)"],
    grid=false, legend = :topleft, xlab = "Number of Observations", title="Means",
    color = [:black :darkblue :darkred], ylim = (-5, 30))

a = @animate for yi in y
    fit!(s1, yi)
    fit!(s2, yi)
    push!(p, nobs(s1), vcat(yi, value(s1), value(s2)))
end

gif(a, @__DIR__() * "/readme.gif")




#-----------------------------------------------------------------------# weight
p1 = plot(EqualWeight())
p2 = plot(ExponentialWeight(.1))
p3 = plot(BoundedEqualWeight(.1))
p4 = plot(LearningRate())
p5 = plot(HarmonicWeight())
p6 = plot(McclainWeight())

p = plot(p1, p2, p3, p4, p5, p6, size = (1200, 800), legendfont = font(12))

png(p, @__DIR__() * "/weights.png")
