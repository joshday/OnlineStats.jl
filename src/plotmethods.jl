# Stopped importing Gadfly to speed up interactive development.  Here
# are the Gadfly.plot methods for various types.

#----------------------------------------------# Boxplot from FiveNumberSummary
function Gadfly.plot(o::OnlineStats.FiveNumberSummary)
    s = OnlineStats.state(o)
    iqr = s[4] - s[2]
    Gadfly.plot(
        Gadfly.layer(lower_fence = [maximum((s[2] - 1.5 * iqr, s[1]))],
              lower_hinge = [s[2]],
              middle = [s[3]],
              upper_hinge = [s[4]],
              upper_fence = [minimum((s[4] + 1.5 * iqr, s[5]))],
              # outliers = [s[1], s[5]],
              x = ["Data"], Gadfly.Geom.boxplot),
        Gadfly.layer(x = ["Data"], y=[s[1], s[5]], Gadfly.Geom.point))
end


#--------------------------------------------------------------# Normal Mixture
function Gadfly.plot(o::MixtureModel{Univariate, Continuous, Normal}, a::Int, b::Int,
                     args...)
    plotvec = [x -> pdf(o, x)]
    legendvec = ["Mixture"]

    for j in 1:length(components(o))
        plotvec = [plotvec; x -> probs(o)[j] * pdf(components(o)[j], x)]
        legendvec = [legendvec; ["Component $j"]]
    end

    Gadfly.plot(plotvec, a, b, color = repeat(legendvec), args...)
end


#----------------------------------------# Normal Mixture overlaid on histogram
function Gadfly.plot(o::MixtureModel{Univariate, Continuous, Normal}, x::Vector,
                     args...)
    a = maximum(x)
    b = minimum(x)
    xvals = linspace(a, b, 1000)
    yvals = pdf(o, xvals)
    Gadfly.plot(Gadfly.layer(x = xvals, y = yvals, Gadfly.Geom.line, order = 1,
        Gadfly.Theme(default_color = Gadfly.color("black"))),
        Gadfly.layer(x = x, Gadfly.Geom.histogram(density = true), order = 0),
                args...)
end
