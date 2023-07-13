using AirBorne: AirBorne, Money, Portfolio, Wallet, Security, get_symbol
using AirBorne.ETL.Cache: load_bundle
using AirBorne.Structures: ContextTypeB, TimeEvent, summarizePerformance
using AirBorne.Markets.StaticMarket:
    addMoneyToAccount!, addSecurityToPortfolio!, execute_orders!, expose_data, keyJE
using AirBorne.Engines.DEDS: run
using AirBorne.Strategies.SMA: interday_initialize!, interday_trading_logic!

function f(acc, mon)
    return acc[get_symbol(a)] += mon.value * -1
end;
using Dates: DateTime
using Test
using Logging
# This more sophisticated data structures and 
# Strategy templates 
@testset "Backtest B" begin

    ######################
    ###  ContextTypeB  ###
    ######################
    dummy_event = TimeEvent(DateTime(2018, 1, 1), "example")
    contextB = ContextTypeB(dummy_event) # Initialize ContextTypeB

    @test length(dummy_event) == 1 # Events are atomic, thus have length 1.
    @test typeof(contextB.portfolio) == Portfolio
    @test typeof(contextB.accounts) == Wallet

    # addSecurityToPortfolio!(context.B)
    contextB.accounts += Money(10^5, :USD)
    @test contextB.accounts[:USD] == 10^5
    journal_entry = Dict(
        "exchangeName" => "NMS",
        "ticker" => "AAPL",
        "shares" => 100.0,
        "price" => Money(78.5, :USD),
        "amount" => 100.0 * Money(78.5, :USD),
        "date" => dummy_event.date,
    )
    journal_entry["assetID"] = keyJE(journal_entry)
    addMoneyToAccount!(contextB.accounts, journal_entry)
    addSecurityToPortfolio!(contextB.portfolio, journal_entry)
    vector_portfolio = []
    addSecurityToPortfolio!(vector_portfolio, journal_entry)
    @test size(vector_portfolio) == (1,)
    @test contextB.accounts[:USD] == 92150.0
    @test contextB.portfolio[Symbol(journal_entry["assetID"])] == 100.0

    ######################
    ###  SMA Strategy  ###
    ######################
    cache_dir = joinpath(@__DIR__, "assets", "cache")
    data = load_bundle("demo"; cache_dir=cache_dir)
    simulate_until = DateTime(2019, 2, 1)
    sma_initialize!(context) = interday_initialize!(context; longHorizon=20, shortHorizon=5)
    sma_trading_logic! = interday_trading_logic!
    context = run(
        data,
        sma_initialize!,
        sma_trading_logic!,
        execute_orders!,
        expose_data;
        audit=true,
        max_date=DateTime(2019, 2, 1),
    )
    @test size(context.audit.portfolioHistory) == (741,)
    @test size(summarizePerformance(data, context; removeWeekend=true), 1) == 531
end
