using Documenter, OnlineStats, OnlineStatsBase

makedocs(
    format = :html,
    sitename = "OnlineStats.jl",
    authors = "Josh Day",
    clean = true,
    pages = [
        "index.md",
        "weights.md",
        "series.md",
        "whatcan.md",
        "api.md",
        "newstats.md"
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
