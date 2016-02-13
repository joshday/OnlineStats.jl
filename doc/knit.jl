module KnitDocs


import OnlineStats


function knit(mod::Module, dest::AbstractString = Pkg.dir(string(mod), "doc/api.md"))
    nms = names(mod)
    nms = setdiff(nms, [symbol(mod)])  # hack to avoid including README
    touch(dest)
    file = open(dest, "r+")

    write(file, "# API for " * string(mod) * "\n\n")
    write(file, "---\n")
    write(file, "# Table of Contents")

    for nm in nms
        d = Docs.doc(eval(parse(string(mod) * "." * string(nm))))
        if typeof(d) != Void
            write(file, "1. [$nm](#$nm)\n")
        end
    end

    print_with_color(:blue, "The following items are included in the output file:\n")
    for nm in nms
        d = Docs.doc(eval(parse(string(mod) * "." * string(nm))))
        if typeof(d) != Void
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
