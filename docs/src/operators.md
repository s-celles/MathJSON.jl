# Operator Registry

MathJSON.jl uses a JSON-based registry system to define operators, their categories, and Julia function mappings. This design allows extending operator support without modifying Julia source code.

## File Structure

The registry consists of three JSON files in the `data/` directory:

```
data/
├── categories.json        # Category definitions
├── operators.json         # Operator definitions with category references
├── julia_functions.json   # Julia function mappings
└── schemas/               # JSON Schema files for validation
    ├── categories.schema.json
    ├── operators.schema.json
    └── julia_functions.schema.json
```

## Registry File Formats

### categories.json

Defines operator categories with unique identifiers, display names, and descriptions.

```json
{
  "categories": [
    {
      "id": "ARITHMETIC",
      "name": "Arithmetic",
      "description": "Basic math operations (+, -, *, /, ^)"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | Yes | Uppercase identifier (e.g., "ARITHMETIC") |
| `name` | String | Yes | Human-readable display name |
| `description` | String | Yes | Brief description of the category |

### operators.json

Defines operators with their category assignments and optional metadata.

```json
{
  "operators": [
    {
      "name": "Add",
      "category": "ARITHMETIC",
      "arity": "variadic",
      "description": "Addition of two or more values",
      "aliases": ["Plus", "Sum"]
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | Yes | MathJSON operator name |
| `category` | String | Yes | Category ID (must exist in categories.json) |
| `arity` | String/Integer | No | "unary", "binary", "variadic", or specific count |
| `description` | String | No | Brief description |
| `aliases` | Array | No | Alternative operator names |

### julia_functions.json

Maps operators to Julia functions for expression evaluation.

```json
{
  "mappings": [
    {
      "operator": "Add",
      "julia_function": "+",
      "module": "Base"
    },
    {
      "operator": "And",
      "julia_function": null,
      "expression": "logical_and"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `operator` | String | Yes | Operator name (must exist in operators.json) |
| `julia_function` | String/null | Yes | Julia function name or null if unmapped |
| `module` | String | No | Module containing the function (default: "Base") |
| `expression` | String | No | Key for special anonymous functions |

**Special Functions**: Some operators like `And` and `Or` require anonymous functions. These use the `expression` field to reference entries in the `SPECIAL_FUNCTIONS` dictionary:

```julia
const SPECIAL_FUNCTIONS = Dict{String,Function}(
    "logical_and" => (a, b) -> a && b,
    "logical_or" => (a, b) -> a || b
)
```

## Adding New Operators

### Step 1: Add Category (if needed)

Add a new entry to `data/categories.json`:

```json
{
  "id": "MY_CATEGORY",
  "name": "My Category",
  "description": "Description of the category"
}
```

**Note**: You must also add the category to the `OperatorCategory.T` enum in `src/operators.jl` and the `CATEGORY_ENUM_MAP` dictionary.

### Step 2: Add Operator

Add a new entry to `data/operators.json`:

```json
{
  "name": "MyOperator",
  "category": "MY_CATEGORY",
  "arity": "binary",
  "description": "What this operator does"
}
```

### Step 3: Add Julia Function Mapping

Add a new entry to `data/julia_functions.json`:

```json
{
  "operator": "MyOperator",
  "julia_function": "my_julia_function",
  "module": "Base"
}
```

For operators without a direct Julia equivalent:

```json
{
  "operator": "MyOperator",
  "julia_function": null
}
```

For operators requiring custom anonymous functions:

1. Add to `SPECIAL_FUNCTIONS` in `src/registry_loader.jl`:
   ```julia
   "my_special" => (a, b) -> custom_logic(a, b)
   ```

2. Reference in JSON:
   ```json
   {
     "operator": "MyOperator",
     "julia_function": null,
     "expression": "my_special"
   }
   ```

### Step 4: Run Tests

Validate your changes pass schema validation and all tests:

```bash
julia --project=. -e 'using Pkg; Pkg.test()'
```

## Current Operators

### Arithmetic

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Add | `+` | variadic | Addition |
| Subtract | `-` | binary | Subtraction |
| Multiply | `*` | variadic | Multiplication |
| Divide | `/` | binary | Division |
| Power | `^` | binary | Exponentiation |
| Negate | `-` | unary | Negation |
| Root | - | binary | Nth root |
| Sqrt | `sqrt` | unary | Square root |
| Abs | `abs` | unary | Absolute value |

### Trigonometric

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Sin | `sin` | unary | Sine |
| Cos | `cos` | unary | Cosine |
| Tan | `tan` | unary | Tangent |
| Arcsin | `asin` | unary | Inverse sine |
| Arccos | `acos` | unary | Inverse cosine |
| Arctan | `atan` | unary | Inverse tangent |
| Sinh | `sinh` | unary | Hyperbolic sine |
| Cosh | `cosh` | unary | Hyperbolic cosine |
| Tanh | `tanh` | unary | Hyperbolic tangent |
| Arcsinh | `asinh` | unary | Inverse hyperbolic sine |
| Arccosh | `acosh` | unary | Inverse hyperbolic cosine |
| Arctanh | `atanh` | unary | Inverse hyperbolic tangent |

### Logarithmic

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Log | `log` | unary | Natural logarithm |
| Ln | `log` | unary | Natural logarithm (alias) |
| Exp | `exp` | unary | Exponential (e^x) |
| Log10 | `log10` | unary | Base-10 logarithm |
| Log2 | `log2` | unary | Base-2 logarithm |

### Comparison

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Equal | `==` | binary | Equality |
| NotEqual | `!=` | binary | Inequality |
| Less | `<` | binary | Less than |
| Greater | `>` | binary | Greater than |
| LessEqual | `<=` | binary | Less than or equal |
| GreaterEqual | `>=` | binary | Greater than or equal |

### Logical

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| And | `(a, b) -> a && b` | variadic | Logical AND |
| Or | `(a, b) -> a \|\| b` | variadic | Logical OR |
| Not | `!` | unary | Logical NOT |

### Set

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Union | `union` | variadic | Set union |
| Intersection | `intersect` | variadic | Set intersection |
| SetMinus | `setdiff` | binary | Set difference |

### Calculus

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Derivative | - | binary | Derivative |
| Integrate | - | variadic | Integral |

## API Reference

### Functions

```@docs
get_category
get_julia_function
is_known_operator
```

### Types

```@docs
MathJSON.OperatorCategory
MathJSON.CategoryInfo
MathJSON.OperatorInfo
MathJSON.RegistryLoadError
```
