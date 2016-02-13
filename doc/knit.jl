module KnitDocs


import OnlineStats

"""
knit(mod, dest)
"""
function knit(mod::Module, dest::AbstractString = Pkg.dir(string(mod), "doc/api.md"))
    nms = names(mod)
    touch(dest)
    file = open(dest, "r+")
    write(file, "# API for " * string(mod) * "\n\n")
    print_with_color(:blue, "The following items are included in the output file:\n")

    for nm in setdiff(nms, [symbol(mod)])  # hack to avoid including README
        d = Docs.doc(eval(parse(string(mod) * "." * string(nm))))
        if typeof(d) != Void
            println(nm)
            write(file, "### " * string(nm) * "\n")
            write(file, Markdown.plain(d))
            write(file, "\n")
        end
    end

    close(file)
end

end # module


KnitDocs.knit(OnlineStats)
