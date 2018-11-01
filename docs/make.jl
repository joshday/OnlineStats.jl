using Documenter, OnlineStats, OnlineStatsBase

makedocs(
    modules = [OnlineStats, OnlineStatsBase],
    format = [:html],
    sitename = "OnlineStats.jl",
    authors = "Josh Day",
    clean = true,
    debug = true,
    pages = [
        "index.md",
        "collectionstats.md",
        "weights.md",
        "howfitworks.md",
        "stats_and_models.md",
        "parallel.md",
        "visualizations.md",
        "demos.md",
        "api.md",
    ]
)

deploydocs(
    repo   = "github.com/joshday/OnlineStats.jl.git",
    target = "build",
    osname = "linux",
    julia  = "1.0",
    deps   = nothing,
    make   = nothing
)
