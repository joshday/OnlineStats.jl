# Josh: I stopped importing Gadfly to speed up interactive development.  Here
# are the Gadfly.plot methods that I've done.

#----------------------------------------------# Boxplot from FiveNumberSummary
# function Gadfly.plot(obj::OnlineStats.FiveNumberSummary)
#     s = OnlineStats.state(obj)[:value]
#     iqr = s[3] - s[1]
#     Gadfly.plot(
#         Gadfly.layer(lower_fence = [maximum((s[2] - 1.5 * iqr, s[1]))],
#               lower_hinge = [s[2]],
#               middle = [s[3]],
#               upper_hinge = [s[4]],
#               upper_fence = [minimum((s[4] + 1.5 * iqr, s[5]))],
#               # outliers = [s[1], s[5]],
#               x = ["Data"], Gadfly.Geom.boxplot),
#         Gadfly.layer(x = ["Data"], y=[s[1], s[5]], Gadfly.Geom.point))
# end


#--------------------------------------------------------------# Normal Mixture
function Gadfly.plot(obj::MixtureModel{Univariate, Continuous, Normal}, a, b;
                     args...)
    plotvec = [x -> pdf(obj, x)]
    legendvec = ["Mixture"]

    for j in 1:length(components(obj))
        plotvec = [plotvec; x -> probs(obj)[j] * pdf(components(obj)[j], x)]
        legendvec = [legendvec; ["Component $j"]]
    end

    Gadfly.plot(plotvec, a, b, color = repeat(legendvec), args...)
end


#----------------------------------------# Normal Mixture overlaid on histogram
function Gadfly.plot(obj::MixtureModel{Univariate, Continuous, Normal}, x;
                     args...)
    a = maximum(x)
    b = minimum(x)
    xvals = a:(b-a)/1000:b
    yvals = pdf(obj, xvals)
    Gadfly.plot(Gadfly.layer(x = xvals, y=yvals, Gadfly.Geom.line, order = 1,
        Gadfly.Theme(default_color = Gadfly.color("black"))),
        Gadfly.layer(x = x, Gadfly.Geom.histogram(density = true), order = 0))
end
