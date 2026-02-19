"""
    MathJSON

A Julia package for parsing, manipulating, and generating mathematical expressions
in the MathJSON format.

MathJSON is a JSON-based format for representing mathematical expressions,
providing interoperability with web-based mathematical tools like MathLive
and the Cortex Compute Engine.

# Exports
- `parse(MathJSONFormat, str)`: Parse a MathJSON string into an expression
- `generate(MathJSONFormat, expr)`: Generate a MathJSON string from an expression
- `validate(expr)`: Validate an expression against the MathJSON specification

# Optional Extensions
- Symbolics.jl: `to_symbolics(expr)` and `from_symbolics(expr)` for conversion
"""
module MathJSON

using JSON3

# Include type definitions
include("types.jl")

# Include registry loader (must come before operators.jl)
include("registry_loader.jl")

# Include operator registry
include("operators.jl")

"""
    MathJSONFormat

Singleton type used for dispatch in `parse(MathJSONFormat, str)` and
`generate(MathJSONFormat, expr)` functions.
"""
struct MathJSONFormat end

# Include parser (after MathJSONFormat is defined)
include("parser.jl")

# Include generator
include("generator.jl")

# Include validation
include("validation.jl")

# Stub functions for Symbolics.jl extension
# These will be overloaded when Symbolics.jl is loaded

"""
    to_symbolics(expr::AbstractMathJSONExpr)

Convert a MathJSON expression to a Symbolics.jl expression.

This function requires the Symbolics.jl package to be loaded.
Load it with `using Symbolics` before calling this function.

# Examples
```julia
using Symbolics
expr = parse(MathJSONFormat, "[\"Add\", \"x\", 1]")
symbolic = to_symbolics(expr)
```
"""
function to_symbolics end

"""
    from_symbolics(expr)

Convert a Symbolics.jl expression to a MathJSON expression.

This function requires the Symbolics.jl package to be loaded.
Load it with `using Symbolics` before calling this function.

# Examples
```julia
using Symbolics
@variables x
mathjson = from_symbolics(x + 1)
```
"""
function from_symbolics end

# Exports
export MathJSONFormat
export ExpressionType
export AbstractMathJSONExpr
export MathJSONParseError, UnsupportedConversionError
export NumberExpr, SymbolExpr, StringExpr, FunctionExpr
export metadata, with_metadata, ValidationResult
export OperatorCategory, OPERATORS, JULIA_FUNCTIONS
export get_category, get_julia_function, is_known_operator
export RegistryLoadError, CategoryInfo, OperatorInfo
export load_categories, load_operators, load_julia_functions, get_registry_path
export SPECIAL_FUNCTIONS
export generate, validate
export to_symbolics, from_symbolics

end # module MathJSON
