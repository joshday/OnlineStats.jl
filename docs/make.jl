using Documenter, OnlineStats, OnlineStatsBase, InteractiveUtils

makedocs(
    format = Documenter.HTML(
        assets = [
            asset("assets/style.css", islocal=true),
            asset("assets/favicon.ico", islocal=true),
        ],
        sidebar_sitename=false,
        edit_link = nothing,
        footer = "© 2022 Josh Day"
    ),
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
