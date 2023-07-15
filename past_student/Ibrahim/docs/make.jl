using Documenter
using Airborne

makedocs(
    sitename = "Airborne.jl",
    format = Documenter.HTML(prettyurls = false),
    pages = [
        "Introduction" => "index.md",
        "API" => "api.md"
    ]
)

deploydocs(
    repo = "github.com/ibzmo/Airborne.jl.git",
    devbranch = "main"
)