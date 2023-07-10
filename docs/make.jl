using AirBorne
using AirBorne.Utils
using AirBorne.Structures
using AirBorne.ETL
using AirBorne.ETL.YFinance
using AirBorne.ETL.Cache
using AirBorne.Strategies
using AirBorne.Strategies.SMA
using AirBorne.Engines
using AirBorne.Engines.DEDS
using AirBorne.Markets
using AirBorne.Markets.StaticMarket
using Documenter

DocMeta.setdocmeta!(AirBorne, :DocTestSetup, :(using AirBorne); recursive=true)
Documenter.Writers.HTMLWriter.HTML(; collapselevel=1)

makedocs(;
    modules=[AirBorne],
    authors="brunocastroibarburu94 <brunocastroibarburu@gmail.com> and contributors",
    repo="https://github.com/JuDO-dev/Airborne.jl/blob/{commit}{path}#{line}",
    sitename="AirBorne.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://JuDO-dev.github.io/AirBorne.jl",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "High Level Design" => [
            "Glossary" => "./pages/highLevelDesign.md",
            "Data Pipeline" => "./pages/etl/etl.md",
            "Financial Modelling" => "./pages/financialModelling.md",
            "Event Driven Simulation" => "./pages/backtesting/eventDrivenSimulation.md",
        ],
        "Examples" => [
            "Strategy: SMA " => "./pages/examples/SMA.md",
        ],
        "Autodocs" => "./pages/autodocs.md",
        "Contribution Guidelines" => "./pages/contributionGuidelines.md",
    ],
)

deploydocs(; repo="github.com/JuDO-dev/AirBorne.jl", devbranch="dev")
