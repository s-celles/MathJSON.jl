using Test
using MathJSON
using MathJSON: RegistryLoadError, CategoryInfo, OperatorInfo
using MathJSON: load_categories, load_operators, load_julia_functions, get_registry_path
using MathJSON: SPECIAL_FUNCTIONS

@testset "Registry Loader" begin
    @testset "Data Types" begin
        @testset "CategoryInfo" begin
            cat = CategoryInfo("ARITHMETIC", "Arithmetic", "Basic math operations")
            @test cat.id == "ARITHMETIC"
            @test cat.name == "Arithmetic"
            @test cat.description == "Basic math operations"
        end

        @testset "OperatorInfo" begin
            op = OperatorInfo(:Add, "ARITHMETIC", "variadic", "Addition", ["Plus", "Sum"])
            @test op.name == :Add
            @test op.category == "ARITHMETIC"
            @test op.arity == "variadic"
            @test op.description == "Addition"
            @test op.aliases == ["Plus", "Sum"]

            # Test with minimal fields
            op_minimal = OperatorInfo(:Sin, "TRIGONOMETRIC", nothing, nothing, String[])
            @test op_minimal.name == :Sin
            @test op_minimal.category == "TRIGONOMETRIC"
            @test op_minimal.arity === nothing
            @test op_minimal.description === nothing
            @test op_minimal.aliases == String[]
        end

        @testset "RegistryLoadError" begin
            err = RegistryLoadError("/path/to/file.json", "File not found")
            @test err.path == "/path/to/file.json"
            @test err.details == "File not found"
            @test occursin("/path/to/file.json", sprint(showerror, err))
            @test occursin("File not found", sprint(showerror, err))
        end
    end

    @testset "Path Resolution" begin
        @testset "get_registry_path" begin
            path = get_registry_path("categories.json")
            @test isfile(path)
            @test endswith(path, "data/categories.json") || endswith(path, "data\\categories.json")

            schema_path = get_registry_path("schemas/categories.schema.json")
            @test isfile(schema_path)
        end
    end

    @testset "Category Loading" begin
        @testset "load_categories success" begin
            path = get_registry_path("categories.json")
            categories = load_categories(path)

            @test categories isa Dict{String,CategoryInfo}
            @test haskey(categories, "ARITHMETIC")
            @test haskey(categories, "TRIGONOMETRIC")
            @test haskey(categories, "UNKNOWN")

            arith = categories["ARITHMETIC"]
            @test arith.id == "ARITHMETIC"
            @test arith.name == "Arithmetic"
            @test !isempty(arith.description)
        end

        @testset "load_categories file not found" begin
            @test_throws RegistryLoadError load_categories("/nonexistent/path.json")
            try
                load_categories("/nonexistent/path.json")
            catch e
                @test e isa RegistryLoadError
                @test occursin("/nonexistent/path.json", e.path)
            end
        end

        @testset "load_categories malformed JSON" begin
            # Create a temporary malformed JSON file
            tmpfile = tempname() * ".json"
            write(tmpfile, "{ invalid json }")
            @test_throws RegistryLoadError load_categories(tmpfile)
            rm(tmpfile)
        end
    end

    @testset "Operator Loading" begin
        @testset "load_operators success" begin
            cat_path = get_registry_path("categories.json")
            categories = load_categories(cat_path)

            op_path = get_registry_path("operators.json")
            operators = load_operators(op_path, categories)

            @test operators isa Dict{Symbol,OperatorInfo}
            @test haskey(operators, :Add)
            @test haskey(operators, :Sin)
            @test haskey(operators, :Derivative)

            add_op = operators[:Add]
            @test add_op.name == :Add
            @test add_op.category == "ARITHMETIC"
        end

        @testset "load_operators invalid category reference" begin
            categories = Dict{String,CategoryInfo}()  # Empty categories

            tmpfile = tempname() * ".json"
            write(tmpfile, """{"operators": [{"name": "Add", "category": "INVALID"}]}""")

            @test_throws RegistryLoadError load_operators(tmpfile, categories)
            try
                load_operators(tmpfile, categories)
            catch e
                @test e isa RegistryLoadError
                @test occursin("INVALID", e.details)
            end
            rm(tmpfile)
        end
    end

    @testset "Julia Function Loading" begin
        @testset "load_julia_functions success" begin
            cat_path = get_registry_path("categories.json")
            categories = load_categories(cat_path)

            op_path = get_registry_path("operators.json")
            operators = load_operators(op_path, categories)

            func_path = get_registry_path("julia_functions.json")
            functions = load_julia_functions(func_path, operators)

            @test functions isa Dict{Symbol,Union{Function,Nothing}}

            # Test mapped functions
            @test functions[:Add] === +
            @test functions[:Sin] === sin
            @test functions[:Exp] === exp

            # Test unmapped operators return nothing
            @test functions[:Derivative] === nothing

            # Test special functions
            @test functions[:And] isa Function
            @test functions[:And](true, true) == true
            @test functions[:And](true, false) == false

            @test functions[:Or] isa Function
            @test functions[:Or](true, false) == true
        end

        @testset "load_julia_functions invalid operator reference" begin
            operators = Dict{Symbol,OperatorInfo}()  # Empty operators

            tmpfile = tempname() * ".json"
            write(tmpfile, """{"mappings": [{"operator": "Unknown", "julia_function": "+"}]}""")

            @test_throws RegistryLoadError load_julia_functions(tmpfile, operators)
            rm(tmpfile)
        end
    end

    @testset "Special Functions" begin
        @test haskey(SPECIAL_FUNCTIONS, "logical_and")
        @test haskey(SPECIAL_FUNCTIONS, "logical_or")

        @test SPECIAL_FUNCTIONS["logical_and"](true, true) == true
        @test SPECIAL_FUNCTIONS["logical_and"](true, false) == false
        @test SPECIAL_FUNCTIONS["logical_or"](false, true) == true
        @test SPECIAL_FUNCTIONS["logical_or"](false, false) == false
    end
end
