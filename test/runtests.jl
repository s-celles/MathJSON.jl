using MathJSON
using Test

@testset "MathJSON.jl" begin
    @testset "Module Loading" begin
        @test isdefined(MathJSON, :MathJSONFormat)
        @test MathJSON.MathJSONFormat isa Type
    end

    # Include type system tests
    include("types.jl")

    # Include operator registry tests
    include("operators.jl")

    # Include parser tests
    include("parser.jl")

    # Include generator tests
    include("generator.jl")

    # Include validation tests
    include("validation.jl")

    # Include Symbolics.jl extension tests
    include("symbolics_ext.jl")

    # Include package quality tests
    include("package/aqua.jl")
end
