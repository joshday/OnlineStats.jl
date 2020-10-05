using Documenter, OnlineStats, OnlineStatsBase

makedocs(
    format = Documenter.HTML(
        assets = ["assets/style.css", "assets/favicon.ico"], 
        sidebar_sitename=false,
        analytics="UA-72795550-5"
    ),
    sitename = "OnlineStats Docs",
    modules = [OnlineStats, OnlineStatsBase],
    authors = "Josh Day",
    clean = true,
    debug = true,
    pages = [
        "index.md",
        "stats_and_models.md",
        "bigdata.md",
        "dataviz.md",
        "collections.md",
        "howfitworks.md",
        "weights.md",
        "api.md",
    ]
)

deploydocs(
    repo   = "github.com/joshday/OnlineStats.jl.git"
)
