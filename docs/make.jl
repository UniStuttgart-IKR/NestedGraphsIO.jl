using Documenter, NestedGraphsIO

makedocs(sitename="NestedGraphsIO.jl",
    pages = [
        "Introduction" => "index.md",
        "Usage and Examples" => "usage.md",
        "API" => "API.md"
    ],
    modules=[NestedGraphsIO])

deploydocs(
    repo = "github.com/UniStuttgart-IKR/NestedGraphsIO.jl.git",
)
