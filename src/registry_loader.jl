"""
Registry loader for MathJSON operator definitions.

This module provides functions to load operator categories, operators,
and Julia function mappings from JSON files in the data/ directory.
"""

using JSON3

# =============================================================================
# Data Types
# =============================================================================

"""
    CategoryInfo

Stores information about an operator category loaded from JSON.

# Fields
- `id::String`: Unique uppercase identifier (e.g., "ARITHMETIC")
- `name::String`: Human-readable display name
- `description::String`: Brief description of the category
"""
struct CategoryInfo
    id::String
    name::String
    description::String
end

"""
    OperatorInfo

Stores information about an operator loaded from JSON.

# Fields
- `name::Symbol`: Operator name as Symbol
- `category::String`: Category ID reference
- `arity::Union{String,Int,Nothing}`: Operator arity
- `description::Union{String,Nothing}`: Operator description
- `aliases::Vector{String}`: Alternative names
"""
struct OperatorInfo
    name::Symbol
    category::String
    arity::Union{String,Int,Nothing}
    description::Union{String,Nothing}
    aliases::Vector{String}
end

"""
    RegistryLoadError <: Exception

Exception raised when loading registry files fails.

# Fields
- `path::String`: Path to the file that caused the error
- `details::String`: Detailed error message
"""
struct RegistryLoadError <: Exception
    path::String
    details::String
end

function Base.showerror(io::IO, e::RegistryLoadError)
    print(io, "RegistryLoadError: Failed to load registry file '", e.path, "': ", e.details)
end

# =============================================================================
# Special Functions Mapping
# =============================================================================

"""
    SPECIAL_FUNCTIONS

Dictionary mapping special expression keys to anonymous functions.
Used for operators that cannot be represented as simple function references.
"""
const SPECIAL_FUNCTIONS = Dict{String,Function}(
    # Logical operators
    "logical_and" => (a, b) -> a && b,
    "logical_or" => (a, b) -> a || b,
    "logical_nand" => (a, b) -> !(a && b),
    "logical_nor" => (a, b) -> !(a || b),
    "logical_implies" => (a, b) -> !a || b,
    "logical_equivalent" => (a, b) -> a == b,
    # Set operators
    "not_element" => (x, s) -> !(x in s),
    "proper_subset" => (a, b) -> a ⊆ b && a != b,
    "proper_superset" => (a, b) -> b ⊆ a && a != b,
    "issuperset" => (a, b) -> b ⊆ a,
    # Arithmetic
    "square" => x -> x^2,
    # Collection operators
    "rest" => x -> x[2:end],
    "most" => x -> x[1:end-1],
    "take_n" => (x, n) -> x[1:min(n, length(x))],
    "drop_n" => (x, n) -> x[min(n+1, length(x)+1):end],
    "make_range" => (args...) -> begin
        if length(args) == 1
            1:args[1]
        elseif length(args) == 2
            args[1]:args[2]
        else
            args[1]:args[2]:args[3]
        end
    end
)

# =============================================================================
# Path Resolution
# =============================================================================

"""
    get_registry_path(filename::String) -> String

Return absolute path to a registry file in the data/ directory.

# Arguments
- `filename`: Relative path within data/ directory

# Examples
```julia
path = get_registry_path("categories.json")
schema_path = get_registry_path("schemas/categories.schema.json")
```
"""
function get_registry_path(filename::String)::String
    pkg_dir = pkgdir(@__MODULE__)
    if pkg_dir === nothing
        # Fallback for development
        pkg_dir = dirname(dirname(@__FILE__))
    end
    return joinpath(pkg_dir, "data", filename)
end

# =============================================================================
# Loading Functions
# =============================================================================

"""
    load_categories(filepath::String) -> Dict{String, CategoryInfo}

Load category definitions from a JSON file.

# Arguments
- `filepath`: Absolute path to categories JSON file

# Returns
Dictionary mapping category ID to CategoryInfo

# Throws
- `RegistryLoadError`: If file not found or JSON is malformed
"""
function load_categories(filepath::String)::Dict{String,CategoryInfo}
    if !isfile(filepath)
        throw(RegistryLoadError(filepath, "File not found"))
    end

    local data
    try
        content = read(filepath, String)
        data = JSON3.read(content)
    catch e
        if e isa ArgumentError
            throw(RegistryLoadError(filepath, "Invalid JSON: $(e.msg)"))
        end
        rethrow()
    end

    categories = Dict{String,CategoryInfo}()
    for cat in data.categories
        info = CategoryInfo(
            String(cat.id),
            String(cat.name),
            String(cat.description)
        )
        categories[info.id] = info
    end

    return categories
