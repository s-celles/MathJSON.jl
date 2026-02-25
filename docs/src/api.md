# API Reference

## Core Types

```@docs
MathJSONFormat
AbstractMathJSONExpr
ExpressionType
```

## Expression Types

```@docs
NumberExpr
SymbolExpr
StringExpr
FunctionExpr
```

## Parsing

```@docs
Base.parse(::Type{MathJSONFormat}, ::AbstractString)
```

## Generation

```@docs
generate
```

## Validation

```@docs
validate
ValidationResult
```

## Metadata

```@docs
metadata
with_metadata
```

## Operators

```@docs
OperatorCategory
OPERATORS
JULIA_FUNCTIONS
get_category
get_julia_function
is_known_operator
```

## Symbolics.jl Integration

```@docs
to_symbolics
to_mathjson
```

### Deprecated

- `from_symbolics(expr)` — use [`to_mathjson(expr)`](@ref to_mathjson) instead.

## Errors

```@docs
MathJSONParseError
UnsupportedConversionError
```
