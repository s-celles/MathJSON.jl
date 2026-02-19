using Test
using MathJSON
using MathJSON: OperatorCategory, OPERATORS, JULIA_FUNCTIONS,
    get_category, get_julia_function, is_known_operator

@testset "Operator Registry" begin
    @testset "OperatorCategory Enum" begin
        @test isdefined(MathJSON, :OperatorCategory)
        @test isdefined(MathJSON.OperatorCategory, :T)

        # Test all category values exist
        @test OperatorCategory.ARITHMETIC isa OperatorCategory.T
        @test OperatorCategory.TRIGONOMETRIC isa OperatorCategory.T
        @test OperatorCategory.LOGARITHMIC isa OperatorCategory.T
        @test OperatorCategory.COMPARISON isa OperatorCategory.T
        @test OperatorCategory.LOGICAL isa OperatorCategory.T
        @test OperatorCategory.SET isa OperatorCategory.T
        @test OperatorCategory.CALCULUS isa OperatorCategory.T
        @test OperatorCategory.UNKNOWN isa OperatorCategory.T
    end

    @testset "OPERATORS Dictionary" begin
        @test OPERATORS isa Dict{Symbol, OperatorCategory.T}

        # Arithmetic operators
        @test OPERATORS[:Add] == OperatorCategory.ARITHMETIC
        @test OPERATORS[:Subtract] == OperatorCategory.ARITHMETIC
        @test OPERATORS[:Multiply] == OperatorCategory.ARITHMETIC
        @test OPERATORS[:Divide] == OperatorCategory.ARITHMETIC
        @test OPERATORS[:Power] == OperatorCategory.ARITHMETIC
        @test OPERATORS[:Negate] == OperatorCategory.ARITHMETIC

        # Trigonometric operators
        @test OPERATORS[:Sin] == OperatorCategory.TRIGONOMETRIC
        @test OPERATORS[:Cos] == OperatorCategory.TRIGONOMETRIC
        @test OPERATORS[:Tan] == OperatorCategory.TRIGONOMETRIC
        @test OPERATORS[:Arcsin] == OperatorCategory.TRIGONOMETRIC
        @test OPERATORS[:Arccos] == OperatorCategory.TRIGONOMETRIC
        @test OPERATORS[:Arctan] == OperatorCategory.TRIGONOMETRIC

        # Logarithmic operators
        @test OPERATORS[:Log] == OperatorCategory.LOGARITHMIC
        @test OPERATORS[:Ln] == OperatorCategory.LOGARITHMIC
        @test OPERATORS[:Exp] == OperatorCategory.LOGARITHMIC

        # Comparison operators
        @test OPERATORS[:Equal] == OperatorCategory.COMPARISON
        @test OPERATORS[:NotEqual] == OperatorCategory.COMPARISON
        @test OPERATORS[:Less] == OperatorCategory.COMPARISON
        @test OPERATORS[:Greater] == OperatorCategory.COMPARISON
        @test OPERATORS[:LessEqual] == OperatorCategory.COMPARISON
        @test OPERATORS[:GreaterEqual] == OperatorCategory.COMPARISON

        # Logical operators
        @test OPERATORS[:And] == OperatorCategory.LOGICAL
        @test OPERATORS[:Or] == OperatorCategory.LOGICAL
        @test OPERATORS[:Not] == OperatorCategory.LOGICAL

        # Set operators
        @test OPERATORS[:Union] == OperatorCategory.SET
        @test OPERATORS[:Intersection] == OperatorCategory.SET
        @test OPERATORS[:SetMinus] == OperatorCategory.SET

        # Calculus operators
        @test OPERATORS[:Derivative] == OperatorCategory.CALCULUS
        @test OPERATORS[:Integrate] == OperatorCategory.CALCULUS
    end

    @testset "JULIA_FUNCTIONS Dictionary" begin
        @test JULIA_FUNCTIONS isa Dict{Symbol, Function}

        # Arithmetic
        @test JULIA_FUNCTIONS[:Add](2, 3) == 5
        @test JULIA_FUNCTIONS[:Subtract](5, 3) == 2
        @test JULIA_FUNCTIONS[:Multiply](4, 3) == 12
        @test JULIA_FUNCTIONS[:Divide](10, 2) == 5.0
        @test JULIA_FUNCTIONS[:Power](2, 3) == 8
        @test JULIA_FUNCTIONS[:Negate](5) == -5
        @test JULIA_FUNCTIONS[:Sqrt](4) == 2.0
        @test JULIA_FUNCTIONS[:Abs](-5) == 5

        # Trigonometric
        @test JULIA_FUNCTIONS[:Sin](0) == 0.0
        @test JULIA_FUNCTIONS[:Cos](0) == 1.0
        @test isapprox(JULIA_FUNCTIONS[:Tan](π/4), 1.0, atol=1e-10)
        @test JULIA_FUNCTIONS[:Arcsin](0) == 0.0
        @test JULIA_FUNCTIONS[:Arccos](1) == 0.0
        @test JULIA_FUNCTIONS[:Arctan](0) == 0.0

        # Logarithmic
        @test JULIA_FUNCTIONS[:Exp](0) == 1.0
        @test JULIA_FUNCTIONS[:Ln](ℯ) ≈ 1.0
        @test JULIA_FUNCTIONS[:Log](ℯ) ≈ 1.0
        @test JULIA_FUNCTIONS[:Log10](10) == 1.0
        @test JULIA_FUNCTIONS[:Log2](2) == 1.0

        # Comparison
        @test JULIA_FUNCTIONS[:Equal](3, 3) == true
        @test JULIA_FUNCTIONS[:NotEqual](3, 4) == true
        @test JULIA_FUNCTIONS[:Less](3, 4) == true
        @test JULIA_FUNCTIONS[:Greater](4, 3) == true
        @test JULIA_FUNCTIONS[:LessEqual](3, 3) == true
        @test JULIA_FUNCTIONS[:GreaterEqual](4, 3) == true

        # Logical
        @test JULIA_FUNCTIONS[:And](true, true) == true
        @test JULIA_FUNCTIONS[:And](true, false) == false
        @test JULIA_FUNCTIONS[:Or](true, false) == true
        @test JULIA_FUNCTIONS[:Not](true) == false
    end

    @testset "get_category" begin
        @test get_category(:Add) == OperatorCategory.ARITHMETIC
        @test get_category(:Sin) == OperatorCategory.TRIGONOMETRIC
        @test get_category(:Log) == OperatorCategory.LOGARITHMIC
        @test get_category(:Equal) == OperatorCategory.COMPARISON
        @test get_category(:And) == OperatorCategory.LOGICAL
        @test get_category(:Union) == OperatorCategory.SET
        @test get_category(:Derivative) == OperatorCategory.CALCULUS

        # Unknown operator returns UNKNOWN
        @test get_category(:CustomOp) == OperatorCategory.UNKNOWN
        @test get_category(:Foo) == OperatorCategory.UNKNOWN
    end

    @testset "get_julia_function" begin
        @test get_julia_function(:Add) === +
        @test get_julia_function(:Sin) === sin
        @test get_julia_function(:Exp) === exp

        # Unknown operator returns nothing
        @test get_julia_function(:CustomOp) === nothing
        @test get_julia_function(:Foo) === nothing
    end

    @testset "is_known_operator" begin
        @test is_known_operator(:Add) == true
        @test is_known_operator(:Sin) == true
        @test is_known_operator(:Derivative) == true

        @test is_known_operator(:CustomOp) == false
        @test is_known_operator(:Foo) == false
    end
end
