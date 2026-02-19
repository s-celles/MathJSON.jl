using Test
using MathJSON
using Symbolics
using SymbolicUtils

using MathJSON: MathJSONFormat, NumberExpr, SymbolExpr, StringExpr, FunctionExpr,
    UnsupportedConversionError, to_symbolics, from_symbolics

@testset "Symbolics.jl Extension" begin
    @testset "to_symbolics conversion" begin
        @testset "Numbers" begin
            @test to_symbolics(NumberExpr(42)) == 42
            @test to_symbolics(NumberExpr(3.14)) == 3.14
            @test to_symbolics(NumberExpr(-17)) == -17
        end

        @testset "Symbols" begin
            result = to_symbolics(SymbolExpr("x"))
            @test result isa Symbolics.Num
        end

        @testset "Arithmetic functions" begin
            # Addition
            expr = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            result = to_symbolics(expr)
            @test result == 3

            # Subtraction
            expr = FunctionExpr(:Subtract, [NumberExpr(5), NumberExpr(3)])
            result = to_symbolics(expr)
            @test result == 2

            # Multiplication
            expr = FunctionExpr(:Multiply, [NumberExpr(4), NumberExpr(3)])
            result = to_symbolics(expr)
            @test result == 12

            # Division
            expr = FunctionExpr(:Divide, [NumberExpr(10), NumberExpr(2)])
            result = to_symbolics(expr)
            @test result == 5.0

            # Power
            expr = FunctionExpr(:Power, [NumberExpr(2), NumberExpr(3)])
            result = to_symbolics(expr)
            @test result == 8

            # Negate
            expr = FunctionExpr(:Negate, [NumberExpr(5)])
            result = to_symbolics(expr)
            @test result == -5
        end

        @testset "Trigonometric functions" begin
            # Sin
            expr = FunctionExpr(:Sin, [NumberExpr(0)])
            result = to_symbolics(expr)
            @test result == 0.0

            # Cos
            expr = FunctionExpr(:Cos, [NumberExpr(0)])
            result = to_symbolics(expr)
            @test result == 1.0
        end

        @testset "Logarithmic functions" begin
            # Exp
            expr = FunctionExpr(:Exp, [NumberExpr(0)])
            result = to_symbolics(expr)
            @test result == 1.0

            # Sqrt
            expr = FunctionExpr(:Sqrt, [NumberExpr(4)])
            result = to_symbolics(expr)
            @test result == 2.0
        end

        @testset "Symbolic expressions" begin
            # x + 1
            expr = FunctionExpr(:Add, [SymbolExpr("x"), NumberExpr(1)])
            result = to_symbolics(expr)
            @test result isa Symbolics.Num

            # sin(x)
            expr = FunctionExpr(:Sin, [SymbolExpr("x")])
            result = to_symbolics(expr)
            @test result isa Symbolics.Num
        end

        @testset "Nested expressions" begin
            # (1 + 2) * 3
            inner = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            outer = FunctionExpr(:Multiply, [inner, NumberExpr(3)])
            result = to_symbolics(outer)
            @test result == 9
        end

        @testset "N-ary operators" begin
            # Add with 3 arguments
            expr = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2), NumberExpr(3)])
            result = to_symbolics(expr)
            @test result == 6

            # Multiply with 3 arguments
            expr = FunctionExpr(:Multiply, [NumberExpr(2), NumberExpr(3), NumberExpr(4)])
            result = to_symbolics(expr)
            @test result == 24
        end

        @testset "Error handling" begin
            # StringExpr not supported
            @test_throws UnsupportedConversionError to_symbolics(StringExpr("hello"))

            # Unknown operator
            @test_throws UnsupportedConversionError to_symbolics(
                FunctionExpr(:CustomOp, [NumberExpr(1)])
            )
        end
    end

    @testset "from_symbolics conversion" begin
        @testset "Numbers" begin
            result = from_symbolics(42)
            @test result isa NumberExpr
            @test result.value == 42

            result = from_symbolics(3.14)
            @test result isa NumberExpr
            @test result.value == 3.14
        end

        @testset "Symbolic variables" begin
            @variables x
            result = from_symbolics(x)
            @test result isa SymbolExpr
            @test result.name == "x"
        end

        @testset "Arithmetic expressions" begin
            @variables x y

            # x + y
            result = from_symbolics(x + y)
            @test result isa FunctionExpr
            @test result.operator == :Add

            # x * y
            result = from_symbolics(x * y)
            @test result isa FunctionExpr
            @test result.operator == :Multiply

            # x - y
            result = from_symbolics(x - y)
            @test result isa FunctionExpr

            # x / y
            result = from_symbolics(x / y)
            @test result isa FunctionExpr

            # x^2
            result = from_symbolics(x^2)
            @test result isa FunctionExpr
            @test result.operator == :Power
        end

        @testset "Trigonometric expressions" begin
            @variables x

            result = from_symbolics(sin(x))
            @test result isa FunctionExpr
            @test result.operator == :Sin

            result = from_symbolics(cos(x))
            @test result isa FunctionExpr
            @test result.operator == :Cos
        end

        @testset "Logarithmic expressions" begin
            @variables x

            result = from_symbolics(exp(x))
            @test result isa FunctionExpr
            @test result.operator == :Exp

            result = from_symbolics(sqrt(x))
            @test result isa FunctionExpr
            @test result.operator == :Sqrt
        end

        @testset "Complex expressions" begin
            @variables x y

            # sin(x) + cos(y)
            result = from_symbolics(sin(x) + cos(y))
            @test result isa FunctionExpr
            @test result.operator == :Add
        end
    end

    @testset "Round-trip conversion" begin
        @testset "Numeric round-trip" begin
            original = NumberExpr(42)
            symbolic = to_symbolics(original)
            back = from_symbolics(symbolic)
            @test back.value == original.value
        end

        @testset "Expression round-trip" begin
            @variables x

            # Start from Symbolics
            symbolic_expr = x + 1
            mathjson = from_symbolics(symbolic_expr)
            @test mathjson isa FunctionExpr

            # Convert back to Symbolics
            back = to_symbolics(mathjson)
            @test back isa Symbolics.Num
        end
    end
end
