using Test
using MathJSON
using MathJSON: OperatorCategory, OPERATORS, JULIA_FUNCTIONS,
    get_category, get_julia_function, is_known_operator

@testset "Backward Compatibility" begin
    # Baseline data now using Cortex Compute Engine categories
    # These tests ensure the JSON-loaded registry produces correct results

    @testset "OperatorCategory Enum Values" begin
        # All Cortex categories must be accessible
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

    @testset "Cortex Operator Categories" begin
        # Baseline: operators must map to correct Cortex categories
        baseline_categories = Dict{Symbol,OperatorCategory.T}(
            # Arithmetic operators
            :Add => OperatorCategory.ARITHMETIC,
            :Subtract => OperatorCategory.ARITHMETIC,
            :Multiply => OperatorCategory.ARITHMETIC,
            :Divide => OperatorCategory.ARITHMETIC,
            :Power => OperatorCategory.ARITHMETIC,
            :Negate => OperatorCategory.ARITHMETIC,
            :Root => OperatorCategory.ARITHMETIC,
            :Sqrt => OperatorCategory.ARITHMETIC,
            :Abs => OperatorCategory.ARITHMETIC,
            :Exp => OperatorCategory.ARITHMETIC,
            :Ln => OperatorCategory.ARITHMETIC,
            :Log => OperatorCategory.ARITHMETIC,
            :Log10 => OperatorCategory.ARITHMETIC,
            :Log2 => OperatorCategory.ARITHMETIC,
            # Trigonometry operators
            :Sin => OperatorCategory.TRIGONOMETRY,
            :Cos => OperatorCategory.TRIGONOMETRY,
            :Tan => OperatorCategory.TRIGONOMETRY,
            :Arcsin => OperatorCategory.TRIGONOMETRY,
            :Arccos => OperatorCategory.TRIGONOMETRY,
            :Arctan => OperatorCategory.TRIGONOMETRY,
            :Sinh => OperatorCategory.TRIGONOMETRY,
            :Cosh => OperatorCategory.TRIGONOMETRY,
            :Tanh => OperatorCategory.TRIGONOMETRY,
            :Arsinh => OperatorCategory.TRIGONOMETRY,
            :Arcosh => OperatorCategory.TRIGONOMETRY,
            :Artanh => OperatorCategory.TRIGONOMETRY,
            # Relational operators
            :Equal => OperatorCategory.RELATIONAL_OPERATORS,
            :NotEqual => OperatorCategory.RELATIONAL_OPERATORS,
            :Less => OperatorCategory.RELATIONAL_OPERATORS,
            :Greater => OperatorCategory.RELATIONAL_OPERATORS,
            :LessEqual => OperatorCategory.RELATIONAL_OPERATORS,
            :GreaterEqual => OperatorCategory.RELATIONAL_OPERATORS,
            # Logic operators
            :And => OperatorCategory.LOGIC,
            :Or => OperatorCategory.LOGIC,
            :Not => OperatorCategory.LOGIC,
            # Collections operators
            :Union => OperatorCategory.COLLECTIONS,
            :Intersection => OperatorCategory.COLLECTIONS,
            :SetMinus => OperatorCategory.COLLECTIONS,
            # Calculus operators
            :D => OperatorCategory.CALCULUS,
            :Integrate => OperatorCategory.CALCULUS
        )

        for (op, expected_cat) in baseline_categories
            @test get_category(op) == expected_cat
            @test OPERATORS[op] == expected_cat
        end
    end

    @testset "Original Julia Functions" begin
        # Baseline: all original function mappings must work identically
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
        @test JULIA_FUNCTIONS[:Arcsin](0) == 0.0
        @test JULIA_FUNCTIONS[:Arccos](1) == 0.0

        # Logarithmic
        @test JULIA_FUNCTIONS[:Exp](0) == 1.0
        @test JULIA_FUNCTIONS[:Log10](10) == 1.0
        @test JULIA_FUNCTIONS[:Log2](2) == 1.0

        # Comparison
        @test JULIA_FUNCTIONS[:Equal](3, 3) == true
        @test JULIA_FUNCTIONS[:NotEqual](3, 4) == true
        @test JULIA_FUNCTIONS[:Less](3, 4) == true
        @test JULIA_FUNCTIONS[:Greater](4, 3) == true

        # Logical
        @test JULIA_FUNCTIONS[:And](true, true) == true
        @test JULIA_FUNCTIONS[:And](true, false) == false
        @test JULIA_FUNCTIONS[:Or](true, false) == true
        @test JULIA_FUNCTIONS[:Not](true) == false
    end

    @testset "get_julia_function API" begin
        # Function references should match
        @test get_julia_function(:Add) === +
        @test get_julia_function(:Sin) === sin
        @test get_julia_function(:Exp) === exp
        @test get_julia_function(:Log) === log

        # Unknown operators return nothing
        @test get_julia_function(:CustomOp) === nothing
        @test get_julia_function(:NonExistent) === nothing

        # Operators without Julia mapping
        @test get_julia_function(:D) === nothing
        @test get_julia_function(:Integrate) === nothing
    end

    @testset "is_known_operator API" begin
        # All Cortex operators should be recognized
        cortex_operators = [
            :Add, :Subtract, :Multiply, :Divide, :Power, :Negate, :Root, :Sqrt, :Abs,
            :Sin, :Cos, :Tan, :Arcsin, :Arccos, :Arctan,
            :Sinh, :Cosh, :Tanh, :Arsinh, :Arcosh, :Artanh,
            :Log, :Ln, :Exp, :Log10, :Log2,
            :Equal, :NotEqual, :Less, :Greater, :LessEqual, :GreaterEqual,
            :And, :Or, :Not,
            :Union, :Intersection, :SetMinus,
            :D, :Integrate
        ]

        for op in cortex_operators
            @test is_known_operator(op) == true
        end

        # Unknown operators
        @test is_known_operator(:CustomOp) == false
        @test is_known_operator(:Foo) == false
    end

    @testset "get_category API" begin
        # Test same behavior with new categories
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

    @testset "Dictionary Types" begin
        @test OPERATORS isa Dict{Symbol,OperatorCategory.T}
        @test JULIA_FUNCTIONS isa Dict{Symbol,Function}
    end
end
