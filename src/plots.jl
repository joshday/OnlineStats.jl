#--------------------------------------------------------------------------# map_rows
"""
Perform operations on data in blocks.

`map_rows(f::Function, b::Integer, data...)`

This function iteratively feeds the `f` blocks of `b` observations from `data`.
The most common usage is with `do` blocks:

```julia
# Example 1
y = randn(50)
o = Variance()
map_rows(10, y) do yi
    fit!(o, yi)
    println("Updated with another batch!")
end
display(o)

# Example 2
x = randn(100, 5)
y = randn(100)
o = LinReg(x, y)
map_rows(10, x, y) do xi, yi
    fit!(o, xi, yi)
    println("Updated with another batch!")
end
display(o)
```
"""
function map_rows(f::Function, b::Integer, data...)
    n = size(data[1], 1)
    i = 1
    while i <= n
        rng = i:min(i + b - 1, n)
        batch_data = map(x -> rows(x, rng), data)
        f(batch_data...)
        i += b
    end
end


#--------------------------------------------------------------# plot of coefficients
RecipesBase.@recipe function f(o::OnlineStat{XYInput})
    β = coef(o)
    nonzero = collect(β .== 0)
    mylegend = length(unique(nonzero)) > 1
    x = 1:length(β)
    try
        if o.intercept  # if intercept, make indices start at 0
            x -= 1
        end
    end
    seriestype --> :scatter
    legend --> mylegend
    group --> nonzero
    label --> ["Nonzero" "Zero"]
    ylabel --> "Value"
    xlims --> (minimum(x) - 1, maximum(x) + 1)
    xlabel --> "Index of Coefficient Vector"
    x, β
end
