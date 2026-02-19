"""
MathJSON validation implementation.

Provides functions for validating MathJSON expressions against the specification.
"""

"""
    validate(expr::AbstractMathJSONExpr; strict::Bool=false) -> ValidationResult

Validate a MathJSON expression against the specification.

# Arguments
- `expr`: The expression to validate
- `strict`: If `true`, also check symbol naming conventions and operator names
  against the standard library

# Returns
A `ValidationResult` with `valid` flag and `errors` vector

# Strict Mode Checks
- Symbol names should follow camelCase (variables) or PascalCase (constants)
- Operator names should be recognized standard library operators
- Wildcards (starting with `_`) are only valid in specific contexts

# Examples
```julia
# Basic validation
result = validate(NumberExpr(42))
result.valid  # true

# Invalid structure
result = validate(FunctionExpr(:Add, []))  # Missing arguments
result.valid  # true (structurally valid, but semantically questionable)

# Strict mode
result = validate(FunctionExpr(:CustomOp, [NumberExpr(1)]); strict=true)
result.errors  # ["Unknown operator: CustomOp"]
```
"""
function validate(expr::AbstractMathJSONExpr; strict::Bool = false)
    errors = String[]
    _validate_expr(expr, errors, strict)
    return ValidationResult(isempty(errors), errors)
end

"""
    _validate_expr(expr, errors, strict)

Internal validation dispatch for expressions.
"""
function _validate_expr(expr::NumberExpr, errors::Vector{String}, strict::Bool)
    # Numbers are always structurally valid
    # Could add domain checks here if needed
    return nothing
end

function _validate_expr(expr::SymbolExpr, errors::Vector{String}, strict::Bool)
    name = expr.name

    # Basic structural validation
    if isempty(name)
        push!(errors, "Symbol name cannot be empty")
        return nothing
    end

    if strict
        _validate_symbol_name(name, errors)
    end

    return nothing
end

function _validate_expr(expr::StringExpr, errors::Vector{String}, strict::Bool)
    # Strings are always structurally valid
    return nothing
end

function _validate_expr(expr::FunctionExpr, errors::Vector{String}, strict::Bool)
    # Validate operator
    op = expr.operator
    op_str = String(op)

    if isempty(op_str)
        push!(errors, "Function operator cannot be empty")
    end

    # Recursively validate arguments
    for (i, arg) in enumerate(expr.arguments)
        _validate_expr(arg, errors, strict)
    end

    # Strict mode: check if operator is known
    if strict && !is_known_operator(op)
        push!(errors, "Unknown operator: $op_str")
    end

    return nothing
end

"""
    _validate_symbol_name(name, errors)

Validate symbol naming conventions in strict mode.
"""
function _validate_symbol_name(name::String, errors::Vector{String})
    # Skip backtick-wrapped names (non-standard identifiers)
    if startswith(name, "`") && endswith(name, "`")
        return nothing
    end

    # Check for wildcards (should start with underscore and have more characters)
    if startswith(name, "_")
        if length(name) == 1
            push!(errors, "Wildcard symbol '_' must have a name after the underscore")
        end
        # Wildcards are valid, no further checks
        return nothing
    end

    # Check for valid identifier characters
    if !_is_valid_identifier(name)
        push!(errors, "Invalid symbol name: '$name'. Must be alphanumeric with underscores")
    end

    # Check naming convention
    if length(name) > 0
        first_char = name[1]
        if isuppercase(first_char)
            # PascalCase - constant (valid)
        elseif islowercase(first_char)
            # camelCase - variable (valid)
            # Could add more checks here
        else
            push!(errors, "Symbol name should start with a letter: '$name'")
        end
    end

    return nothing
end

"""
    _is_valid_identifier(name) -> Bool

Check if a name is a valid MathJSON identifier.
"""
function _is_valid_identifier(name::String)
    if isempty(name)
        return false
    end

    first_char = name[1]
    if !(isletter(first_char) || first_char == '_')
        return false
    end

    for c in name[2:end]
        if !(isletter(c) || isdigit(c) || c == '_')
            return false
        end
    end

    return true
end
