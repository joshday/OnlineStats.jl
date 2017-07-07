using Documenter, OnlineStats

makedocs(
    format = :html,
    sitename = "OnlineStats.jl",
    pages = [
        "index.md",
        "types.md",
        "api.md"
    ]
)

deploydocs(
    repo   = "github.com/joshday/OnlineStats.jl.git",
    target = "build",
    deps   = nothing,
    make   = nothing
)
