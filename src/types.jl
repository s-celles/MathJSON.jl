"""
Expression type enum and base types for MathJSON expressions.
"""

"""
    ExpressionType

Module containing the expression type enum. Use scoped access to avoid
namespace pollution.

# Example
```julia
expr_type = ExpressionType.NUMBER
expr_type isa ExpressionType.T  # true
```
"""
module ExpressionType

"""
    ExpressionType.T

Enum representing the four fundamental MathJSON expression types.

# Values
- `NUMBER`: Numeric values (integers, floats, rationals)
- `SYMBOL`: Variables, constants, and function names
- `STRING`: String literals
- `FUNCTION`: Function applications with operator and arguments
"""
@enum T begin
    NUMBER
    SYMBOL
    STRING
    FUNCTION
end

end # module ExpressionType

"""
    AbstractMathJSONExpr

Abstract base type for all MathJSON expression types.

All concrete expression types (`NumberExpr`, `SymbolExpr`, `StringExpr`,
`FunctionExpr`) are subtypes of this abstract type, enabling dispatch-based
polymorphism.
"""
abstract type AbstractMathJSONExpr end

"""
    MathJSONParseError <: Exception

Exception thrown when parsing invalid MathJSON input.

# Fields
- `message::String`: Description of the parse error
- `position::Union{Nothing, Int}`: Optional position in the input where error occurred

# Example
```julia
throw(MathJSONParseError("Unexpected token", 42))
```
"""
struct MathJSONParseError <: Exception
    message::String
    position::Union{Nothing, Int}
end

MathJSONParseError(message::String) = MathJSONParseError(message, nothing)

function Base.showerror(io::IO, e::MathJSONParseError)
    print(io, "MathJSONParseError: ", e.message)
    if e.position !== nothing
        print(io, " at position ", e.position)
    end
end

"""
    UnsupportedConversionError <: Exception

Exception thrown when attempting to convert an unsupported MathJSON expression
to Symbolics.jl or vice versa.

# Fields
- `message::String`: Description of the conversion error

# Example
```julia
throw(UnsupportedConversionError("Unknown operator: CustomOp"))
```
"""
struct UnsupportedConversionError <: Exception
    message::String
end

function Base.showerror(io::IO, e::UnsupportedConversionError)
    print(io, "UnsupportedConversionError: ", e.message)
end

# Type alias for numeric values supported by MathJSON
const MathJSONNumber = Union{Int64, Float64, BigFloat, Rational{BigInt}, Rational{Int64}}

"""
    NumberExpr <: AbstractMathJSONExpr

Represents a numeric value in MathJSON format.

# Fields
- `value::MathJSONNumber`: The numeric value (Int64, Float64, BigFloat, or Rational)
- `raw::Union{Nothing, String}`: Original string representation for extended precision
- `metadata::Union{Nothing, Dict{String, Any}}`: Optional metadata dictionary

# Constructors
```julia
NumberExpr(value)                        # Simple numeric value
NumberExpr(value, raw)                   # With raw string for precision
NumberExpr(value, raw, metadata)         # Full constructor
NumberExpr(value; metadata=nothing)      # With keyword metadata
```

# Examples
```julia
n1 = NumberExpr(42)
n2 = NumberExpr(3.14, "3.14159265358979323846")
n3 = NumberExpr(1//3)
n4 = NumberExpr(3.14; metadata=Dict("wikidata" => "Q167"))
```
"""
struct NumberExpr <: AbstractMathJSONExpr
    value::MathJSONNumber
    raw::Union{Nothing, String}
    metadata::Union{Nothing, Dict{String, Any}}
end

# Convenience constructors
function NumberExpr(value::MathJSONNumber, raw::String)
    NumberExpr(value, raw, nothing)
end
function NumberExpr(value::MathJSONNumber;
        raw::Union{Nothing, String} = nothing,
        metadata::Union{Nothing, Dict{String, Any}} = nothing)
    NumberExpr(value, raw, metadata)
end

# Equality based on value only (raw and metadata don't affect equality)
function Base.:(==)(a::NumberExpr, b::NumberExpr)
    # Handle NaN specially (NaN != NaN in IEEE, but we want NaN == NaN for expressions)
    if isnan(a.value) && isnan(b.value)
        return true
    end
    return a.value == b.value
end

function Base.show(io::IO, n::NumberExpr)
    if n.raw !== nothing
        print(io, "NumberExpr(", n.value, ", \"", n.raw, "\")")
    else
        print(io, "NumberExpr(", n.value, ")")
    end
