"""
MathJSON parser implementation.

Provides functions for parsing MathJSON strings into expression types.
"""

"""
    parse(::Type{MathJSONFormat}, str::AbstractString) -> AbstractMathJSONExpr

Parse a MathJSON string into an expression tree.

# Arguments
- `str`: A valid MathJSON JSON string

# Returns
An expression tree (`NumberExpr`, `SymbolExpr`, `StringExpr`, or `FunctionExpr`)

# Throws
- `MathJSONParseError`: If the input is not valid MathJSON

# Examples
```julia
# Parse a number
parse(MathJSONFormat, "42")  # NumberExpr(42)

# Parse a symbol
parse(MathJSONFormat, "\"x\"")  # SymbolExpr("x")

# Parse a function
parse(MathJSONFormat, "[\"Add\", 1, 2]")  # FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
```
"""
function Base.parse(::Type{MathJSONFormat}, str::AbstractString)
    try
        json_value = JSON3.read(str)
        return _parse_value(json_value)
    catch e
        if e isa JSON3.Error
            throw(MathJSONParseError("Invalid JSON: $(e.message)", nothing))
        elseif e isa ArgumentError
            # JSON3 throws ArgumentError for invalid JSON in some cases
            throw(MathJSONParseError("Invalid JSON: $(e.msg)", nothing))
        end
        rethrow()
    end
end

"""
    _parse_value(value) -> AbstractMathJSONExpr

Internal dispatch function for parsing JSON values into expressions.
"""
function _parse_value(value::Number)
    return _parse_number(value)
end

function _parse_value(value::AbstractString)
    return _parse_string_or_symbol(value)
end

function _parse_value(value::AbstractVector)
    return _parse_function(value)
end

function _parse_value(value::JSON3.Object)
    return _parse_object(value)
end

function _parse_value(value)
    throw(MathJSONParseError("Unsupported JSON value type: $(typeof(value))", nothing))
end

"""
    _parse_number(value::Number) -> NumberExpr

Parse a JSON number into a NumberExpr.
"""
function _parse_number(value::Integer)
    return NumberExpr(Int64(value))
end

function _parse_number(value::AbstractFloat)
    return NumberExpr(Float64(value))
end

"""
    _parse_string_or_symbol(value::AbstractString) -> Union{SymbolExpr, StringExpr}

Parse a JSON string. Single-quoted strings are StringExpr,
otherwise it's a SymbolExpr.
"""
function _parse_string_or_symbol(value::AbstractString)
    # MathJSON uses single quotes for string literals
    if startswith(value, "'") && endswith(value, "'") && length(value) >= 2
        # Remove the quotes to get the string content
        content = value[2:prevind(value, lastindex(value))]
        return StringExpr(content)
    else
        # It's a symbol
        return SymbolExpr(value)
    end
end

"""
    _parse_function(arr::AbstractVector) -> FunctionExpr

Parse a JSON array as a function expression.
First element is the operator, rest are arguments.
"""
function _parse_function(arr::AbstractVector)
    if isempty(arr)
        throw(MathJSONParseError("Function expression array cannot be empty", nothing))
    end

    op = arr[1]
    if !(op isa AbstractString)
        throw(MathJSONParseError("Function operator must be a string, got: $(typeof(op))", nothing))
    end

    operator = Symbol(op)
    arguments = AbstractMathJSONExpr[_parse_value(arg) for arg in arr[2:end]]

    return FunctionExpr(operator, arguments)
end

"""
    _parse_object(obj::JSON3.Object) -> AbstractMathJSONExpr

Parse a JSON object into an expression.
Handles extended number format, symbol format, string format, and function format.
"""
function _parse_object(obj::JSON3.Object)
    # Check for number format: {"num": "value"}
    if haskey(obj, :num)
        return _parse_number_object(obj)
    end

    # Check for symbol format: {"sym": "name", ...metadata}
    if haskey(obj, :sym)
        return _parse_symbol_object(obj)
    end

    # Check for string format: {"str": "value", ...metadata}
    if haskey(obj, :str)
        return _parse_string_object(obj)
    end

    # Check for function format: {"fn": [...], ...metadata}
    if haskey(obj, :fn)
        return _parse_function_object(obj)
    end

    throw(MathJSONParseError("Unknown object format. Expected 'num', 'sym', 'str', or 'fn' key", nothing))
end

"""
    _parse_number_object(obj::JSON3.Object) -> NumberExpr

Parse a number object: {"num": "value"}
Handles special values (NaN, Infinity) and extended precision.
"""
function _parse_number_object(obj::JSON3.Object)
    num_value = obj[:num]

    if !(num_value isa AbstractString)
        throw(MathJSONParseError("'num' value must be a string, got: $(typeof(num_value))", nothing))
    end

    # Handle special values
    if num_value == "NaN"
        return NumberExpr(NaN)
    elseif num_value == "+Infinity" || num_value == "Infinity"
        return NumberExpr(Inf)
    elseif num_value == "-Infinity"
        return NumberExpr(-Inf)
    end

    # Handle repeating decimal notation: "1.(3)" -> 1/3 + 1 = 4/3
    if contains(num_value, "(") && contains(num_value, ")")
        return _parse_repeating_decimal(num_value)
    end

    # Parse as extended precision
    parsed_value = _parse_numeric_string(num_value)
    return NumberExpr(parsed_value, num_value)
