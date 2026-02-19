using Test
using JSON3
using JSONSchema
using MathJSON: get_registry_path

@testset "Schema Validation" begin
    @testset "categories.json" begin
        schema_path = get_registry_path("schemas/categories.schema.json")
        data_path = get_registry_path("categories.json")

        @test isfile(schema_path)
        @test isfile(data_path)

        schema = Schema(read(schema_path, String))
        data = JSON3.read(read(data_path, String))

        @test isvalid(schema, data)
    end

    @testset "operators.json" begin
        schema_path = get_registry_path("schemas/operators.schema.json")
        data_path = get_registry_path("operators.json")

        @test isfile(schema_path)
        @test isfile(data_path)

        schema = Schema(read(schema_path, String))
        data = JSON3.read(read(data_path, String))

        @test isvalid(schema, data)
    end

    @testset "julia_functions.json" begin
        schema_path = get_registry_path("schemas/julia_functions.schema.json")
        data_path = get_registry_path("julia_functions.json")

        @test isfile(schema_path)
        @test isfile(data_path)

        schema = Schema(read(schema_path, String))
        data = JSON3.read(read(data_path, String))

        @test isvalid(schema, data)
    end

    @testset "Schema structure" begin
        # Test that schemas are valid JSON Schema draft-07
        for schema_file in [
            "schemas/categories.schema.json",
            "schemas/operators.schema.json",
            "schemas/julia_functions.schema.json"
        ]
            path = get_registry_path(schema_file)
            content = read(path, String)
            schema_data = JSON3.read(content)

            @test haskey(schema_data, Symbol("\$schema"))
            @test haskey(schema_data, :type)
            @test haskey(schema_data, :required)
            @test haskey(schema_data, :properties)
        end
    end

    @testset "Data integrity" begin
        # Verify categories file has required structure
        cat_path = get_registry_path("categories.json")
        cat_data = JSON3.read(read(cat_path, String))
        @test haskey(cat_data, :categories)
        @test length(cat_data.categories) >= 8  # At least original 8 categories

        # Verify operators file has required structure
        op_path = get_registry_path("operators.json")
        op_data = JSON3.read(read(op_path, String))
        @test haskey(op_data, :operators)
        @test length(op_data.operators) >= 40  # At least original 40 operators

        # Verify julia_functions file has required structure
        func_path = get_registry_path("julia_functions.json")
        func_data = JSON3.read(read(func_path, String))
        @test haskey(func_data, :mappings)
        @test length(func_data.mappings) >= 37  # At least original 37 mappings

        # Verify all operator category references are valid
        categories = Set(String(c.id) for c in cat_data.categories)
        for op in op_data.operators
            @test String(op.category) in categories
        end

        # Verify all function mapping operator references are valid
        operators = Set(String(o.name) for o in op_data.operators)
        for mapping in func_data.mappings
            @test String(mapping.operator) in operators
        end
    end
end
