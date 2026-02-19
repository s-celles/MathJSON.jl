# MathJSON.jl

A Julia package for parsing, manipulating, and generating mathematical expressions in the [MathJSON](https://cortexjs.io/math-json/) format.

MathJSON is a JSON-based format for representing mathematical expressions, providing interoperability with web-based mathematical tools like [MathLive](https://cortexjs.io/mathlive/) and the [Cortex Compute Engine](https://cortexjs.io/compute-engine/).

## Features

- **Parse MathJSON**: Convert MathJSON strings to Julia expression trees
- **Generate MathJSON**: Serialize Julia expressions to MathJSON format
- **Validation**: Verify expressions conform to the MathJSON specification
- **Symbolics.jl Integration**: Bidirectional conversion with Symbolics.jl expressions

## Installation

```julia
using Pkg
Pkg.add("MathJSON")
```

## Quick Start

```julia
using MathJSON

# Parse a MathJSON expression
expr = parse(MathJSONFormat, """["Add", 1, 2]""")

# Generate MathJSON from an expression
json = generate(MathJSONFormat, FunctionExpr(:Multiply, [NumberExpr(3), SymbolExpr("x")]))

# Validate an expression
result = validate(expr)
```

## Symbolics.jl Integration

MathJSON.jl provides seamless integration with [Symbolics.jl](https://github.com/JuliaSymbolics/Symbolics.jl):

```julia
using MathJSON
using Symbolics

# Convert MathJSON to Symbolics
expr = parse(MathJSONFormat, """["Add", "x", 1]""")
symbolic = to_symbolics(expr)

# Convert Symbolics to MathJSON
@variables x
mathjson = from_symbolics(x + 1)
```

## API

See the [API Reference](api.md) page for complete documentation of all exported functions and types.
