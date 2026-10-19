```@raw html
---
layout: home

hero:
  name: MathJSON.jl
  text: MathJSON for Julia
  tagline: Parse, validate, and generate mathematical expressions with Julia.
  actions:
    - theme: brand
      text: Get started
      link: api/
    - theme: alt
      text: Operator registry
      link: operators/
    - theme: alt
      text: GitHub
      link: https://github.com/s-celles/MathJSON.jl

features:
  - icon: 🧩
    title: Parse and generate
    details: Convert between MathJSON and Julia expression trees.
    link: api/
  - icon: ✅
    title: Validate expressions
    details: Check expressions against the MathJSON specification.
  - icon: ∑
    title: Symbolics integration
    details: Convert between MathJSON and Symbolics.jl expressions.
  - icon: 📚
    title: Extensive operator registry
    details: Work with 382 operators in 15 categories.
    link: operators/
---
```

# MathJSON.jl

A Julia package for parsing, manipulating, and generating mathematical expressions in the [MathJSON](https://cortexjs.io/math-json/) format.

MathJSON is a JSON-based format for representing mathematical expressions, providing interoperability with web-based mathematical tools like [MathLive](https://cortexjs.io/mathlive/) and the [Cortex Compute Engine](https://cortexjs.io/compute-engine/).

## Features

- **Parse MathJSON**: Convert MathJSON strings to Julia expression trees
- **Generate MathJSON**: Serialize Julia expressions to MathJSON format
- **Validation**: Verify expressions conform to the MathJSON specification
- **Symbolics.jl Integration**: Bidirectional conversion with Symbolics.jl expressions
- **Cortex Compute Engine Compatible**: Full support for all 382 operators from the official MathJSON standard library

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
mathjson = to_mathjson(x + 1)
```

## Operator Registry

MathJSON.jl includes an extensive operator registry based on the [Cortex Compute Engine](https://cortexjs.io/compute-engine/) standard library:

- **382 operators** across 15 categories
- **Arithmetic**: Add, Subtract, Multiply, Divide, Power, Sqrt, Abs, Exp, Log, ...
- **Trigonometry**: Sin, Cos, Tan, Arcsin, Arccos, Arctan, Sinh, Cosh, ...
- **Calculus**: D (derivative), Integrate, Limit, Sum, Product, ...
- **Linear Algebra**: Determinant, Transpose, Inverse, Eigenvalues, ...
- **Logic**: And, Or, Not, Xor, Implies, Equivalent, ...
- **Statistics**: Mean, Median, Variance, StandardDeviation, ...
- **And more**: Collections, Combinatorics, Number Theory, Polynomials, ...

See the [Operator Registry](operators.md) page for complete documentation.

## API

See the [API Reference](api.md) page for complete documentation of all exported functions and types.