end

"""
    _parse_repeating_decimal(str::AbstractString) -> NumberExpr

Parse repeating decimal notation like "1.(3)" or "0.(142857)".
"""
function _parse_repeating_decimal(str::AbstractString)
    # Match pattern: optional minus, integer part, decimal point, non-repeating part, (repeating part)
    # Examples: "1.(3)", "0.(142857)", "1.2(3)", "-0.(6)"
    m = match(r"^(-?)(\d*)\.?(\d*)\((\d+)\)$", str)
    if m === nothing
        throw(MathJSONParseError("Invalid repeating decimal format: $str", nothing))
    end

    sign = m.captures[1] == "-" ? -1 : 1
    integer_part = isempty(m.captures[2]) ? "0" : m.captures[2]
    non_repeating = m.captures[3]
    repeating = m.captures[4]

    # Convert to rational
    # For "a.bc(def)":
    # = a.bcdefdefdef...
    # Let x = 0.bc(def)
    # x * 10^(len(bc)) = bc.(def)
    # Let y = 0.(def) = def/(10^len(def) - 1)
    # x = (bc + y) / 10^len(bc)
    # Total = a + x

    int_val = parse(BigInt, integer_part)
    nr_len = length(non_repeating)
    r_len = length(repeating)

    if nr_len > 0
        non_rep_val = parse(BigInt, non_repeating)
    else
        non_rep_val = BigInt(0)
    end
    rep_val = parse(BigInt, repeating)

    # Repeating part as fraction: rep_val / (10^r_len - 1)
    rep_denom = BigInt(10)^r_len - 1
    rep_frac = rep_val // rep_denom

    # Shift non-repeating and repeating by decimal places
    denom_shift = BigInt(10)^nr_len
    decimal_frac = (non_rep_val // denom_shift) + (rep_frac // denom_shift)

    result = sign * (int_val + decimal_frac)

    # Convert to Rational{Int64} if possible, otherwise Rational{BigInt}
    if typemin(Int64) <= numerator(result) <= typemax(Int64) &&
       typemin(Int64) <= denominator(result) <= typemax(Int64)
        return NumberExpr(Rational{Int64}(numerator(result), denominator(result)), str)
    else
        return NumberExpr(result, str)
    end
end

"""
    _parse_numeric_string(str::AbstractString) -> MathJSONNumber

Parse a numeric string into the appropriate Julia numeric type.
"""
function _parse_numeric_string(str::AbstractString)
    # Try to parse as integer first
    try
        val = parse(Int64, str)
        return val
    catch
    end

    # Try to parse as Float64
    try
        val = parse(Float64, str)
        return val
    catch
    end

    # Try to parse as BigFloat for extended precision
    try
        val = parse(BigFloat, str)
        return val
    catch
    end

    throw(MathJSONParseError("Cannot parse numeric value: $str", nothing))
end

"""
    _parse_symbol_object(obj::JSON3.Object) -> SymbolExpr

Parse a symbol object: {"sym": "name", ...metadata}
"""
function _parse_symbol_object(obj::JSON3.Object)
    name = obj[:sym]
    if !(name isa AbstractString)
        throw(MathJSONParseError("'sym' value must be a string, got: $(typeof(name))", nothing))
    end

    metadata = _extract_metadata(obj)
    return SymbolExpr(name; metadata = metadata)
end

"""
    _parse_string_object(obj::JSON3.Object) -> StringExpr

Parse a string object: {"str": "value", ...metadata}
"""
function _parse_string_object(obj::JSON3.Object)
    value = obj[:str]
    if !(value isa AbstractString)
        throw(MathJSONParseError("'str' value must be a string, got: $(typeof(value))", nothing))
    end

    metadata = _extract_metadata(obj)
    return StringExpr(value; metadata = metadata)
end

"""
    _parse_function_object(obj::JSON3.Object) -> FunctionExpr

Parse a function object: {"fn": [...], ...metadata}
"""
function _parse_function_object(obj::JSON3.Object)
    fn_value = obj[:fn]
    if !(fn_value isa AbstractVector)
        throw(MathJSONParseError("'fn' value must be an array, got: $(typeof(fn_value))", nothing))
    end

    expr = _parse_function(fn_value)
    metadata = _extract_metadata(obj)

    if metadata !== nothing
        return FunctionExpr(expr.operator, expr.arguments, metadata)
    end
    return expr
end

# Known metadata keys
const METADATA_KEYS = Set(["wikidata", "comment", "latex", "documentation", "sourceUrl"])

"""
    _extract_metadata(obj::JSON3.Object) -> Union{Nothing, Dict{String, Any}}

Extract metadata fields from a JSON object.
"""
function _extract_metadata(obj::JSON3.Object)
    metadata = Dict{String, Any}()

    for key in METADATA_KEYS
        sym_key = Symbol(key)
        if haskey(obj, sym_key)
            metadata[key] = obj[sym_key]
        end
    end

    return isempty(metadata) ? nothing : metadata
end
