using AirBorne: AirBorne
using Test
@testset "AirBorne.ETL.YFinance" begin
    using Dates: Dates
    from = Dates.DateTime("2022-01-01")
    to = Dates.DateTime("2022-02-01")
    u_from = string(round(Int, Dates.datetime2unix(from)))
    u_to = string(round(Int, Dates.datetime2unix(to)))
    r = AirBorne.ETL.YFinance.get_interday_data(["AAPL"], u_from, u_to)
    @test size(r) == (20, 12)

    screener_df = AirBorne.ETL.NASDAQ.screener()
    @test size(screener_df, 1) > 5000
    @test "symbol" in names(screener_df)
end
