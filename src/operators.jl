"""
MathJSON Standard Library operator registry and Julia function mapping.

Operators and function mappings are loaded from JSON files in the data/ directory.
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
    # Additional categories from MathJSON standard library
    TRIGONOMETRY
    COLLECTIONS
    COMPLEX
    SPECIAL_FUNCTIONS
    STATISTICS
    LINEAR_ALGEBRA
    COMBINATORICS
    NUMBER_THEORY
    CORE
    CONTROL_STRUCTURES
    FUNCTIONS
    STRINGS
    UNITS
end

end # module OperatorCategory

# =============================================================================
# Category String to Enum Mapping
# =============================================================================

"""
    CATEGORY_ENUM_MAP

Maps category ID strings to OperatorCategory.T enum values.
"""
const CATEGORY_ENUM_MAP = Dict{String,OperatorCategory.T}(
    "ARITHMETIC" => OperatorCategory.ARITHMETIC,
    "TRIGONOMETRIC" => OperatorCategory.TRIGONOMETRIC,
    "LOGARITHMIC" => OperatorCategory.LOGARITHMIC,
    "COMPARISON" => OperatorCategory.COMPARISON,
    "LOGICAL" => OperatorCategory.LOGICAL,
    "SET" => OperatorCategory.SET,
    "CALCULUS" => OperatorCategory.CALCULUS,
    "UNKNOWN" => OperatorCategory.UNKNOWN,
    "TRIGONOMETRY" => OperatorCategory.TRIGONOMETRY,
    "COLLECTIONS" => OperatorCategory.COLLECTIONS,
    "COMPLEX" => OperatorCategory.COMPLEX,
    "SPECIAL_FUNCTIONS" => OperatorCategory.SPECIAL_FUNCTIONS,
    "STATISTICS" => OperatorCategory.STATISTICS,
    "LINEAR_ALGEBRA" => OperatorCategory.LINEAR_ALGEBRA,
    "COMBINATORICS" => OperatorCategory.COMBINATORICS,
    "NUMBER_THEORY" => OperatorCategory.NUMBER_THEORY,
    "CORE" => OperatorCategory.CORE,
    "CONTROL_STRUCTURES" => OperatorCategory.CONTROL_STRUCTURES,
    "FUNCTIONS" => OperatorCategory.FUNCTIONS,
    "STRINGS" => OperatorCategory.STRINGS,
    "UNITS" => OperatorCategory.UNITS
)

# =============================================================================
# Load Registry Data from JSON Files
# =============================================================================

"""
    _load_registry_data()

Load operator registry data from JSON files and return populated dictionaries.
"""
function _load_registry_data()
    # Load categories
    cat_path = get_registry_path("categories.json")
    categories = load_categories(cat_path)

    # Load operators
    op_path = get_registry_path("operators.json")
    operator_registry = load_operators(op_path, categories)

    # Load Julia functions
    func_path = get_registry_path("julia_functions.json")
    function_registry = load_julia_functions(func_path, operator_registry)

    # Build OPERATORS dictionary (Symbol -> OperatorCategory.T)
    operators_dict = Dict{Symbol,OperatorCategory.T}()
    for (name, info) in operator_registry
        cat_enum = get(CATEGORY_ENUM_MAP, info.category, OperatorCategory.UNKNOWN)
        operators_dict[name] = cat_enum
    end

    # Build JULIA_FUNCTIONS dictionary (Symbol -> Function)
    # Only include operators that have a function mapping
    functions_dict = Dict{Symbol,Function}()
    for (name, func) in function_registry
        if func !== nothing
            functions_dict[name] = func
        end
    end

    return operators_dict, functions_dict
end

# Load at module initialization
const _LOADED_OPERATORS, _LOADED_FUNCTIONS = _load_registry_data()

"""
    OPERATORS::Dict{Symbol, OperatorCategory.T}

Dictionary mapping MathJSON operator symbols to their categories.
Loaded from data/operators.json at module initialization.
"""
const OPERATORS = _LOADED_OPERATORS

"""
    JULIA_FUNCTIONS::Dict{Symbol, Function}

Dictionary mapping MathJSON operators to Julia functions.
Used for converting MathJSON expressions to executable Julia code
and for Symbolics.jl integration.
Loaded from data/julia_functions.json at module initialization.
"""
const JULIA_FUNCTIONS = _LOADED_FUNCTIONS

# =============================================================================
# API Functions
# =============================================================================

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
