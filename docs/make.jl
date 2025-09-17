using SEQ2EXPdata
using Documenter

DocMeta.setdocmeta!(SEQ2EXPdata, :DocTestSetup, :(using SEQ2EXPdata); recursive=true)

makedocs(;
    modules=[SEQ2EXPdata],
    authors="Shane Kuei-Hsien Chu (skchu@wustl.edu)",
    sitename="SEQ2EXPdata.jl",
    format=Documenter.HTML(;
        canonical="https://kchu25.github.io/SEQ2EXPdata.jl",
        edit_link="main",
        assets=String[],
    ),
    pages=[
        "Home" => "index.md",
    ],
)

deploydocs(;
    repo="github.com/kchu25/SEQ2EXPdata.jl",
    devbranch="main",
)
