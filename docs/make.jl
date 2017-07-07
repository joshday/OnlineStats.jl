using Documenter, OnlineStats

makedocs(
    format = :html,
    sitename = "OnlineStats.jl",
    authors = "Josh Day",
    clean = true,
    pages = [
        "index.md",
        "pages/types.md",
        "pages/api.md"
    ]
)

deploydocs(
    repo   = "github.com/joshday/OnlineStats.jl.git",
    target = "build",
    osname = "linux",
    julia  = "0.6",
    deps   = nothing,
    make   = nothing
)
