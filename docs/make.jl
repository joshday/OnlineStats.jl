using Documenter, OnlineStats, OnlineStatsBase

makedocs(
    format = Documenter.HTML(
        assets = ["assets/style.css", "assets/favicon.ico"], 
        sidebar_sitename=false
    ),
    sitename = "OnlineStats Docs",
    modules = [OnlineStats, OnlineStatsBase],
    authors = "Josh Day",
    clean = true,
    debug = true,
    pages = [
        "index.md",
        "weights.md",
        "stats_and_models.md",
        "bigdata.md",
        "dataviz.md",
        "howfitworks.md",
        "api.md",
    ]
)

deploydocs(
    repo   = "github.com/joshday/OnlineStats.jl.git"
)
