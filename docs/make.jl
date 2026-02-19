using Documenter
using MathJSON

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
    format = Documenter.HTML(;
        prettyurls = get(ENV, "CI", "false") == "true",
        canonical = "https://s-celles.github.io/MathJSON.jl"
    ),
    warnonly = [:missing_docs]
)

deploydocs(;
    repo = "github.com/s-celles/MathJSON.jl",
    devbranch = "main",
    push_preview = true
)
