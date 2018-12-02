using Documenter

makedocs(
    format = :html,
    sitename = "StatsMakie",
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
)
