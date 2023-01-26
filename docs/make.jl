using FilterKinect
using Documenter

DocMeta.setdocmeta!(FilterKinect, :DocTestSetup, :(using FilterKinect); recursive=true)

makedocs(;
    modules=[FilterKinect],
    authors="Alexander Reimer",
    repo="https://github.com/AR102/FilterKinect.jl/blob/{commit}{path}#{line}",
    sitename="FilterKinect.jl",
    format=Documenter.HTML(;
        prettyurls=get(ENV, "CI", "false") == "true",
        canonical="https://AR102.github.io/FilterKinect.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
        "Troubleshooting" => "troubleshooting.md"
    ],
)

deploydocs(;
    repo="github.com/AR102/FilterKinect.jl",
    devbranch="main",
)
