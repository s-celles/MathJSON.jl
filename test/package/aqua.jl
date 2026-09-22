using Aqua
using MathJSON

@testset "Aqua.jl Quality Tests" begin
    Aqua.test_all(
        MathJSON;
        ambiguities = false,  # Will enable once we have more methods
        stale_deps = (ignore = [:JSON],),  # JSON is used through the parser and generator
    )
end
