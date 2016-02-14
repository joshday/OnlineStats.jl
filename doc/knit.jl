module KnitDocs


import OnlineStats, Plots
O = OnlineStats


function knit(mod::Module, dest::AbstractString = Pkg.dir(string(mod), "doc/api.md"))
    nms = names(mod)
    nms = setdiff(nms, [symbol(mod)])  # hack to avoid including README
    touch(dest)
    file = open(dest, "r+")

    write(file, "# API for " * string(mod) * "\n\n")
    write(file, "# Table of Contents\n")

    # Make TOC
    for nm in nms
        obj = eval(parse("$mod.$nm"))   # Get identifier (OnlineStats.AdaDelta)
        if Docs.doc(obj) != nothing     # If there is documentation for the identifier:
            objtype = typeof(obj)       # get type
            if objtype == DataType      # if DataType, get supertype
                objsuper = super(obj)
                superstring = replace(string(objsuper), string(mod) * ".", "")
                write(file, "1. [$nm (<: $superstring)](#$(lowercase(string(nm))))\n")
            else
                write(file, "1. [$nm (<: $objtype)](#$(lowercase(string(nm))))\n")
            end
        end
    end
    write(file, "\n")

    # Fill in docs
    print_with_color(:blue, "The following items are included in the output file:\n")
    for nm in nms
        d = Docs.doc(eval(parse("$mod.$nm")))
        if d != nothing
            println(nm)
            write(file, "# " * string(nm) * "\n")
            write(file, Markdown.plain(d))
            write(file, "\n")
        end
    end

    close(file)
end

end # module


KnitDocs.knit(OnlineStats)
