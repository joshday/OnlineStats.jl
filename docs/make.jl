using Documenter, OnlineStats, OnlineStatsBase

makedocs(
    format = Documenter.HTML(),
    sitename = "OnlineStats.jl",
    authors = "Josh Day",
    clean = true,
    debug = true,
    pages = [
        "index.md",
        "weights.md",
        "stats_and_models.md",
        "parallel.md",
        "plots.md",
        "howfitworks.md",
        "api.md",
    ]
)

deploydocs(
    repo   = "github.com/joshday/OnlineStats.jl.git"
)
