using Documenter, StatsMakie

makedocs(
    format = :html,
    sitename = "StatsMakie",
    authors = "JuliaPlots",
    pages = [
        "Home" => "index.md",
        "Manual" => Any[
            "Tutorial" => "manual/tutorial.md",
        ]
    ]
)

deploydocs(
    repo = "github.com/JuliaPlots/StatsMakie.jl.git",
    target = "build",
    osname = "linux",
    deps   = nothing,
    make   = nothing
)