end

"""
    load_operators(filepath::String, categories::Dict{String,CategoryInfo}) -> Dict{Symbol, OperatorInfo}

Load operator definitions from a JSON file.

# Arguments
- `filepath`: Absolute path to operators JSON file
- `categories`: Dictionary of loaded categories for reference validation

# Returns
Dictionary mapping operator Symbol to OperatorInfo

# Throws
- `RegistryLoadError`: If file not found, JSON malformed, or category reference invalid
"""
function load_operators(
    filepath::String, categories::Dict{String,CategoryInfo}
)::Dict{Symbol,OperatorInfo}
    if !isfile(filepath)
        throw(RegistryLoadError(filepath, "File not found"))
    end

    local data
    try
        content = read(filepath, String)
        data = JSON3.read(content)
    catch e
        if e isa ArgumentError
            throw(RegistryLoadError(filepath, "Invalid JSON: $(e.msg)"))
        end
        rethrow()
    end

    operators = Dict{Symbol,OperatorInfo}()
    for op in data.operators
        name = Symbol(op.name)
        category = String(op.category)

        # Validate category reference
        if !haskey(categories, category)
            throw(RegistryLoadError(
                filepath,
                "Unknown category '$category' for operator '$name'"
            ))
        end

        arity = if hasproperty(op, :arity) && op.arity !== nothing
            val = op.arity
            val isa Integer ? Int(val) : String(val)
        else
            nothing
        end

        description = if hasproperty(op, :description) && op.description !== nothing
            String(op.description)
        else
            nothing
        end

        aliases = if hasproperty(op, :aliases) && op.aliases !== nothing
            String[String(a) for a in op.aliases]
        else
            String[]
        end

        info = OperatorInfo(name, category, arity, description, aliases)
        operators[name] = info
    end

    return operators
end

"""
    load_julia_functions(filepath::String, operators::Dict{Symbol,OperatorInfo}) -> Dict{Symbol, Union{Function, Nothing}}

Load Julia function mappings from a JSON file.

# Arguments
- `filepath`: Absolute path to julia_functions JSON file
- `operators`: Dictionary of loaded operators for reference validation

# Returns
Dictionary mapping operator Symbol to Function or nothing

# Throws
- `RegistryLoadError`: If file not found, JSON malformed, or operator reference invalid
"""
function load_julia_functions(
    filepath::String, operators::Dict{Symbol,OperatorInfo}
)::Dict{Symbol,Union{Function,Nothing}}
    if !isfile(filepath)
        throw(RegistryLoadError(filepath, "File not found"))
    end

    local data
    try
        content = read(filepath, String)
        data = JSON3.read(content)
    catch e
        if e isa ArgumentError
            throw(RegistryLoadError(filepath, "Invalid JSON: $(e.msg)"))
        end
        rethrow()
    end

    functions = Dict{Symbol,Union{Function,Nothing}}()
    for mapping in data.mappings
        op_name = Symbol(mapping.operator)

        # Validate operator reference
        if !haskey(operators, op_name)
            throw(RegistryLoadError(
                filepath,
                "Unknown operator '$op_name' in julia_functions.json"
            ))
        end

        func = nothing

        # Check for special expression first
        if hasproperty(mapping, :expression) && mapping.expression !== nothing
            expr_key = String(mapping.expression)
            if haskey(SPECIAL_FUNCTIONS, expr_key)
                func = SPECIAL_FUNCTIONS[expr_key]
            end
        elseif mapping.julia_function !== nothing
            func_name = String(mapping.julia_function)
            mod = if hasproperty(mapping, :module) && mapping.module !== nothing
                Symbol(mapping.module)
            else
                :Base
            end

            # Resolve function from module
            try
                func = getfield(Base, Symbol(func_name))
            catch
                # Try as is for operators like +, -, etc.
                try
                    func = eval(Meta.parse(func_name))
                catch
                    # Leave as nothing if we can't resolve
                    func = nothing
                end
            end
        end

        functions[op_name] = func
    end

    return functions
end
