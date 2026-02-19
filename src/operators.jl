"""
MathJSON Standard Library operator registry and Julia function mapping.
"""

"""
    OperatorCategory

Module containing the operator category enum. Use scoped access to avoid
namespace pollution.

# Example
```julia
cat = OperatorCategory.ARITHMETIC
cat isa OperatorCategory.T  # true
```
"""
module OperatorCategory

"""
    OperatorCategory.T

Enum representing the categories of MathJSON operators.

# Values
- `ARITHMETIC`: Basic math operations (+, -, *, /, ^)
- `TRIGONOMETRIC`: Trigonometric functions (sin, cos, tan, etc.)
- `LOGARITHMIC`: Logarithmic and exponential functions
- `COMPARISON`: Comparison operators (<, >, ==, etc.)
- `LOGICAL`: Logical operators (and, or, not)
- `SET`: Set operations (union, intersection)
- `CALCULUS`: Calculus operations (derivative, integral)
- `UNKNOWN`: Unknown or unrecognized operator
"""
@enum T begin
    ARITHMETIC
    TRIGONOMETRIC
    LOGARITHMIC
    COMPARISON
    LOGICAL
    SET
    CALCULUS
    UNKNOWN
end

end # module OperatorCategory

"""
    OPERATORS::Dict{Symbol, OperatorCategory.T}

Dictionary mapping MathJSON operator symbols to their categories.
"""
const OPERATORS = Dict{Symbol, OperatorCategory.T}(
    # Arithmetic operators
    :Add => OperatorCategory.ARITHMETIC,
    :Subtract => OperatorCategory.ARITHMETIC,
    :Multiply => OperatorCategory.ARITHMETIC,
    :Divide => OperatorCategory.ARITHMETIC,
    :Power => OperatorCategory.ARITHMETIC,
    :Negate => OperatorCategory.ARITHMETIC,
    :Root => OperatorCategory.ARITHMETIC,
    :Sqrt => OperatorCategory.ARITHMETIC,
    :Abs => OperatorCategory.ARITHMETIC,

    # Trigonometric operators
    :Sin => OperatorCategory.TRIGONOMETRIC,
    :Cos => OperatorCategory.TRIGONOMETRIC,
    :Tan => OperatorCategory.TRIGONOMETRIC,
    :Arcsin => OperatorCategory.TRIGONOMETRIC,
    :Arccos => OperatorCategory.TRIGONOMETRIC,
    :Arctan => OperatorCategory.TRIGONOMETRIC,
    :Sinh => OperatorCategory.TRIGONOMETRIC,
    :Cosh => OperatorCategory.TRIGONOMETRIC,
    :Tanh => OperatorCategory.TRIGONOMETRIC,
    :Arcsinh => OperatorCategory.TRIGONOMETRIC,
    :Arccosh => OperatorCategory.TRIGONOMETRIC,
    :Arctanh => OperatorCategory.TRIGONOMETRIC,

    # Logarithmic/exponential operators
    :Log => OperatorCategory.LOGARITHMIC,
    :Ln => OperatorCategory.LOGARITHMIC,
    :Exp => OperatorCategory.LOGARITHMIC,
    :Log10 => OperatorCategory.LOGARITHMIC,
    :Log2 => OperatorCategory.LOGARITHMIC,

    # Comparison operators
    :Equal => OperatorCategory.COMPARISON,
    :NotEqual => OperatorCategory.COMPARISON,
    :Less => OperatorCategory.COMPARISON,
    :Greater => OperatorCategory.COMPARISON,
    :LessEqual => OperatorCategory.COMPARISON,
    :GreaterEqual => OperatorCategory.COMPARISON,

    # Logical operators
    :And => OperatorCategory.LOGICAL,
    :Or => OperatorCategory.LOGICAL,
    :Not => OperatorCategory.LOGICAL,

    # Set operators
    :Union => OperatorCategory.SET,
    :Intersection => OperatorCategory.SET,
    :SetMinus => OperatorCategory.SET,

    # Calculus operators
    :Derivative => OperatorCategory.CALCULUS,
    :Integrate => OperatorCategory.CALCULUS
)

"""
    JULIA_FUNCTIONS::Dict{Symbol, Function}

Dictionary mapping MathJSON operators to Julia functions.
Used for converting MathJSON expressions to executable Julia code
and for Symbolics.jl integration.
"""
const JULIA_FUNCTIONS = Dict{Symbol, Function}(
    # Arithmetic
    :Add => +,
    :Subtract => -,
    :Multiply => *,
    :Divide => /,
    :Power => ^,
    :Negate => -,
    :Sqrt => sqrt,
    :Abs => abs,

    # Trigonometric
    :Sin => sin,
    :Cos => cos,
    :Tan => tan,
    :Arcsin => asin,
    :Arccos => acos,
    :Arctan => atan,
    :Sinh => sinh,
    :Cosh => cosh,
    :Tanh => tanh,
    :Arcsinh => asinh,
    :Arccosh => acosh,
    :Arctanh => atanh,

    # Logarithmic/exponential
    :Log => log,
    :Ln => log,
    :Exp => exp,
    :Log10 => log10,
    :Log2 => log2,

    # Comparison
    :Equal => ==,
    :NotEqual => !=,
    :Less => <,
    :Greater => >,
    :LessEqual => <=,
    :GreaterEqual => >=,

    # Logical
    :And => (a, b) -> a && b,
    :Or => (a, b) -> a || b,
    :Not => !
)

"""
    get_category(op::Symbol) -> OperatorCategory.T

Return the category for a MathJSON operator, or `UNKNOWN` if the operator
is not recognized.

# Examples
```julia
get_category(:Add)      # OperatorCategory.ARITHMETIC
get_category(:Sin)      # OperatorCategory.TRIGONOMETRIC
get_category(:Custom)   # OperatorCategory.UNKNOWN
```
"""
function get_category(op::Symbol)
    return get(OPERATORS, op, OperatorCategory.UNKNOWN)
end

"""
    get_julia_function(op::Symbol) -> Union{Function, Nothing}

Return the Julia function corresponding to a MathJSON operator,
or `nothing` if no mapping exists.

# Examples
```julia
get_julia_function(:Add)     # +
get_julia_function(:Sin)     # sin
get_julia_function(:Custom)  # nothing
```
"""
function get_julia_function(op::Symbol)
    return get(JULIA_FUNCTIONS, op, nothing)
end

"""
    is_known_operator(op::Symbol) -> Bool

Return `true` if the operator is a known MathJSON standard library operator.

# Examples
```julia
is_known_operator(:Add)     # true
is_known_operator(:Sin)     # true
is_known_operator(:Custom)  # false
```
"""
function is_known_operator(op::Symbol)
    return haskey(OPERATORS, op)
end
