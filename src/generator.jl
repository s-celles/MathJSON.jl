"""
MathJSON generator implementation.

Provides functions for generating MathJSON strings from expression types.
"""

"""
    generate(::Type{MathJSONFormat}, expr::AbstractMathJSONExpr; compact::Bool=true, pretty::Bool=false) -> String

Generate a MathJSON string from an expression tree.

# Arguments
- `expr`: A MathJSON expression tree
- `compact`: If `true` (default), generate minimal JSON without unnecessary object forms
- `pretty`: If `true`, generate formatted JSON with indentation (default: `false`)

# Returns
A valid MathJSON JSON string

# Examples
```julia
# Generate a number
generate(MathJSONFormat, NumberExpr(42))  # "42"

# Generate a symbol
generate(MathJSONFormat, SymbolExpr("x"))  # "\"x\""

# Generate a function
generate(MathJSONFormat, FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]))  # "[\"Add\",1,2]"

# Generate with metadata (uses object form)
expr = NumberExpr(3.14; metadata=Dict("wikidata" => "Q167"))
generate(MathJSONFormat, expr)  # "{\"num\":\"3.14\",\"wikidata\":\"Q167\"}"
```
"""
function generate(::Type{MathJSONFormat}, expr::AbstractMathJSONExpr;
        compact::Bool = true, pretty::Bool = false)
    json_value = _to_json_value(expr, compact)
    if pretty
        io = IOBuffer()
        JSON3.pretty(io, json_value)
        return String(take!(io))
    else
        return JSON3.write(json_value)
    end
end

"""
    _to_json_value(expr, compact) -> Any

Convert an expression to a JSON-serializable value.
"""
function _to_json_value(expr::NumberExpr, compact::Bool)
    return _generate_number(expr, compact)
end

function _to_json_value(expr::SymbolExpr, compact::Bool)
    return _generate_symbol(expr, compact)
end

function _to_json_value(expr::StringExpr, compact::Bool)
    return _generate_string(expr, compact)
end

function _to_json_value(expr::FunctionExpr, compact::Bool)
    return _generate_function(expr, compact)
end

"""
    _generate_number(expr::NumberExpr, compact::Bool) -> Any

Generate JSON value for a number expression.
"""
function _generate_number(expr::NumberExpr, compact::Bool)
    value = expr.value
    has_metadata = expr.metadata !== nothing && !isempty(expr.metadata)
    has_raw = expr.raw !== nothing

    # Special values always need object form
    if isnan(value)
        return _build_number_object("NaN", expr.metadata)
    elseif isinf(value)
        if value > 0
            return _build_number_object("+Infinity", expr.metadata)
        else
            return _build_number_object("-Infinity", expr.metadata)
        end
    end

    # Rational needs object form for repeating decimal representation
    if value isa Rational
        return _build_number_object(_rational_to_repeating_string(value), expr.metadata)
    end

    # Extended precision (raw) needs object form
    if has_raw || has_metadata
        num_str = has_raw ? expr.raw : _value_to_string(value)
        return _build_number_object(num_str, expr.metadata)
    end

    # Simple number - use JSON native format if compact
    if compact
        if value isa Integer
            return Int64(value)
        else
            return Float64(value)
        end
    else
        return _build_number_object(_value_to_string(value), nothing)
    end
end

"""
    _build_number_object(num_str::String, metadata) -> Dict

Build a number object {"num": "value", ...metadata}
"""
function _build_number_object(num_str::String, metadata)
    result = Dict{String, Any}("num" => num_str)
    if metadata !== nothing
        merge!(result, metadata)
    end
    return result
end

"""
    _value_to_string(value) -> String

Convert a numeric value to its string representation.
"""
function _value_to_string(value::Integer)
    return string(value)
end

function _value_to_string(value::AbstractFloat)
    return string(value)
end

function _value_to_string(value::BigFloat)
    return string(value)
end

"""
    _rational_to_repeating_string(r::Rational) -> String

Convert a rational number to repeating decimal notation.
"""
function _rational_to_repeating_string(r::Rational)
    # For simplicity, just convert to decimal string format
    # A full implementation would detect the repeating pattern
    # For now, use fraction notation or decimal approximation
    n = numerator(r)
    d = denominator(r)

    # Handle simple cases
    if d == 1
        return string(n)
    end

    # Try to find repeating decimal representation
    # Extract integer part
    sign_str = n < 0 ? "-" : ""
    n = abs(n)
    int_part = n ÷ d
    remainder = n % d

    if remainder == 0
        return sign_str * string(int_part)
    end

    # Find the decimal expansion
    decimals = Char[]
    remainders = Int[]
    seen = Dict{Int, Int}()

    while remainder != 0 && !haskey(seen, remainder)
        seen[remainder] = length(decimals) + 1
        remainder *= 10
        digit = remainder ÷ d
        push!(decimals, Char('0' + digit))
        remainder = remainder % d
    end

    if remainder == 0
        # Terminating decimal
        return sign_str * string(int_part) * "." * String(decimals)
    else
        # Repeating decimal
        repeat_start = seen[remainder]
        non_repeating = String(decimals[1:(repeat_start - 1)])
        repeating = String(decimals[repeat_start:end])
        if isempty(non_repeating)
            return sign_str * string(int_part) * ".(" * repeating * ")"
        else
            return sign_str * string(int_part) * "." * non_repeating * "(" * repeating * ")"
        end
    end
end

"""
    _generate_symbol(expr::SymbolExpr, compact::Bool) -> Any

Generate JSON value for a symbol expression.
"""
function _generate_symbol(expr::SymbolExpr, compact::Bool)
    has_metadata = expr.metadata !== nothing && !isempty(expr.metadata)

    if has_metadata || !compact
        result = Dict{String, Any}("sym" => expr.name)
        if has_metadata
            merge!(result, expr.metadata)
        end
        return result
    else
        # Simple string form for valid identifiers
        return expr.name
    end
end

"""
    _generate_string(expr::StringExpr, compact::Bool) -> Any

Generate JSON value for a string expression.
"""
function _generate_string(expr::StringExpr, compact::Bool)
    has_metadata = expr.metadata !== nothing && !isempty(expr.metadata)

    if has_metadata || !compact
        result = Dict{String, Any}("str" => expr.value)
        if has_metadata
            merge!(result, expr.metadata)
        end
        return result
    else
        # Single-quoted string format
        return "'" * expr.value * "'"
    end
end

"""
    _generate_function(expr::FunctionExpr, compact::Bool) -> Any

Generate JSON value for a function expression.
"""
function _generate_function(expr::FunctionExpr, compact::Bool)
    has_metadata = expr.metadata !== nothing && !isempty(expr.metadata)

    # Build the array form
    arr = Any[String(expr.operator)]
    for arg in expr.arguments
        push!(arr, _to_json_value(arg, compact))
    end

    if has_metadata
        result = Dict{String, Any}("fn" => arr)
        merge!(result, expr.metadata)
        return result
    else
        return arr
    end
end
