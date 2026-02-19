using Test
using MathJSON
using MathJSON: OperatorCategory, OPERATORS, JULIA_FUNCTIONS,
    get_category, get_julia_function, is_known_operator

@testset "Backward Compatibility" begin
    # Baseline data from original hardcoded implementation
    # These tests ensure the JSON-loaded registry produces identical results

    @testset "OperatorCategory Enum Values" begin
        # All original enum values must remain accessible
        @test OperatorCategory.ARITHMETIC isa OperatorCategory.T
        @test OperatorCategory.TRIGONOMETRIC isa OperatorCategory.T
        @test OperatorCategory.LOGARITHMIC isa OperatorCategory.T
        @test OperatorCategory.COMPARISON isa OperatorCategory.T
        @test OperatorCategory.LOGICAL isa OperatorCategory.T
        @test OperatorCategory.SET isa OperatorCategory.T
        @test OperatorCategory.CALCULUS isa OperatorCategory.T
        @test OperatorCategory.UNKNOWN isa OperatorCategory.T

        # New categories should also be accessible
        @test OperatorCategory.TRIGONOMETRY isa OperatorCategory.T
        @test OperatorCategory.COLLECTIONS isa OperatorCategory.T
        @test OperatorCategory.COMPLEX isa OperatorCategory.T
        @test OperatorCategory.SPECIAL_FUNCTIONS isa OperatorCategory.T
    end

    @testset "Original Operator Categories" begin
        # Baseline: all original operators must map to same categories
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
            # Trigonometric operators
            :Sin => OperatorCategory.TRIGONOMETRIC,
            :Cos => OperatorCategory.TRIGONOMETRIC,
            :Tan => OperatorCategory.TRIGONOMETRIC,
            :Arcsin => OperatorCategory.TRIGONOMETRIC,
            :Arccos => OperatorCategory.TRIGONOMETRIC,
            :Arctan => OperatorCategory.TRIGONOMETRIC,
            :Sinh => OperatorCategory.TRIGONOMETRIC,
            :Cosh => OperatorCategory.TRIGONOMETRIC,
            :Tanh => OperatorCategory.TRIGONOMETRIC,
            :Arcsinh => OperatorCategory.TRIGONOMETRIC,
            :Arccosh => OperatorCategory.TRIGONOMETRIC,
            :Arctanh => OperatorCategory.TRIGONOMETRIC,
            # Logarithmic operators
            :Log => OperatorCategory.LOGARITHMIC,
            :Ln => OperatorCategory.LOGARITHMIC,
            :Exp => OperatorCategory.LOGARITHMIC,
            :Log10 => OperatorCategory.LOGARITHMIC,
            :Log2 => OperatorCategory.LOGARITHMIC,
            # Comparison operators
            :Equal => OperatorCategory.COMPARISON,
            :NotEqual => OperatorCategory.COMPARISON,
            :Less => OperatorCategory.COMPARISON,
            :Greater => OperatorCategory.COMPARISON,
            :LessEqual => OperatorCategory.COMPARISON,
            :GreaterEqual => OperatorCategory.COMPARISON,
            # Logical operators
            :And => OperatorCategory.LOGICAL,
            :Or => OperatorCategory.LOGICAL,
            :Not => OperatorCategory.LOGICAL,
            # Set operators
            :Union => OperatorCategory.SET,
            :Intersection => OperatorCategory.SET,
            :SetMinus => OperatorCategory.SET,
            # Calculus operators
            :Derivative => OperatorCategory.CALCULUS,
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
        @test get_julia_function(:Derivative) === nothing
        @test get_julia_function(:Integrate) === nothing
    end

    @testset "is_known_operator API" begin
        # All original operators should be recognized
        original_operators = [
            :Add, :Subtract, :Multiply, :Divide, :Power, :Negate, :Root, :Sqrt, :Abs,
            :Sin, :Cos, :Tan, :Arcsin, :Arccos, :Arctan,
            :Sinh, :Cosh, :Tanh, :Arcsinh, :Arccosh, :Arctanh,
            :Log, :Ln, :Exp, :Log10, :Log2,
            :Equal, :NotEqual, :Less, :Greater, :LessEqual, :GreaterEqual,
            :And, :Or, :Not,
            :Union, :Intersection, :SetMinus,
            :Derivative, :Integrate
        ]

        for op in original_operators
            @test is_known_operator(op) == true
        end

        # Unknown operators
        @test is_known_operator(:CustomOp) == false
        @test is_known_operator(:Foo) == false
    end

    @testset "get_category API" begin
        # Test same behavior as before
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

    @testset "Dictionary Types" begin
        @test OPERATORS isa Dict{Symbol,OperatorCategory.T}
        @test JULIA_FUNCTIONS isa Dict{Symbol,Function}
    end
end
