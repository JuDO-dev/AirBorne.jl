using AirBorne
using Test

@testset "AirBorne.jl" begin
    # Sanity check
    @test AirBorne.hello_world() == "Hello World!"
    @test AirBorne.ETL.YFinance.hello_yfinance() == "Hello YFinance!"
    @test AirBorne.ETL.Cache.hello_cache() == "Hello Cache!"

end
