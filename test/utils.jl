using AirBorne.Utils: lagFill, makeRunning, movingAverage

using Test
@testset "Utils" begin
    using DataFrames: DataFrame, missing
    a1 = [1, 0, missing, 2, 3, nothing, 4, 5]
    df = DataFrame(Dict("columnWithMissing" => a1))
    @test lagFill(df.columnWithMissing; fill=[missing]) == [1, 0, 0, 2, 3, nothing, 4, 5]
    @test lagFill(df.columnWithMissing) == [1, 0, 0, 2, 3, 3, 4, 5]

    a2 = [1, 2, 3, 4, 5, 6, 7]
    @test makeRunning(a2, sum) == [1, 3, 6, 10, 15, 21, 28]
    @test makeRunning(a2, sum; startFrom=2) == [nothing, 2.0, 5.0, 9.0, 14.0, 20.0, 27.0]
    @test makeRunning(a2, sum; windowSize=2, startFrom=2) ==
        [nothing, 2.0, 5.0, 7.0, 9.0, 11.0, 13.0]
    @test movingAverage(a2) == [1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0]
    @test movingAverage(a2; windowSize=2) == [1.0, 1.5, 2.5, 3.5, 4.5, 5.5, 6.5]
    @test movingAverage(a2; windowSize=2, startFrom=2) ==
        [nothing, 2.0, 2.5, 3.5, 4.5, 5.5, 6.5]
end
