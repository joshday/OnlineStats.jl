#--------------------------------------------------------------# plot of coefficients
@recipe function f(o::OnlineStat{XYInput})
    β = coef(o)
    nonzero = collect(β .== 0)
    x = 1:length(β)
    try
        if o.intercept  # if intercept, make indices start at 0
            x -= 1
        end
    end
    seriestype --> :scatter
    legend --> length(unique(nonzero)) > 1
    group --> nonzero
    label --> ["Nonzero" "Zero"]
    ylabel --> "Value"
    xlims --> (minimum(x) - 1, maximum(x) + 1)
    xlabel --> "Index of Coefficient Vector"
    x, β
end
