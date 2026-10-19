using Documenter
using DocumenterLandingPage
using MathJSON

include("build_llms.jl")

makedocs(;
    sitename = "MathJSON.jl",
    modules = [MathJSON],
    authors = "Sébastien Celles <s.celles@gmail.com>",
    repo = "https://github.com/s-celles/MathJSON.jl",
    pages = [
        "Home" => "index.md",
        "Operator Registry" => "operators.md",
        "API Reference" => "api.md"
    ],
    checkdocs = :exports,
    plugins = [LandingPage()],
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://s-celles.github.io/MathJSON.jl",
        edit_link = nothing,
        repolink = "https://github.com/s-celles/MathJSON.jl"
    )
)

if get(ENV, "CI", "false") == "true"
    deploydocs(;
        repo = "github.com/s-celles/MathJSON.jl",
        devbranch = "main",
        push_preview = true
    )
end
