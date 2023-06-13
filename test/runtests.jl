using Test
using TestSetExtensions

@testset ExtendedTestSet  "All the tests" begin
    @includetests ARGS
end
