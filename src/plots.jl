export coefplot, TracePlot, CompareTracePlot


RecipesBase.@recipe function plot(o::OnlineStat{XYInput})
    β = coef(o)
    nonzero = collect(β .== 0)
    mylegend = length(unique(nonzero)) > 1
    x = 1:length(β)
    try
        if o.intercept  # if intercept, make indices start at 0
            x -= 1
        end
    end
    :linetype --> :scatter
    :legend --> mylegend
    :group --> nonzero
    :label --> ["Nonzero" "Zero"]
    :ylabel --> "Value"
    :xlims --> (minimum(x) - 1, maximum(x) + 1)
    :xlabel --> "Index of Coefficient Vector"
    x, β
end


# abstract MetaOnlineStat <: OnlineStat
# fit!(o::MetaOnlineStat, args...) = fit!(o.o, args...)
# updatecounter!(o::MetaOnlineStat) = updatecounter!(o.o)
# value(o::MetaOnlineStat) = value(o.o)
# nobs(o::MetaOnlineStat) = nobs(o.o)
#
# type TracePlot{O <: OnlineStat, N} <: MetaOnlineStat
#     o::O
#     f::Function
#     values::Array{Float64, N}
# end
# function TracePlot(o::OnlineStat, f::Function = value, res::Int = 200)
#     init = f(o)
#     dims = tuple(size(init)..., 2 * res)
#     TracePlot(o, f, zeros(dims))
# end




#
# #--------------------------------------------------------------------# TracePlot
# """
# `TracePlot(o::OnlineStat, f::Function = value)`
#
# Create a trace plot using values from OnlineStat `o`.  Every call to `fit!(o, args...)`
# adds a new observation to the plot.
#
# ```julia
# using Plots
# o = Mean(ExponentialWeight(.1))
# tr = TracePlot(o)
# for i in 1:100
#     fit!(tr, i / 100 + randn(100))
# end
#
# o = Variance()
# tr = TracePlot(o, x -> [mean(o), var(o)])
# for i in 1:100
#     fit!(tr, randn(100))
# end
# ```
# """
# type TracePlot <: OnlineStat
#     o::OnlineStat
#     p::Plots.Plot
#     f::Function
# end
#
# function TracePlot(o::OnlineStats.OnlineStat, f::Function = value; kw...)
#     p = Plots.plot([nobs(o)], collect(f(o))';
#         xlabel = "nobs",
#         ylabel = "value of function $f",
#         kw...)
#     TracePlot(o, p, f)
# end
#
# function fit!(tr::TracePlot, args...)
#     fit!(tr.o, args...)
#     push!(tr.p, nobs(tr.o), collect(tr.f(tr.o)))
# end
#
# Plots.plot(tr::TracePlot) = tr.p
# nobs(tr::TracePlot) = nobs(tr.o)
# value(tr::TracePlot) = value(tr.o)
#
# #-------------------------------------------------------------# CompareTracePlot
# """
# Compare the values of multiple OnlineStats.  Useful for comparing competing models.
#
# ```julia
# o1 = StatLearn(size(x, 2), SGD())
# o2 = StatLearn(size(x, 2), AdaGrad())
# tr = CompareTracePlot([o1, o2], o -> loss(o, x, y))
# fit!(o1, x1, y1); fit!(o2, x1, y1)
# fit!(o1, x2, y2); fit!(o2, x2, y2)
# ...
# ```
# """
# type CompareTracePlot
#     os::Vector
#     p::Plots.Plot
#     f::Function  # Use a function that returns a scalar
# end
#
# function CompareTracePlot(os::Vector, f::Function; kw...)
#     p = Plots.plot(
#         Float64[nobs(oi) for oi in os]',   # x
#         Float64[f(oi) for oi in os]';      # y
#         ylabel = "value of function $f", xlabel = "nobs", kw...
#     )
#     CompareTracePlot(os, p, f)
# end
#
# function fit!(c::CompareTracePlot, args...)
#     for o in c.os
#         fit!(o, args...)
#     end
#     for i in 1:length(c.os)
#         push!(c.p, i, nobs(c.os[i]), c.f(c.os[i]))
#     end
# end
#
# Plots.plot(c::CompareTracePlot) = c.p