end

"""
    SymbolExpr <: AbstractMathJSONExpr

Represents a symbol (variable, constant, or function name) in MathJSON format.

Symbol names are automatically normalized to Unicode NFC form for consistent
comparison.

# Fields
- `name::String`: The symbol name (NFC normalized)
- `metadata::Union{Nothing, Dict{String, Any}}`: Optional metadata dictionary

# Constructors
```julia
SymbolExpr(name)                    # Simple symbol
SymbolExpr(name; metadata=nothing)  # With optional metadata
```

# Valid Identifier Formats
- Standard: alphanumeric + underscore (e.g., `x`, `my_var`, `x1`)
- Backtick-wrapped: for non-standard names (e.g., `` `x+y` ``, `` `my var` ``)
- PascalCase: for constants (e.g., `Pi`, `ExponentialE`)

# Examples
```julia
s1 = SymbolExpr("x")
s2 = SymbolExpr("Pi"; metadata=Dict("wikidata" => "Q167"))
s3 = SymbolExpr("`x+y`")  # Non-standard identifier
```
"""
struct SymbolExpr <: AbstractMathJSONExpr
    name::String
    metadata::Union{Nothing, Dict{String, Any}}

    # Inner constructor with NFC normalization
    function SymbolExpr(name::String, metadata::Union{Nothing, Dict{String, Any}})
        normalized_name = Base.Unicode.normalize(name, :NFC)
        new(normalized_name, metadata)
    end
end

# Convenience constructor
function SymbolExpr(name::String; metadata::Union{Nothing, Dict{String, Any}} = nothing)
    SymbolExpr(name, metadata)
end

# Equality based on name only
function Base.:(==)(a::SymbolExpr, b::SymbolExpr)
    return a.name == b.name
end

function Base.show(io::IO, s::SymbolExpr)
    print(io, "SymbolExpr(\"", s.name, "\")")
end

"""
    StringExpr <: AbstractMathJSONExpr

Represents a string literal in MathJSON format.

# Fields
- `value::String`: The string value
- `metadata::Union{Nothing, Dict{String, Any}}`: Optional metadata dictionary

# Constructors
```julia
StringExpr(value)                    # Simple string
StringExpr(value; metadata=nothing)  # With optional metadata
```

# Examples
```julia
s1 = StringExpr("hello")
s2 = StringExpr("greeting"; metadata=Dict("comment" => "A greeting"))
```
"""
struct StringExpr <: AbstractMathJSONExpr
    value::String
    metadata::Union{Nothing, Dict{String, Any}}
end

# Convenience constructor
function StringExpr(value::String; metadata::Union{Nothing, Dict{String, Any}} = nothing)
    StringExpr(value, metadata)
end

# Equality based on value only
function Base.:(==)(a::StringExpr, b::StringExpr)
    return a.value == b.value
end

function Base.show(io::IO, s::StringExpr)
    print(io, "StringExpr(\"", s.value, "\")")
end

"""
    FunctionExpr <: AbstractMathJSONExpr

Represents a function application in MathJSON format.

# Fields
- `operator::Symbol`: The function/operator name as a Julia Symbol
- `arguments::Vector{AbstractMathJSONExpr}`: The function arguments
- `metadata::Union{Nothing, Dict{String, Any}}`: Optional metadata dictionary

# Constructors
```julia
FunctionExpr(operator, arguments)                    # Basic construction
FunctionExpr(operator, arguments; metadata=nothing)  # With optional metadata
```

# Examples
```julia
# 1 + 2
f1 = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])

# sin(x)
f2 = FunctionExpr(:Sin, [SymbolExpr("x")])

# (1 + 2) * 3 (nested)
inner = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
outer = FunctionExpr(:Multiply, [inner, NumberExpr(3)])
```
"""
struct FunctionExpr <: AbstractMathJSONExpr
    operator::Symbol
    arguments::Vector{AbstractMathJSONExpr}
    metadata::Union{Nothing, Dict{String, Any}}
end

# Convenience constructor
function FunctionExpr(operator::Symbol, arguments::Vector{<:AbstractMathJSONExpr};
        metadata::Union{Nothing, Dict{String, Any}} = nothing)
    FunctionExpr(operator, convert(Vector{AbstractMathJSONExpr}, arguments), metadata)
end

