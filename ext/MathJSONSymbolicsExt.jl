"""
Extension module for Symbolics.jl integration with MathJSON.

This extension provides bidirectional conversion between MathJSON expressions
and Symbolics.jl symbolic expressions.
"""
module MathJSONSymbolicsExt

using MathJSON
using Symbolics
using SymbolicUtils

import MathJSON: to_symbolics, to_mathjson
import MathJSON: NumberExpr, SymbolExpr, StringExpr, FunctionExpr, AbstractMathJSONExpr
import MathJSON: UnsupportedConversionError, JULIA_FUNCTIONS, get_julia_function

# Cache for created Symbolics variables
const _VARIABLE_CACHE = Dict{String, Symbolics.Num}()

"""
    _get_or_create_variable(name::String) -> Symbolics.Num

Get or create a Symbolics variable for the given name.
Variables are cached to ensure consistency.
"""
function _get_or_create_variable(name::String)
    if haskey(_VARIABLE_CACHE, name)
        return _VARIABLE_CACHE[name]
    end
    var = Symbolics.variable(Symbol(name))
    _VARIABLE_CACHE[name] = var
    return var
end

"""
    clear_variable_cache!()

Clear the variable cache. Useful for testing or when starting fresh.
"""
function clear_variable_cache!()
    empty!(_VARIABLE_CACHE)
end

# ============================================================================
# MathJSON to Symbolics conversion
# ============================================================================

"""
    to_symbolics(expr::AbstractMathJSONExpr)

Convert a MathJSON expression to a Symbolics.jl expression.

# Examples
```julia
using Symbolics, MathJSON

# Convert a number
to_symbolics(NumberExpr(42))  # 42

# Convert a symbol
to_symbolics(SymbolExpr("x"))  # x (Symbolics variable)

# Convert a function
expr = parse(MathJSONFormat, "[\"Add\", \"x\", 1]")
to_symbolics(expr)  # x + 1
```
"""
function to_symbolics(expr::NumberExpr)
    return expr.value
end

function to_symbolics(expr::SymbolExpr)
    return _get_or_create_variable(expr.name)
end

function to_symbolics(expr::StringExpr)
    throw(UnsupportedConversionError("StringExpr cannot be converted to Symbolics"))
end

function to_symbolics(expr::FunctionExpr)
    op = expr.operator
    args = [to_symbolics(arg) for arg in expr.arguments]

    # Handle special cases
    if op == :Negate && length(args) == 1
        return -args[1]
    end

    # Look up Julia function
    julia_fn = get_julia_function(op)
    if julia_fn === nothing
        throw(UnsupportedConversionError("Unknown operator: $op"))
    end

    # Apply function based on arity
    if length(args) == 0
        throw(UnsupportedConversionError("Operator $op requires at least one argument"))
    elseif length(args) == 1
        return julia_fn(args[1])
    elseif length(args) == 2
        return julia_fn(args[1], args[2])
    else
        # For n-ary operators like Add and Multiply, reduce
        if op in [:Add, :Multiply]
            return reduce(julia_fn, args)
        else
            throw(UnsupportedConversionError("Operator $op does not support $(length(args)) arguments"))
        end
    end
end

# ============================================================================
# Symbolics to MathJSON conversion
# ============================================================================

# Mapping from Julia functions back to MathJSON operators
const REVERSE_OPERATOR_MAP = Dict{Function, Symbol}(
    Base.:+ => :Add,
    Base.:- => :Subtract,
    Base.:* => :Multiply,
    Base.:/ => :Divide,
    Base.:^ => :Power,
    Base.sin => :Sin,
    Base.cos => :Cos,
    Base.tan => :Tan,
    Base.asin => :Arcsin,
    Base.acos => :Arccos,
    Base.atan => :Arctan,
    Base.sinh => :Sinh,
    Base.cosh => :Cosh,
    Base.tanh => :Tanh,
    Base.asinh => :Arcsinh,
    Base.acosh => :Arccosh,
    Base.atanh => :Arctanh,
    Base.log => :Ln,
    Base.exp => :Exp,
    Base.log10 => :Log10,
    Base.log2 => :Log2,
    Base.sqrt => :Sqrt,
    Base.abs => :Abs
)

"""
    to_mathjson(expr) -> AbstractMathJSONExpr

Convert a Symbolics.jl expression to a MathJSON expression.

# Examples
```julia
using Symbolics, MathJSON

@variables x y
mathjson = to_mathjson(x + y)
# FunctionExpr(:Add, [SymbolExpr("x"), SymbolExpr("y")])
```
"""
function to_mathjson(expr::Number)
    if expr isa Integer
        return NumberExpr(Int64(expr))
    elseif expr isa Rational
        return NumberExpr(expr)
    else
        return NumberExpr(Float64(expr))
    end
end

function to_mathjson(expr::Symbolics.Num)
    # Unwrap Num to get the underlying symbolic expression
    return to_mathjson(Symbolics.value(expr))
end

function to_mathjson(expr::SymbolicUtils.BasicSymbolic)
    if SymbolicUtils.issym(expr)
        name = String(SymbolicUtils.nameof(expr))
        return SymbolExpr(name)
    elseif SymbolicUtils.iscall(expr)
        return _convert_symbolic_call(expr)
    elseif SymbolicUtils.symtype(expr) <: Number
        # Literal constant wrapped in BasicSymbolic (e.g. -1 in x - y)
        return to_mathjson(expr.val)
    else
        throw(UnsupportedConversionError("Unsupported symbolic expression type: $(typeof(expr))"))
    end
end

function to_mathjson(sym::Symbol)
    return SymbolExpr(String(sym))
end

"""
    _convert_symbolic_call(expr) -> FunctionExpr

Convert a symbolic function call to FunctionExpr.
"""
function _convert_symbolic_call(expr)
    op = SymbolicUtils.operation(expr)
    args_sym = SymbolicUtils.arguments(expr)

    # Convert arguments recursively
    args = AbstractMathJSONExpr[to_mathjson(arg) for arg in args_sym]

    # Map operation to MathJSON operator
    mathjson_op = get(REVERSE_OPERATOR_MAP, op, nothing)
    if mathjson_op === nothing
        # Try to use the function name as operator
        if op isa Function
            op_name = nameof(op)
            mathjson_op = Symbol(uppercasefirst(String(op_name)))
        else
            throw(UnsupportedConversionError("Unknown operation: $op"))
        end
    end

    return FunctionExpr(mathjson_op, args)
end

end # module
