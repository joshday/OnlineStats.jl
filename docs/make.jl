using Documenter, OnlineStats

makedocs(
    format = :html,
    sitename = "OnlineStats.jl",
    pages = [
        "index.md",
        "api.md",
        "types.md"
    ]
)

deploydocs(
    repo   = "github.com/joshday/OnlineStats.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)
