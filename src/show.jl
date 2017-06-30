# Ex:  `name(randn(5))`         prints `Array{Float64, 1}`
# Ex:  `name(randn(5), false)`  prints `Array`
function name(o, withparams = true)
    s = replace(string(typeof(o)), "OnlineStats.", "")
    if !withparams
        s = replace(s, r"\{(.*)", "")
    end
    s
end


# second line, the weight
function print_weight(io::IO, W)
    print(io, "┣━━ ")
    println(io, W)
end
