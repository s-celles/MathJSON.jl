using Test
using MathJSON
using MathJSON: MathJSONFormat, NumberExpr, SymbolExpr, StringExpr, FunctionExpr,
    MathJSONParseError, metadata

@testset "MathJSON Parser" begin
    @testset "Parse Numbers" begin
        @testset "Integer values" begin
            expr = parse(MathJSONFormat, "42")
            @test expr isa NumberExpr
            @test expr.value == 42
            @test expr.value isa Int64
        end

        @testset "Float values" begin
            expr = parse(MathJSONFormat, "3.14")
            @test expr isa NumberExpr
            @test expr.value == 3.14
            @test expr.value isa Float64
        end

        @testset "Negative values" begin
            expr = parse(MathJSONFormat, "-42")
            @test expr.value == -42

            expr = parse(MathJSONFormat, "-3.14")
            @test expr.value == -3.14
        end

        @testset "Extended precision (object form)" begin
            expr = parse(MathJSONFormat, """{"num": "3.14159265358979323846"}""")
            @test expr isa NumberExpr
            @test expr.raw == "3.14159265358979323846"
        end

        @testset "Special values" begin
            # NaN
            expr = parse(MathJSONFormat, """{"num": "NaN"}""")
            @test expr isa NumberExpr
            @test isnan(expr.value)

            # Positive infinity
            expr = parse(MathJSONFormat, """{"num": "+Infinity"}""")
            @test isinf(expr.value)
            @test expr.value > 0

            expr = parse(MathJSONFormat, """{"num": "Infinity"}""")
            @test isinf(expr.value)
            @test expr.value > 0

            # Negative infinity
            expr = parse(MathJSONFormat, """{"num": "-Infinity"}""")
            @test isinf(expr.value)
            @test expr.value < 0
        end

        @testset "Repeating decimals" begin
            # 1/3 = 0.(3)
            expr = parse(MathJSONFormat, """{"num": "0.(3)"}""")
            @test expr isa NumberExpr
            @test expr.value isa Rational
            @test expr.value == 1 // 3

            # 1.(3) = 4/3
            expr = parse(MathJSONFormat, """{"num": "1.(3)"}""")
            @test expr.value == 4 // 3

            # 0.(142857) = 1/7
            expr = parse(MathJSONFormat, """{"num": "0.(142857)"}""")
            @test expr.value == 1 // 7

            # 1.2(3) = 1 + 2/10 + (3/9)/10 = 1 + 0.2 + 0.0333... = 37/30
            expr = parse(MathJSONFormat, """{"num": "1.2(3)"}""")
            @test expr.value == 37 // 30
        end
    end

    @testset "Parse Symbols" begin
        @testset "Simple symbols" begin
            expr = parse(MathJSONFormat, "\"x\"")
            @test expr isa SymbolExpr
            @test expr.name == "x"
        end

        @testset "PascalCase constants" begin
            expr = parse(MathJSONFormat, "\"Pi\"")
            @test expr.name == "Pi"

            expr = parse(MathJSONFormat, "\"ExponentialE\"")
            @test expr.name == "ExponentialE"
        end

        @testset "Symbol object form" begin
            expr = parse(MathJSONFormat, """{"sym": "Pi"}""")
            @test expr isa SymbolExpr
            @test expr.name == "Pi"
        end

        @testset "Symbol with metadata" begin
            expr = parse(MathJSONFormat, """{"sym": "Pi", "wikidata": "Q167"}""")
            @test expr.name == "Pi"
            @test metadata(expr) !== nothing
            @test metadata(expr)["wikidata"] == "Q167"
        end
    end

    @testset "Parse Strings" begin
        @testset "Single-quoted strings" begin
            expr = parse(MathJSONFormat, "\"'Hello World'\"")
            @test expr isa StringExpr
            @test expr.value == "Hello World"
        end

        @testset "Empty string" begin
            expr = parse(MathJSONFormat, "\"''\"")
            @test expr isa StringExpr
            @test expr.value == ""
        end

        @testset "String object form" begin
            expr = parse(MathJSONFormat, """{"str": "Hello"}""")
            @test expr isa StringExpr
            @test expr.value == "Hello"
        end

        @testset "String with metadata" begin
            expr = parse(MathJSONFormat, """{"str": "Hello", "comment": "greeting"}""")
            @test expr.value == "Hello"
            @test metadata(expr)["comment"] == "greeting"
        end
    end

    @testset "Parse Functions" begin
        @testset "Simple function" begin
            expr = parse(MathJSONFormat, """["Add", 1, 2]""")
            @test expr isa FunctionExpr
            @test expr.operator == :Add
            @test length(expr.arguments) == 2
            @test expr.arguments[1].value == 1
            @test expr.arguments[2].value == 2
        end

        @testset "Unary function" begin
            expr = parse(MathJSONFormat, """["Negate", 5]""")
            @test expr.operator == :Negate
            @test length(expr.arguments) == 1
            @test expr.arguments[1].value == 5
        end

        @testset "Function with symbol argument" begin
            expr = parse(MathJSONFormat, """["Sin", "x"]""")
            @test expr.operator == :Sin
            @test expr.arguments[1] isa SymbolExpr
            @test expr.arguments[1].name == "x"
        end

        @testset "Nested functions" begin
            # (1 + 2) * 3
            expr = parse(MathJSONFormat, """["Multiply", ["Add", 1, 2], 3]""")
            @test expr.operator == :Multiply
            @test expr.arguments[1] isa FunctionExpr
            @test expr.arguments[1].operator == :Add
            @test expr.arguments[2].value == 3
        end

        @testset "Function object form" begin
            expr = parse(MathJSONFormat, """{"fn": ["Add", 1, 2]}""")
            @test expr isa FunctionExpr
            @test expr.operator == :Add
        end

        @testset "Function with metadata" begin
            expr = parse(MathJSONFormat, """{"fn": ["Add", 1, 2], "latex": "1+2"}""")
            @test expr.operator == :Add
            @test metadata(expr)["latex"] == "1+2"
        end

        @testset "Empty arguments" begin
            expr = parse(MathJSONFormat, """["Random"]""")
            @test expr.operator == :Random
            @test isempty(expr.arguments)
        end
    end

    @testset "Metadata Parsing" begin
        @testset "Multiple metadata fields" begin
            expr = parse(MathJSONFormat, """
                {"sym": "Pi", "wikidata": "Q167", "comment": "pi constant", "latex": "\\\\pi"}
            """)
            meta = metadata(expr)
            @test meta["wikidata"] == "Q167"
            @test meta["comment"] == "pi constant"
            @test meta["latex"] == "\\pi"
        end

        @testset "Unknown metadata keys ignored" begin
            expr = parse(MathJSONFormat, """{"sym": "x", "customKey": "value"}""")
            meta = metadata(expr)
            @test meta === nothing || !haskey(meta, "customKey")
        end
    end

    @testset "Error Handling" begin
        @testset "Invalid JSON" begin
            @test_throws MathJSONParseError parse(MathJSONFormat, "not json")
        end

        @testset "Empty function array" begin
            @test_throws MathJSONParseError parse(MathJSONFormat, "[]")
        end

        @testset "Invalid function operator" begin
            @test_throws MathJSONParseError parse(MathJSONFormat, "[123, 1, 2]")
        end

        @testset "Unknown object format" begin
            @test_throws MathJSONParseError parse(MathJSONFormat, """{"unknown": "value"}""")
        end

        @testset "Invalid repeating decimal" begin
            @test_throws MathJSONParseError parse(MathJSONFormat, """{"num": "1.2("}""")
        end
    end
end
