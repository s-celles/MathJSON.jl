# Operator Registry

MathJSON.jl uses a JSON-based registry system based on the [Cortex Compute Engine](https://cortexjs.io/compute-engine/) standard. The registry defines operators, their categories, and Julia function mappings.

## Cortex Compute Engine Compatibility

The operator definitions are sourced from the Cortex Compute Engine's [OPERATORS.json](https://github.com/cortex-js/compute-engine/blob/main/src/math-json/OPERATORS.json), providing full compatibility with the MathJSON standard library.

## File Structure

The registry consists of three JSON files in the `data/` directory:

```
data/
├── categories.json        # Category definitions
├── operators.json         # Operator definitions (Cortex format)
├── julia_functions.json   # Julia function mappings
└── schemas/               # JSON Schema files for validation
    ├── categories.schema.json
    ├── operators.schema.json
    └── julia_functions.schema.json
```

## Registry File Formats

### categories.json

Defines operator categories matching the Cortex Compute Engine standard.

```json
{
  "categories": [
    {
      "id": "Arithmetic",
      "name": "Arithmetic",
      "description": "Basic arithmetic operations and functions"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `id` | String | Yes | Category identifier (e.g., "Arithmetic", "Trigonometry") |
| `name` | String | Yes | Human-readable display name |
| `description` | String | Yes | Brief description of the category |

### operators.json

Defines operators using the Cortex Compute Engine format with full metadata.

```json
{
  "operators": [
    {
      "name": "Add",
      "category": "Arithmetic",
      "arity": "variadic",
      "signature": "(value+) -> value",
      "associative": true,
      "commutative": true,
      "idempotent": true,
      "lazy": true,
      "broadcastable": true,
      "description": "Sum of two or more values.",
      "wikidata": "Q32043"
    }
  ]
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `name` | String | Yes | MathJSON operator name |
| `category` | String | Yes | Category ID (must exist in categories.json) |
| `arity` | String | No | "1", "2", "variadic", "1+", "2+", etc. |
| `signature` | String | No | Type signature (e.g., "(number, number) -> number") |
| `associative` | Boolean | No | Whether the operator is associative |
| `commutative` | Boolean | No | Whether the operator is commutative |
| `idempotent` | Boolean | No | Whether the operator is idempotent |
| `lazy` | Boolean | No | Whether the operator uses lazy evaluation |
| `broadcastable` | Boolean | No | Whether the operator can be broadcast |
| `description` | String | No | Brief description |
| `wikidata` | String | No | Wikidata identifier (e.g., "Q32043") |
| `examples` | Array | No | Example expressions as strings |

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
    "logical_or" => (a, b) -> a || b,
    "logical_nand" => (a, b) -> !(a && b),
    "logical_nor" => (a, b) -> !(a || b),
    "logical_implies" => (a, b) -> !a || b,
    "logical_equivalent" => (a, b) -> a == b,
    "square" => x -> x^2,
    "nth_root" => (x, n) -> x^(1/n),
    # ... and more
)
```

## Categories

MathJSON.jl supports all 15 Cortex Compute Engine categories:

| Category | Description |
|----------|-------------|
| Arithmetic | Basic arithmetic operations and functions |
| Calculus | Calculus operations (derivatives, integrals, limits) |
| Collections | Operations on collections (lists, sequences, sets) |
| Colors | Color manipulation and conversion operations |
| Combinatorics | Combinatorial functions (factorial, binomial, permutations) |
| Control Structures | Control flow structures (if, loop, block) |
| Core | Core language constructs and meta-operations |
| Linear Algebra | Linear algebra operations (matrix, vector, decompositions) |
| Logic | Logical operators and predicates |
| Number Theory | Number theory functions (gcd, lcm, prime, divisibility) |
| Polynomials | Polynomial arithmetic and manipulation |
| Relational Operators | Comparison and relational operators |
| Statistics | Statistical functions (mean, variance, distributions) |
| Trigonometry | Trigonometric and hyperbolic functions |
| Units | Physical units and quantity operations |

## Selected Operators by Category

### Arithmetic (Sample)

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Add | `+` | variadic | Sum of two or more values |
| Subtract | `-` | 2 | Subtraction |
| Multiply | `*` | variadic | Multiplication |
| Divide | `/` | 2 | Division |
| Power | `^` | 2 | Exponentiation |
| Negate | `-` | 1 | Negation |
| Sqrt | `sqrt` | 1 | Square root |
| Abs | `abs` | 1 | Absolute value |
| Exp | `exp` | 1 | Exponential (e^x) |
| Ln | `log` | 1 | Natural logarithm |
| Log | `log` | 1-2 | Logarithm |
| Log10 | `log10` | 1 | Base-10 logarithm |
| Log2 | `log2` | 1 | Base-2 logarithm |

### Trigonometry (Sample)

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Sin | `sin` | 1 | Sine |
| Cos | `cos` | 1 | Cosine |
| Tan | `tan` | 1 | Tangent |
| Arcsin | `asin` | 1 | Inverse sine |
| Arccos | `acos` | 1 | Inverse cosine |
| Arctan | `atan` | 1 | Inverse tangent |
| Sinh | `sinh` | 1 | Hyperbolic sine |
| Cosh | `cosh` | 1 | Hyperbolic cosine |
| Tanh | `tanh` | 1 | Hyperbolic tangent |
| Arsinh | `asinh` | 1 | Inverse hyperbolic sine |
| Arcosh | `acosh` | 1 | Inverse hyperbolic cosine |
| Artanh | `atanh` | 1 | Inverse hyperbolic tangent |

### Relational Operators

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Equal | `==` | 2 | Equality |
| NotEqual | `!=` | 2 | Inequality |
| Less | `<` | 2 | Less than |
| Greater | `>` | 2 | Greater than |
| LessEqual | `<=` | 2 | Less than or equal |
| GreaterEqual | `>=` | 2 | Greater than or equal |
| ApproxEqual | `isapprox` | 2 | Approximate equality |

### Logic

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| And | `(a, b) -> a && b` | variadic | Logical AND |
| Or | `(a, b) -> a \|\| b` | variadic | Logical OR |
| Not | `!` | 1 | Logical NOT |
| Xor | `xor` | 2 | Exclusive OR |
| Nand | `(a, b) -> !(a && b)` | 2 | NOT AND |
| Nor | `(a, b) -> !(a \|\| b)` | 2 | NOT OR |
| Implies | `(a, b) -> !a \|\| b` | 2 | Logical implication |
| Equivalent | `(a, b) -> a == b` | 2 | Logical equivalence |

### Collections (Sample)

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Union | `union` | variadic | Set union |
| Intersection | `intersect` | variadic | Set intersection |
| SetMinus | `setdiff` | 2 | Set difference |
| First | `first` | 1 | First element |
| Last | `last` | 1 | Last element |
| Reverse | `reverse` | 1 | Reverse collection |
| Sort | `sort` | 1 | Sort collection |
| Unique | `unique` | 1 | Unique elements |

### Calculus

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| D | - | 1-2 | Derivative |
| ND | - | 1+ | Numerical derivative |
| Integrate | - | 1+ | Integral |
| NIntegrate | - | 1+ | Numerical integration |
| Limit | - | 2+ | Limit |
| Sum | `sum` | 1+ | Summation |
| Product | `prod` | 1+ | Product |

### Linear Algebra (Sample)

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Determinant | `det` | 1 | Matrix determinant |
| Transpose | `transpose` | 1 | Matrix transpose |
| Inverse | `inv` | 1 | Matrix inverse |
| Trace | `tr` | 1 | Matrix trace |
| Norm | `norm` | 1 | Vector/matrix norm |
| Rank | `rank` | 1 | Matrix rank |
| Eigenvalues | `eigvals` | 1 | Eigenvalues |
| Eigenvectors | `eigvecs` | 1 | Eigenvectors |

### Statistics (Sample)

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Mean | `mean` | 1 | Arithmetic mean |
| Median | `median` | 1 | Median value |
| Variance | `var` | 1 | Variance |
| StandardDeviation | `std` | 1 | Standard deviation |
| Min | `min` | variadic | Minimum |
| Max | `max` | variadic | Maximum |

### Combinatorics (Sample)

| Operator | Julia Function | Arity | Description |
|----------|---------------|-------|-------------|
| Factorial | `factorial` | 1 | Factorial |
| Binomial | `binomial` | 2 | Binomial coefficient |
| GCD | `gcd` | 2+ | Greatest common divisor |
| LCM | `lcm` | 2+ | Least common multiple |

## Adding New Operators

### Step 1: Add Category (if needed)

Add a new entry to `data/categories.json`:

```json
{
  "id": "MyCategory",
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
  "category": "MyCategory",
  "arity": "2",
  "signature": "(number, number) -> number",
  "associative": false,
  "commutative": true,
  "idempotent": false,
  "lazy": false,
  "broadcastable": true,
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

## API Reference

See the [API Reference](api.md#Operators) page for documentation of operator-related functions (`get_category`, `get_julia_function`, `is_known_operator`) and types (`OperatorCategory`).

### Registry Types

```@docs
MathJSON.CategoryInfo
MathJSON.OperatorInfo
MathJSON.RegistryLoadError
```
