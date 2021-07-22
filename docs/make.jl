using Documenter, OnlineStats, OnlineStatsBase

makedocs(
    format = Documenter.HTML(
        assets = [
            asset("assets/style.css", islocal=true), 
            asset("assets/favicon.ico", islocal=true), 
            asset("https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap", class=:css)
        ]
    ),
    sitename = "",
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

deploydocs(repo = "github.com/joshday/OnlineStats.jl.git")
