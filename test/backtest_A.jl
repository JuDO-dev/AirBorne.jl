using AirBorne: AirBorne

using Test
using Logging
@testset "Backtest A" begin
    using AirBorne.ETL.Cache: load_bundle
    using AirBorne.Engines.DEDS: run
    using AirBorne.Markets.StaticMarket:
        execute_orders!, expose_data, parse_portfolioHistory, parse_accountHistory

    include("./assets/AlwaysBuyStrategy.jl")
    cache_dir = joinpath(@__DIR__, "assets", "cache")
    # To generate this data use:
    # from = Dates.DateTime("2017-01-01"); to = Dates.DateTime("2022-01-01")
    # u_from = string(round(Int, Dates.datetime2unix(from))); u_to = string(round(Int, Dates.datetime2unix(to)))
    # data = AirBorne.ETL.YFinance.get_interday_data(["AAPL","GOOG"], u_from, u_to)

    data = load_bundle("demo"; cache_dir=cache_dir)
    initialize! = AlwaysBuyStrategy.initialize!
    trading_logic! = AlwaysBuyStrategy.trading_logic!
    max_iter = 50
    results = run(
        data,
        initialize!,
        trading_logic!,
        execute_orders!,
        expose_data;
        audit=true,
        max_iter=max_iter,
        verbose=true
    )
    @test length(results.audit.eventHistory) == 51
    @test round(
        parse_portfolioHistory(results.audit.portfolioHistory)[end, :"NMS/AAPL"]; digits=2
    ) == 3303.55
    @test round(
        parse_accountHistory(results.audit.accountHistory)[end, :"usd"]; digits=2
    ) == 0.0
end
