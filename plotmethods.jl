# Boxplot from FiveNumberSummary
function Gadfly.plot(obj::FiveNumberSummary)
    s = state(obj)[1:5, 2]
    iqr = obj.quantile.est[3] - obj.quantile.est[1]
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
