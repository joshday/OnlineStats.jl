using Documenter, OnlineStats, OnlineStatsBase

makedocs(
    format = :html,
    sitename = "OnlineStats.jl",
    authors = "Josh Day",
    clean = true,
    pages = [
        "index.md",
        "collectionstats.md",
        "weights.md",
        "stats_and_models.md",
        "parallel.md",
        "datasurrogates.md",
        "visualizations.md",
        "demos.md",
        "api.md",
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
