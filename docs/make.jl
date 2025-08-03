using OnlineStats, OnlineStatsBase, InteractiveUtils
using Documenter
using Documenter.Remotes: GitHub

makedocs(
    format = Documenter.HTML(
        assets = [
            asset("assets/style.css", islocal=true),
            asset("assets/favicon.ico", islocal=true),
        ],
        sidebar_sitename=false,
        footer = "© 2022 Josh Day",
        analytics = "G-5LKX04JX9B"
    ),
    repo = GitHub("joshday/OnlineStats.jl"),
    sitename = "OnlineStats Documentation",
    modules = [OnlineStats, OnlineStatsBase],
    authors = "Josh Day",
    clean = true,
    debug = true,
    doctest = false,
    pages = [
        "index.md",
        "stats_and_models.md",
        "bigdata.md",
        "dataviz.md",
        "collections.md",
        "howfitworks.md",
        "weights.md",
        "ml.md",
        "api.md",
    ]
)

deploydocs(repo = "github.com/joshday/OnlineStats.jl.git")
