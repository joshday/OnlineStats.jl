

# try
#     import Plots
#
#     function Plots.plot(o::OnlineStat; kw...)
#         Plots.plot([nobs(o)], vcat(state(o)[1])', kw...)
#     end
#
#     function update!(o::OnlineStat, args...; plot::Plots.Plot = Plots.current(), plotkw...)
#         update!(o, args...)
#         push!(plot, nobs(o), vcat(state(o)[1]); plotkw...)
#     end
# function Plots.plot(o::StochasticModel)
#     x = 1:length(coef(o))
#     if o.intercept
#         x -= 1
#     end
#     nonzero = collect(coef(o) .== 0)
#     if length(unique(nonzero)) > 1
#         mylegend = true
#     else
#         mylegend = false
#     end
#     Plots.scatter(x, coef(o), group = nonzero, legend = mylegend, xlabel = "β", ylabel = "value",
#         xlims = extrema(x), yticks = [0], lab = ["nonzero" "zero"])
# end
# end
