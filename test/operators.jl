using Test
using MathJSON
using MathJSON: OperatorCategory, OPERATORS, JULIA_FUNCTIONS,
    get_category, get_julia_function, is_known_operator

@testset "Operator Registry" begin
    @testset "OperatorCategory Enum" begin
        @test isdefined(MathJSON, :OperatorCategory)
        @test isdefined(MathJSON.OperatorCategory, :T)

        # Test all Cortex category values exist
        @test OperatorCategory.ARITHMETIC isa OperatorCategory.T
        @test OperatorCategory.CALCULUS isa OperatorCategory.T
        @test OperatorCategory.COLLECTIONS isa OperatorCategory.T
        @test OperatorCategory.COLORS isa OperatorCategory.T
        @test OperatorCategory.COMBINATORICS isa OperatorCategory.T
        @test OperatorCategory.CONTROL_STRUCTURES isa OperatorCategory.T
        @test OperatorCategory.CORE isa OperatorCategory.T
        @test OperatorCategory.LINEAR_ALGEBRA isa OperatorCategory.T
        @test OperatorCategory.LOGIC isa OperatorCategory.T
        @test OperatorCategory.NUMBER_THEORY isa OperatorCategory.T
        @test OperatorCategory.POLYNOMIALS isa OperatorCategory.T
        @test OperatorCategory.RELATIONAL_OPERATORS isa OperatorCategory.T
        @test OperatorCategory.STATISTICS isa OperatorCategory.T
        @test OperatorCategory.TRIGONOMETRY isa OperatorCategory.T
        @test OperatorCategory.UNITS isa OperatorCategory.T
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
        @test OPERATORS[:Exp] == OperatorCategory.ARITHMETIC
        @test OPERATORS[:Ln] == OperatorCategory.ARITHMETIC
        @test OPERATORS[:Log] == OperatorCategory.ARITHMETIC

        # Trigonometry operators
        @test OPERATORS[:Sin] == OperatorCategory.TRIGONOMETRY
        @test OPERATORS[:Cos] == OperatorCategory.TRIGONOMETRY
        @test OPERATORS[:Tan] == OperatorCategory.TRIGONOMETRY
        @test OPERATORS[:Arcsin] == OperatorCategory.TRIGONOMETRY
        @test OPERATORS[:Arccos] == OperatorCategory.TRIGONOMETRY
        @test OPERATORS[:Arctan] == OperatorCategory.TRIGONOMETRY

        # Relational operators
        @test OPERATORS[:Equal] == OperatorCategory.RELATIONAL_OPERATORS
        @test OPERATORS[:NotEqual] == OperatorCategory.RELATIONAL_OPERATORS
        @test OPERATORS[:Less] == OperatorCategory.RELATIONAL_OPERATORS
        @test OPERATORS[:Greater] == OperatorCategory.RELATIONAL_OPERATORS
        @test OPERATORS[:LessEqual] == OperatorCategory.RELATIONAL_OPERATORS
        @test OPERATORS[:GreaterEqual] == OperatorCategory.RELATIONAL_OPERATORS

        # Logic operators
        @test OPERATORS[:And] == OperatorCategory.LOGIC
        @test OPERATORS[:Or] == OperatorCategory.LOGIC
        @test OPERATORS[:Not] == OperatorCategory.LOGIC

        # Collections operators
        @test OPERATORS[:Union] == OperatorCategory.COLLECTIONS
        @test OPERATORS[:Intersection] == OperatorCategory.COLLECTIONS
        @test OPERATORS[:SetMinus] == OperatorCategory.COLLECTIONS

        # Calculus operators
        @test OPERATORS[:D] == OperatorCategory.CALCULUS
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

        # Logarithmic (now in Arithmetic)
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
        @test get_category(:Sin) == OperatorCategory.TRIGONOMETRY
        @test get_category(:Log) == OperatorCategory.ARITHMETIC
        @test get_category(:Equal) == OperatorCategory.RELATIONAL_OPERATORS
        @test get_category(:And) == OperatorCategory.LOGIC
        @test get_category(:Union) == OperatorCategory.COLLECTIONS
        @test get_category(:D) == OperatorCategory.CALCULUS

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
        @test is_known_operator(:D) == true

        @test is_known_operator(:CustomOp) == false
        @test is_known_operator(:Foo) == false
    end
end
