using AirBorne: AirBorne, Money, Portfolio, Wallet, Security, get_symbol
using AirBorne.ETL.Cache: load_bundle
using AirBorne.Structures: ContextTypeB, TimeEvent
using AirBorne.Markets.StaticMarket:
    addMoneyToAccount!, addSecurityToPortfolio!, execute_orders!, expose_data, keyJE
# using AirBorne.Engines.DEDS: run

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
    @test contextB.accounts[:USD] == 92150.0
    @test contextB.portfolio[Symbol(journal_entry["assetID"])] == 100.0

    ######################
    ###  SMA Strategy  ###
    ######################
    # cache_dir = joinpath(@__DIR__, "assets", "cache")
    # data = load_bundle("demo"; cache_dir=cache_dir)

    # # Custom Pricing Mechanism
    # priceModel(cur_data, ticker) = refPrice(cur_data, ticker; col=:market_price)
    # # Custom Single Order Execution
    # eO(ctx, ord, cd) = executeOrder_CB(ctx, ord, cd; priceModel=priceModel)

    # execute_orders!(context, data; executeOrder=eO)
    # cur_data = get_latest(available_data(context, data), [:exchangeName, :symbol], :date)
    # journal_entry, status = executeOrder_CB(context, order, cur_data; priceModel=priceModel)

end
