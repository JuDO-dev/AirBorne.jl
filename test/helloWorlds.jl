using AirBorne: AirBorne
# Sanity check
@testset "Hello Worlds" begin
    @test AirBorne.Utils.hello_world() == "Hello World!"
    @test AirBorne.ETL.YFinance.hello_yfinance() == "Hello YFinance!"
    @test AirBorne.ETL.Cache.hello_cache() == "Hello Cache!"
    @test AirBorne.Backtest.DEDS.hello_deds() == "Hello D.E.D.S.!"
end