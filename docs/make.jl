using Documenter, OnlineStats, OnlineStatsBase

makedocs(
    format = :html,
    sitename = "OnlineStats.jl",
    authors = "Josh Day",
    clean = true,
    doctest = false,
    pages = [
        "pages/index.md",
        "pages/weights.md",
        "pages/series.md",
        "pages/whatcan.md",
        "pages/api.md",
        "pages/newstats.md"
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
