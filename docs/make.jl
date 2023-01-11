using Documenter, NestedGraphsIO, NestedGraphs, GraphIO, Graphs
import NestedGraphs: NestedGraphFormat

makedocs(sitename="NestedGraphsIO.jl",
    pages = [
        "Introduction" => "index.md",
        "Usage and Examples" => "usage.md",
        "API" => "API.md"
    ],
    modules=[NestedGraphsIO])
