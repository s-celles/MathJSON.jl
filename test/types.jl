using Test
using MathJSON
using MathJSON: ExpressionType, AbstractMathJSONExpr, MathJSONParseError,
    UnsupportedConversionError, NumberExpr, SymbolExpr, StringExpr, FunctionExpr,
    metadata, with_metadata, ValidationResult

@testset "Core Type System" begin
    @testset "ExpressionType Enum" begin
        # Test enum exists and is scoped in module
        @test isdefined(MathJSON, :ExpressionType)
        @test isdefined(MathJSON.ExpressionType, :T)

        # Test all enum values exist
        @test isdefined(MathJSON.ExpressionType, :NUMBER)
        @test isdefined(MathJSON.ExpressionType, :SYMBOL)
        @test isdefined(MathJSON.ExpressionType, :STRING)
        @test isdefined(MathJSON.ExpressionType, :FUNCTION)

        # Test enum values are of correct type
        @test ExpressionType.NUMBER isa ExpressionType.T
        @test ExpressionType.SYMBOL isa ExpressionType.T
        @test ExpressionType.STRING isa ExpressionType.T
        @test ExpressionType.FUNCTION isa ExpressionType.T

        # Test enum values are distinct
        @test ExpressionType.NUMBER != ExpressionType.SYMBOL
        @test ExpressionType.STRING != ExpressionType.FUNCTION
    end

    @testset "AbstractMathJSONExpr" begin
        # Test abstract type exists
        @test isdefined(MathJSON, :AbstractMathJSONExpr)
        @test isabstracttype(AbstractMathJSONExpr)
    end

    @testset "MathJSONParseError" begin
        # Test exception type exists and is an Exception
        @test isdefined(MathJSON, :MathJSONParseError)
        @test MathJSONParseError <: Exception

        # Test constructor with message only
        err1 = MathJSONParseError("Invalid JSON")
        @test err1.message == "Invalid JSON"
        @test err1.position === nothing

        # Test constructor with message and position
        err2 = MathJSONParseError("Unexpected token", 42)
        @test err2.message == "Unexpected token"
        @test err2.position == 42

        # Test error can be thrown and caught
        @test_throws MathJSONParseError throw(MathJSONParseError("test"))
    end

    @testset "UnsupportedConversionError" begin
        # Test exception type exists and is an Exception
        @test isdefined(MathJSON, :UnsupportedConversionError)
        @test UnsupportedConversionError <: Exception

        # Test constructor
        err = UnsupportedConversionError("Unknown operator: Foo")
        @test err.message == "Unknown operator: Foo"

        # Test error can be thrown and caught
        @test_throws UnsupportedConversionError throw(UnsupportedConversionError("test"))
    end

    @testset "NumberExpr" begin
        # Test type exists and is a subtype of AbstractMathJSONExpr
        @test isdefined(MathJSON, :NumberExpr)
        @test NumberExpr <: AbstractMathJSONExpr

        @testset "Construction with Int64" begin
            n = NumberExpr(42)
            @test n.value == 42
            @test n.value isa Int64
            @test n.raw === nothing
            @test n.metadata === nothing
        end

        @testset "Construction with Float64" begin
            n = NumberExpr(3.14)
            @test n.value == 3.14
            @test n.value isa Float64
            @test n.raw === nothing
            @test n.metadata === nothing
        end

        @testset "Construction with BigFloat" begin
            bf = BigFloat("3.14159265358979323846264338327950288")
            n = NumberExpr(bf)
            @test n.value == bf
            @test n.value isa BigFloat
        end

        @testset "Construction with Rational" begin
            r = 1 // 3
            n = NumberExpr(r)
            @test n.value == r
            @test n.value isa Rational
        end

        @testset "Construction with extended precision (raw string)" begin
            n = NumberExpr(3.14, "3.14159265358979323846264338327950288")
            @test n.value == 3.14
            @test n.raw == "3.14159265358979323846264338327950288"
            @test n.metadata === nothing
        end

        @testset "Construction with metadata" begin
            meta = Dict{String, Any}("wikidata" => "Q167")
            n = NumberExpr(3.14; metadata = meta)
            @test n.value == 3.14
            @test n.metadata == meta
            @test n.metadata["wikidata"] == "Q167"
        end

        @testset "Full constructor" begin
            meta = Dict{String, Any}("comment" => "pi approximation")
            n = NumberExpr(3.14, "3.14159", meta)
            @test n.value == 3.14
            @test n.raw == "3.14159"
            @test n.metadata == meta
        end

        @testset "Equality" begin
            # Same value, no raw
            @test NumberExpr(42) == NumberExpr(42)
            @test NumberExpr(3.14) == NumberExpr(3.14)

            # Different values
            @test NumberExpr(42) != NumberExpr(43)

            # Same value, different raw (should still be equal based on value)
            @test NumberExpr(3.14) == NumberExpr(3.14, "3.14159")

            # Metadata doesn't affect equality
            @test NumberExpr(42) == NumberExpr(42; metadata = Dict{String, Any}("x" => 1))
        end

        @testset "Base.show" begin
            n = NumberExpr(42)
            io = IOBuffer()
            show(io, n)
            @test String(take!(io)) == "NumberExpr(42)"

            n_raw = NumberExpr(3.14, "3.14159...")
            show(io, n_raw)
            @test occursin("NumberExpr", String(take!(io)))
        end

        @testset "Special values" begin
            # NaN
            n_nan = NumberExpr(NaN)
            @test isnan(n_nan.value)

            # Infinity
            n_inf = NumberExpr(Inf)
            @test isinf(n_inf.value)
            @test n_inf.value > 0

            # Negative infinity
            n_ninf = NumberExpr(-Inf)
            @test isinf(n_ninf.value)
            @test n_ninf.value < 0
        end
    end

    @testset "SymbolExpr" begin
        # Test type exists and is a subtype of AbstractMathJSONExpr
        @test isdefined(MathJSON, :SymbolExpr)
        @test SymbolExpr <: AbstractMathJSONExpr

        @testset "Basic construction" begin
            s = SymbolExpr("x")
            @test s.name == "x"
            @test s.metadata === nothing
        end

        @testset "Construction with metadata" begin
            meta = Dict{String, Any}("wikidata" => "Q12345")
            s = SymbolExpr("Pi"; metadata = meta)
            @test s.name == "Pi"
            @test s.metadata == meta
        end

        @testset "Unicode NFC normalization" begin
            # é composed (U+00E9) vs decomposed (e + U+0301)
            composed = "café"
            decomposed = "cafe\u0301"
            @test composed != decomposed  # Different byte sequences

            s1 = SymbolExpr(composed)
            s2 = SymbolExpr(decomposed)
            @test s1.name == s2.name  # Should be normalized to same form
        end

        @testset "Valid identifier formats" begin
            # Simple alphanumeric
            @test SymbolExpr("x").name == "x"
            @test SymbolExpr("x1").name == "x1"
            @test SymbolExpr("myVar").name == "myVar"

            # With underscores
            @test SymbolExpr("my_var").name == "my_var"
            @test SymbolExpr("_private").name == "_private"

            # PascalCase constants
            @test SymbolExpr("Pi").name == "Pi"
            @test SymbolExpr("ExponentialE").name == "ExponentialE"

            # Backtick-wrapped for non-standard names
            @test SymbolExpr("`x+y`").name == "`x+y`"
            @test SymbolExpr("`my var`").name == "`my var`"
        end

        @testset "Equality" begin
            @test SymbolExpr("x") == SymbolExpr("x")
            @test SymbolExpr("x") != SymbolExpr("y")

            # Metadata doesn't affect equality
            @test SymbolExpr("x") == SymbolExpr("x"; metadata = Dict{String, Any}("a" => 1))
        end

        @testset "Base.show" begin
            s = SymbolExpr("x")
            io = IOBuffer()
            show(io, s)
            @test String(take!(io)) == "SymbolExpr(\"x\")"
        end
    end

    @testset "StringExpr" begin
        # Test type exists and is a subtype of AbstractMathJSONExpr
        @test isdefined(MathJSON, :StringExpr)
        @test StringExpr <: AbstractMathJSONExpr

        @testset "Basic construction" begin
            s = StringExpr("hello")
            @test s.value == "hello"
            @test s.metadata === nothing
        end

        @testset "Construction with metadata" begin
            meta = Dict{String, Any}("comment" => "greeting")
            s = StringExpr("hello"; metadata = meta)
            @test s.value == "hello"
            @test s.metadata == meta
        end

        @testset "Empty string" begin
            s = StringExpr("")
            @test s.value == ""
        end

        @testset "Unicode strings" begin
            s = StringExpr("こんにちは")
            @test s.value == "こんにちは"
        end

        @testset "Equality" begin
            @test StringExpr("hello") == StringExpr("hello")
            @test StringExpr("hello") != StringExpr("world")

            # Metadata doesn't affect equality
            @test StringExpr("hi") == StringExpr("hi"; metadata = Dict{String, Any}("x" => 1))
        end

        @testset "Base.show" begin
            s = StringExpr("hello")
            io = IOBuffer()
            show(io, s)
            @test String(take!(io)) == "StringExpr(\"hello\")"
        end
    end

    @testset "FunctionExpr" begin
        # Test type exists and is a subtype of AbstractMathJSONExpr
        @test isdefined(MathJSON, :FunctionExpr)
        @test FunctionExpr <: AbstractMathJSONExpr

        @testset "Basic construction" begin
            f = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            @test f.operator == :Add
            @test length(f.arguments) == 2
            @test f.metadata === nothing
        end

        @testset "Construction with metadata" begin
            meta = Dict{String, Any}("latex" => "1 + 2")
            f = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]; metadata = meta)
            @test f.operator == :Add
            @test f.metadata == meta
        end

        @testset "Empty arguments" begin
            f = FunctionExpr(:Random, AbstractMathJSONExpr[])
            @test f.operator == :Random
            @test isempty(f.arguments)
        end

        @testset "Nested expressions" begin
            # (1 + 2) * 3
            inner = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            outer = FunctionExpr(:Multiply, [inner, NumberExpr(3)])

            @test outer.operator == :Multiply
            @test length(outer.arguments) == 2
            @test outer.arguments[1] isa FunctionExpr
            @test outer.arguments[1].operator == :Add
        end

        @testset "Mixed argument types" begin
            # sin(x) where x is a symbol
            f = FunctionExpr(:Sin, [SymbolExpr("x")])
            @test f.arguments[1] isa SymbolExpr
            @test f.arguments[1].name == "x"
        end

        @testset "Equality" begin
            f1 = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            f2 = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            f3 = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(3)])
            f4 = FunctionExpr(:Multiply, [NumberExpr(1), NumberExpr(2)])

            @test f1 == f2
            @test f1 != f3  # Different argument
            @test f1 != f4  # Different operator

            # Nested equality
            nested1 = FunctionExpr(:Multiply, [FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]), NumberExpr(3)])
            nested2 = FunctionExpr(:Multiply, [FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]), NumberExpr(3)])
            @test nested1 == nested2

            # Metadata doesn't affect equality
            @test f1 == FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)]; metadata = Dict{String, Any}("x" => 1))
        end

        @testset "Base.show" begin
            f = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            io = IOBuffer()
            show(io, f)
            output = String(take!(io))
            @test occursin("FunctionExpr", output)
            @test occursin("Add", output)
        end
    end

    @testset "Metadata Utilities" begin
        @testset "metadata accessor" begin
            # NumberExpr
            n1 = NumberExpr(42)
            @test metadata(n1) === nothing

            n2 = NumberExpr(42; metadata = Dict{String, Any}("wikidata" => "Q167"))
            @test metadata(n2) == Dict{String, Any}("wikidata" => "Q167")

            # SymbolExpr
            s1 = SymbolExpr("x")
            @test metadata(s1) === nothing

            s2 = SymbolExpr("Pi"; metadata = Dict{String, Any}("constant" => true))
            @test metadata(s2) == Dict{String, Any}("constant" => true)

            # StringExpr
            str1 = StringExpr("hello")
            @test metadata(str1) === nothing

            # FunctionExpr
            f1 = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            @test metadata(f1) === nothing

            f2 = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)];
                metadata = Dict{String, Any}("latex" => "1+2"))
            @test metadata(f2) == Dict{String, Any}("latex" => "1+2")
        end

        @testset "with_metadata (single key-value)" begin
            # NumberExpr
            n1 = NumberExpr(42)
            n2 = with_metadata(n1, "wikidata", "Q167")
            @test metadata(n2) == Dict{String, Any}("wikidata" => "Q167")
            @test n2.value == 42
            @test metadata(n1) === nothing  # Original unchanged

            # SymbolExpr
            s1 = SymbolExpr("x")
            s2 = with_metadata(s1, "comment", "variable")
            @test metadata(s2) == Dict{String, Any}("comment" => "variable")
            @test s2.name == "x"

            # StringExpr
            str1 = StringExpr("hello")
            str2 = with_metadata(str1, "lang", "en")
            @test metadata(str2) == Dict{String, Any}("lang" => "en")

            # FunctionExpr
            f1 = FunctionExpr(:Add, [NumberExpr(1), NumberExpr(2)])
            f2 = with_metadata(f1, "latex", "1+2")
            @test metadata(f2) == Dict{String, Any}("latex" => "1+2")
            @test f2.operator == :Add

            # Adding to existing metadata
            n3 = NumberExpr(42; metadata = Dict{String, Any}("a" => 1))
            n4 = with_metadata(n3, "b", 2)
            @test metadata(n4) == Dict{String, Any}("a" => 1, "b" => 2)
        end

        @testset "with_metadata (dict)" begin
            n1 = NumberExpr(42)
            new_meta = Dict{String, Any}("wikidata" => "Q167", "comment" => "pi")
            n2 = with_metadata(n1, new_meta)
            @test metadata(n2) == new_meta
            @test n2.value == 42

            # Replace existing metadata
            n3 = NumberExpr(42; metadata = Dict{String, Any}("old" => "value"))
            n4 = with_metadata(n3, Dict{String, Any}("new" => "value"))
            @test metadata(n4) == Dict{String, Any}("new" => "value")
        end
    end

    @testset "ValidationResult" begin
        @test isdefined(MathJSON, :ValidationResult)

        # Valid result
        vr1 = ValidationResult(true, String[])
        @test vr1.valid == true
        @test isempty(vr1.errors)

        # Invalid result with errors
        vr2 = ValidationResult(false, ["Error 1", "Error 2"])
        @test vr2.valid == false
        @test length(vr2.errors) == 2
        @test "Error 1" in vr2.errors
    end
end
