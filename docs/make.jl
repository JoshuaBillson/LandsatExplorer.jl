using LandsatExplorer
using Documenter

DocMeta.setdocmeta!(LandsatExplorer, :DocTestSetup, :(using LandsatExplorer); recursive=true)

makedocs(;
    modules=[LandsatExplorer],
    authors="Joshua Billson",
    sitename="LandsatExplorer.jl",
    format=Documenter.HTML(;
        canonical="https://JoshuaBillson.github.io/LandsatExplorer.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/JoshuaBillson/LandsatExplorer.jl",
    devbranch="main",
)
