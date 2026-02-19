using Aqua
using MathJSON

@testset "Aqua.jl Quality Tests" begin
    Aqua.test_all(
        MathJSON;
        ambiguities = false,  # Will enable once we have more methods
        stale_deps = (ignore = [:JSON3],),  # JSON3 used but not directly called yet
    )
end