# Recursive equality comparison
function Base.:(==)(a::FunctionExpr, b::FunctionExpr)
    a.operator != b.operator && return false
    length(a.arguments) != length(b.arguments) && return false
    for (arg_a, arg_b) in zip(a.arguments, b.arguments)
        arg_a != arg_b && return false
    end
    return true
end

function Base.show(io::IO, f::FunctionExpr)
    print(io, "FunctionExpr(:", f.operator, ", [")
    for (i, arg) in enumerate(f.arguments)
        i > 1 && print(io, ", ")
        show(io, arg)
    end
    print(io, "])")
end

# ============================================================================
# Metadata Utilities
# ============================================================================

"""
    metadata(expr::AbstractMathJSONExpr)

Return the metadata dictionary associated with the expression, or `nothing`
if no metadata is present.

# Examples
```julia
n = NumberExpr(42; metadata=Dict("wikidata" => "Q167"))
metadata(n)  # Dict{String, Any}("wikidata" => "Q167")

s = SymbolExpr("x")
metadata(s)  # nothing
```
"""
function metadata(expr::NumberExpr)
    return expr.metadata
end

function metadata(expr::SymbolExpr)
    return expr.metadata
end

function metadata(expr::StringExpr)
    return expr.metadata
end

function metadata(expr::FunctionExpr)
    return expr.metadata
end

"""
    with_metadata(expr, key::String, value) -> AbstractMathJSONExpr

Return a new expression with the given key-value pair added to its metadata.
If the expression already has metadata, the new key-value is merged in.
The original expression is not modified.

# Examples
```julia
n = NumberExpr(42)
n2 = with_metadata(n, "wikidata", "Q167")
metadata(n2)  # Dict{String, Any}("wikidata" => "Q167")
metadata(n)   # nothing (original unchanged)
```
"""
function with_metadata(expr::NumberExpr, key::String, value)
    new_meta = if expr.metadata === nothing
        Dict{String, Any}(key => value)
    else
        merge(expr.metadata, Dict{String, Any}(key => value))
    end
    return NumberExpr(expr.value, expr.raw, new_meta)
end

function with_metadata(expr::SymbolExpr, key::String, value)
    new_meta = if expr.metadata === nothing
        Dict{String, Any}(key => value)
    else
        merge(expr.metadata, Dict{String, Any}(key => value))
    end
    return SymbolExpr(expr.name, new_meta)
end

function with_metadata(expr::StringExpr, key::String, value)
    new_meta = if expr.metadata === nothing
        Dict{String, Any}(key => value)
    else
        merge(expr.metadata, Dict{String, Any}(key => value))
    end
    return StringExpr(expr.value, new_meta)
end

function with_metadata(expr::FunctionExpr, key::String, value)
    new_meta = if expr.metadata === nothing
        Dict{String, Any}(key => value)
    else
        merge(expr.metadata, Dict{String, Any}(key => value))
    end
    return FunctionExpr(expr.operator, expr.arguments, new_meta)
end

"""
    with_metadata(expr, metadata::Dict{String, Any}) -> AbstractMathJSONExpr

Return a new expression with the given metadata dictionary, replacing any
existing metadata. The original expression is not modified.

# Examples
```julia
n = NumberExpr(42; metadata=Dict("old" => "value"))
n2 = with_metadata(n, Dict{String, Any}("new" => "value"))
metadata(n2)  # Dict{String, Any}("new" => "value")
```
"""
function with_metadata(expr::NumberExpr, meta::Dict{String, Any})
    return NumberExpr(expr.value, expr.raw, meta)
end

function with_metadata(expr::SymbolExpr, meta::Dict{String, Any})
    return SymbolExpr(expr.name, meta)
end

function with_metadata(expr::StringExpr, meta::Dict{String, Any})
    return StringExpr(expr.value, meta)
end

function with_metadata(expr::FunctionExpr, meta::Dict{String, Any})
    return FunctionExpr(expr.operator, expr.arguments, meta)
end

# ============================================================================
# Validation Result
# ============================================================================

"""
    ValidationResult

Result of validating a MathJSON expression.

# Fields
- `valid::Bool`: Whether the expression is valid
- `errors::Vector{String}`: List of validation error messages (empty if valid)

# Examples
```julia
result = ValidationResult(true, String[])
result.valid  # true
isempty(result.errors)  # true

result = ValidationResult(false, ["Invalid operator: Foo"])
result.valid  # false
result.errors  # ["Invalid operator: Foo"]
```
"""
struct ValidationResult
    valid::Bool
    errors::Vector{String}
end
