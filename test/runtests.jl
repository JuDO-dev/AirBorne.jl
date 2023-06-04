using AirBorne
using Test

@testset "AirBorne.jl" begin
    # Sanity check
    @test AirBorne.hello_world() == "Hello World!"
    @test AirBorne.ETL.Quandl.hello_quandl() == "Hello Quandl!"
end
