using Test
using MathJSON
using MathJSON: MathJSONFormat, NumberExpr, SymbolExpr, StringExpr, FunctionExpr,
    ValidationResult, validate

@testset "Expression Validation" begin
    @testset "Basic Validation" begin
        @testset "Numbers are always valid" begin
            result = validate(NumberExpr(42))
            @test result.valid == true
            @test isempty(result.errors)

            result = validate(NumberExpr(NaN))
            @test result.valid == true

            result = validate(NumberExpr(Inf))
            @test result.valid == true
        end

        @testset "Valid symbols" begin
            result = validate(SymbolExpr("x"))
            @test result.valid == true

            result = validate(SymbolExpr("myVariable"))
            @test result.valid == true

            result = validate(SymbolExpr("Pi"))
            @test result.valid == true
        end

        @testset "Strings are always valid" begin
            result = validate(StringExpr("hello"))
            @test result.valid == true

            result = validate(StringExpr(""))
            @test result.valid == true
        end

        @testset "Valid functions" begin
            result = validate(FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]))
            @test result.valid == true

            result = validate(FunctionExpr(:Sin, [SymbolExpr("x")]))
            @test result.valid == true

            # Empty arguments is structurally valid
            result = validate(FunctionExpr(:Random, AbstractMathJSONExpr[]))
            @test result.valid == true
        end

        @testset "Nested expressions" begin
            inner = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            outer = FunctionExpr(:Multiply, [inner, NumberExpr(3)])
            result = validate(outer)
            @test result.valid == true
        end
    end

    @testset "Invalid Structures" begin
        @testset "Empty symbol name" begin
            expr = SymbolExpr("")
            result = validate(expr)
            @test result.valid == false
            @test any(e -> occursin("empty", lowercase(e)), result.errors)
        end
    end

    @testset "Strict Mode Validation" begin
        @testset "Known operators pass" begin
            result = validate(FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]); strict = true)
            @test result.valid == true

            result = validate(FunctionExpr(:Sin, [SymbolExpr("x")]); strict = true)
            @test result.valid == true
        end

        @testset "Unknown operators fail in strict mode" begin
            result = validate(FunctionExpr(:CustomOp, [NumberExpr(1)]); strict = true)
            @test result.valid == false
            @test any(e -> occursin("Unknown operator", e), result.errors)
        end

        @testset "Unknown operators pass in non-strict mode" begin
            result = validate(FunctionExpr(:CustomOp, [NumberExpr(1)]); strict = false)
            @test result.valid == true
        end

        @testset "Valid symbol names in strict mode" begin
            # camelCase variables
            result = validate(SymbolExpr("myVariable"); strict = true)
            @test result.valid == true

            # PascalCase constants
            result = validate(SymbolExpr("Pi"); strict = true)
            @test result.valid == true

            # Wildcards
            result = validate(SymbolExpr("_wildcard"); strict = true)
            @test result.valid == true
        end

        @testset "Backtick-wrapped names pass in strict mode" begin
            result = validate(SymbolExpr("`x+y`"); strict = true)
            @test result.valid == true

            result = validate(SymbolExpr("`my var`"); strict = true)
            @test result.valid == true
        end
    end

    @testset "Recursive Validation" begin
        @testset "Nested invalid expressions detected" begin
            # Valid outer, invalid inner (strict mode with unknown operator)
            inner = FunctionExpr(:CustomOp, [NumberExpr(1)])
            outer = FunctionExpr(:Add, [inner, NumberExpr(2)])
            result = validate(outer; strict = true)
            @test result.valid == false
            @test any(e -> occursin("CustomOp", e), result.errors)
        end

        @testset "Multiple errors collected" begin
            inner1 = FunctionExpr(:CustomOp1, [NumberExpr(1)])
            inner2 = FunctionExpr(:CustomOp2, [NumberExpr(2)])
            outer = FunctionExpr(:Add, [inner1, inner2])
            result = validate(outer; strict = true)
            @test result.valid == false
            @test length(result.errors) >= 2
        end
    end
end
