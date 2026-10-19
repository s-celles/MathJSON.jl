"""Generate the llms.txt files served with the documentation site."""
const DOCS_SOURCE = joinpath(@__DIR__, "src")

const DOC_PAGES = [
    "index.md",
    "operators.md",
    "api.md",
]

const LLMS_INDEX = """# MathJSON.jl

> Julia package for parsing, manipulating, validating, and generating MathJSON expressions.

## Documentation

- [Overview](index.md): installation, parsing, generation, validation, and Symbolics integration.
- [Operator Registry](operators.md): supported operators and categories.
- [API Reference](api.md): exported types and functions.
"""

write(joinpath(DOCS_SOURCE, "llms.txt"), LLMS_INDEX)

const LLMS_FULL = join(
    ["# MathJSON.jl documentation", (read(joinpath(DOCS_SOURCE, page), String) for page in DOC_PAGES)...],
    "\n\n",
)
write(joinpath(DOCS_SOURCE, "llms-full.txt"), LLMS_FULL)
