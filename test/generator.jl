using Test
using MathJSON
using MathJSON: MathJSONFormat, NumberExpr, SymbolExpr, StringExpr, FunctionExpr, generate

@testset "MathJSON Generator" begin
    @testset "Generate Numbers" begin
        @testset "Integer values" begin
            expr = NumberExpr(42)
            @test generate(MathJSONFormat, expr) == "42"

            expr = NumberExpr(-17)
            @test generate(MathJSONFormat, expr) == "-17"

            expr = NumberExpr(0)
            @test generate(MathJSONFormat, expr) == "0"
        end

        @testset "Float values" begin
            expr = NumberExpr(3.14)
            result = generate(MathJSONFormat, expr)
            @test result == "3.14"

            expr = NumberExpr(-2.5)
            @test generate(MathJSONFormat, expr) == "-2.5"
        end

        @testset "Special values" begin
            # NaN
            expr = NumberExpr(NaN)
            result = generate(MathJSONFormat, expr)
            @test occursin("\"num\"", result)
            @test occursin("NaN", result)

            # Positive infinity
            expr = NumberExpr(Inf)
            result = generate(MathJSONFormat, expr)
            @test occursin("+Infinity", result)

            # Negative infinity
            expr = NumberExpr(-Inf)
            result = generate(MathJSONFormat, expr)
            @test occursin("-Infinity", result)
        end

        @testset "Extended precision (raw)" begin
            expr = NumberExpr(3.14, "3.14159265358979323846")
            result = generate(MathJSONFormat, expr)
            @test occursin("\"num\"", result)
            @test occursin("3.14159265358979323846", result)
        end

        @testset "Rational values" begin
            expr = NumberExpr(1 // 3)
            result = generate(MathJSONFormat, expr)
            @test occursin("\"num\"", result)
            @test occursin("(3)", result)  # Repeating decimal notation

            expr = NumberExpr(1 // 2)
            result = generate(MathJSONFormat, expr)
            @test occursin("\"num\"", result)
            @test occursin("0.5", result)
        end

        @testset "Numbers with metadata" begin
            meta = Dict{String, Any}("wikidata" => "Q167")
            expr = NumberExpr(3.14; metadata = meta)
            result = generate(MathJSONFormat, expr)
            @test occursin("\"num\"", result)
            @test occursin("wikidata", result)
            @test occursin("Q167", result)
        end
    end

    @testset "Generate Symbols" begin
        @testset "Simple symbols" begin
            expr = SymbolExpr("x")
            @test generate(MathJSONFormat, expr) == "\"x\""

            expr = SymbolExpr("myVariable")
            @test generate(MathJSONFormat, expr) == "\"myVariable\""
        end

        @testset "PascalCase constants" begin
            expr = SymbolExpr("Pi")
            @test generate(MathJSONFormat, expr) == "\"Pi\""
        end

        @testset "Symbols with metadata" begin
            meta = Dict{String, Any}("wikidata" => "Q167")
            expr = SymbolExpr("Pi"; metadata = meta)
            result = generate(MathJSONFormat, expr)
            @test occursin("\"sym\"", result)
            @test occursin("Pi", result)
            @test occursin("wikidata", result)
        end
    end

    @testset "Generate Strings" begin
        @testset "Simple strings" begin
            expr = StringExpr("Hello")
            @test generate(MathJSONFormat, expr) == "\"'Hello'\""
        end

        @testset "Empty string" begin
            expr = StringExpr("")
            @test generate(MathJSONFormat, expr) == "\"''\""
        end

        @testset "Strings with metadata" begin
            meta = Dict{String, Any}("comment" => "greeting")
            expr = StringExpr("Hello"; metadata = meta)
            result = generate(MathJSONFormat, expr)
            @test occursin("\"str\"", result)
            @test occursin("Hello", result)
            @test occursin("comment", result)
        end
    end

    @testset "Generate Functions" begin
        @testset "Simple binary function" begin
            expr = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            result = generate(MathJSONFormat, expr)
            @test result == "[\"Add\",1,2]"
        end

        @testset "Unary function" begin
            expr = FunctionExpr(:Negate, [NumberExpr(5)])
            result = generate(MathJSONFormat, expr)
            @test result == "[\"Negate\",5]"
        end

        @testset "Function with symbol argument" begin
            expr = FunctionExpr(:Sin, [SymbolExpr("x")])
            result = generate(MathJSONFormat, expr)
            @test result == "[\"Sin\",\"x\"]"
        end

        @testset "Nested functions" begin
            inner = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            outer = FunctionExpr(:Multiply, [inner, NumberExpr(3)])
            result = generate(MathJSONFormat, outer)
            @test result == "[\"Multiply\",[\"Add\",1,2],3]"
        end

        @testset "Empty arguments" begin
            expr = FunctionExpr(:Random, AbstractMathJSONExpr[])
            result = generate(MathJSONFormat, expr)
            @test result == "[\"Random\"]"
        end

        @testset "Functions with metadata" begin
            meta = Dict{String, Any}("latex" => "1+2")
            expr = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]; metadata = meta)
            result = generate(MathJSONFormat, expr)
            @test occursin("\"fn\"", result)
            @test occursin("latex", result)
            @test occursin("1+2", result)
        end
    end

    @testset "Round-trip Tests" begin
        @testset "Numbers round-trip" begin
            cases = [
                NumberExpr(42),
                NumberExpr(3.14),
                NumberExpr(-17),
                NumberExpr(0),
            ]
            for expr in cases
                json_str = generate(MathJSONFormat, expr)
                parsed = parse(MathJSONFormat, json_str)
                @test parsed.value == expr.value
            end
        end

        @testset "Symbols round-trip" begin
            cases = [
                SymbolExpr("x"),
                SymbolExpr("Pi"),
                SymbolExpr("myVariable"),
            ]
            for expr in cases
                json_str = generate(MathJSONFormat, expr)
                parsed = parse(MathJSONFormat, json_str)
                @test parsed.name == expr.name
            end
        end

        @testset "Functions round-trip" begin
            cases = [
                FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]),
                FunctionExpr(:Sin, [SymbolExpr("x")]),
                FunctionExpr(:Multiply, [
                    FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]),
                    NumberExpr(3)
                ]),
            ]
            for expr in cases
                json_str = generate(MathJSONFormat, expr)
                parsed = parse(MathJSONFormat, json_str)
                @test parsed == expr
            end
        end

        @testset "Special values round-trip" begin
            # NaN
            expr = NumberExpr(NaN)
            json_str = generate(MathJSONFormat, expr)
            parsed = parse(MathJSONFormat, json_str)
            @test isnan(parsed.value)

            # Infinity
            expr = NumberExpr(Inf)
            json_str = generate(MathJSONFormat, expr)
            parsed = parse(MathJSONFormat, json_str)
            @test isinf(parsed.value) && parsed.value > 0

            # Negative infinity
            expr = NumberExpr(-Inf)
            json_str = generate(MathJSONFormat, expr)
            parsed = parse(MathJSONFormat, json_str)
            @test isinf(parsed.value) && parsed.value < 0
        end

        @testset "Rationals round-trip" begin
            # 1/3
            expr = NumberExpr(1 // 3)
            json_str = generate(MathJSONFormat, expr)
            parsed = parse(MathJSONFormat, json_str)
            @test parsed.value == 1 // 3

            # 1/7
            expr = NumberExpr(1 // 7)
            json_str = generate(MathJSONFormat, expr)
            parsed = parse(MathJSONFormat, json_str)
            @test parsed.value == 1 // 7
        end
    end

    @testset "Pretty printing" begin
        expr = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
        result = generate(MathJSONFormat, expr; pretty = true)
        @test occursin("\n", result)  # Should have newlines
    end
end
