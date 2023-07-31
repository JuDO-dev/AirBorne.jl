using AirBorne: AirBorne

using Test
using Logging
@testset "Backtest: Basic" begin
    using AirBorne.ETL.Cache: load_bundle
    using AirBorne.Engines.DEDS: run
    using AirBorne.Markets.StaticMarket:
        execute_orders!, expose_data, parse_portfolioHistory, parse_accountHistory
    include("./assets/AlwaysBuyStrategy.jl")
    cache_dir = joinpath(@__DIR__, "assets", "cache")
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
        verbose=true,
    )
    @test length(results.audit.eventHistory) == 51
    @test round(
        parse_portfolioHistory(results.audit.portfolioHistory)[end, :"NMS/AAPL"]; digits=2
    ) == 3303.55
    @test round(
        parse_accountHistory(results.audit.accountHistory)[end, :"usd"]; digits=2
    ) == 0.0

    # Test portfolio redistribution order generation
    using AirBorne.ETL.AssetValuation: stockValuation
    using AirBorne.Markets.StaticMarket: ordersForPortfolioRedistribution

    cache_dir = joinpath(@__DIR__, "assets", "cache")
    dataB = load_bundle("Mark1"; cache_dir=cache_dir)
    sv = stockValuation(dataB)

    trading_symbols = unique(dataB[!, "assetID"])
    dollar_symbol = "FEX/USD"
    # Source Portfolio
    sourcePf = Dict([x => 0.0 for x in trading_symbols])
    sourcePf[dollar_symbol] = 10^5
    # Target Distribution
    targetDst = Dict([x => 0.0 for x in keys(sourcePf)])
    targetDst["NCM/AEHR"] = 0.1
    targetDst["NCM/TTOO"] = 0.2
    targetDst["NMS/CLNE"] = 0.05
    targetDst["NMS/TSLA"] = 0.2
    targetDst["NMS/AAPL"] = 0.05
    targetDst["FEX/USD"] = 0.4
    # Asset Value
    assetPricing = sv[3, "stockValue"]
    assetPricing[dollar_symbol] = 1.0
    orders = ordersForPortfolioRedistribution(
        sourcePf,
        targetDst,
        assetPricing;
        curency_symbol=dollar_symbol,
        costPropFactor=0.03,
        costPerTransactionFactor=0,
    )
    @test size(orders) == (4,)
end
