using AirBorne: AirBorne
using Test

@testset "Static Market" begin
    using AirBorne.Markets.StaticMarket:
        produceFeeLedgerEntry, Order, executeOrder_CA!, available_data
    using AirBorne.Structures: ContextTypeA, TimeEvent
    using AirBorne.ETL.Cache: load_bundle
    using AirBorne.Utils: get_latest

    using Dates: DateTime
    using DotMaps: DotMap
    using DataFrames: DataFrame

    # Define dummy Context
    dummy_event = TimeEvent(DateTime(2019, 1, 1), "example2019")
    context = ContextTypeA(dummy_event) # Initialize ContextTypeB

    context.accounts.usd = DotMap(Dict())
    context.accounts.usd.balance = 10^5
    context.accounts.usd.currency = "FEX/USD"
    context1 = deepcopy(context)

    order_specs = DotMap(Dict())
    order_specs.ticker = "AAPL"
    order_specs.shares = 100 # Number of shares to buy/sell
    order_specs.type = "MarketOrder"
    order_specs.account = context1.accounts.usd
    order = Order("NMS", order_specs)

    # Retrieve data
    cache_dir = joinpath(@__DIR__, "assets", "cache")
    data = load_bundle("demo"; cache_dir=cache_dir)
    cur_data = get_latest(available_data(context, data), [:exchangeName, :symbol], :date)
    executeOrder_CA!(context1, order, cur_data) # Basic Tes
    @test size(DataFrame(context1.ledger), 1) == 1

    feeStructA = Dict(
        "FeeName" => "Broker_A_Commission", "fixedPrice" => 1.0, "variableRate" => 0.02
    )
    # 2% commission + $1 transaction fee
    function feeLog(order, ledgerEntry)
        return abs(order.specs.shares) > 10 ? 5 : 5.0 * log10(abs(order.specs.shares))
    end
    function feeSell(order, ledgerEntry)
        return if order.specs.shares < 0
            order.specs.shares * ledgerEntry["sharePrice"] * 0.01
        else
            0.0
        end
    end
    function feeStepped(order, ledgerEntry)
        basicAmount = ledgerEntry["sharePrice"] * order.specs.shares

        commission = 0.001
        if basicAmount < 10^2
            commission = 0.1 # 1 % commission
        elseif basicAmount < 10^3
            commission = 0.01 # 1 % commission
        elseif basicAmount < 10^4
            commission = 0.005 # 50 bps commission
        end
        return commission * basicAmount
    end

    context2 = deepcopy(context)
    order_specs_2 = deepcopy(order_specs)
    order_specs_2.feeStructures = [feeStructA]
    order_specs_2.account = context2.accounts.usd
    order2 = Order("NMS", order_specs_2)
    priceModel(a, b) = 10.0 # Share Price is always 10
    executeOrder_CA!(context2, order2, cur_data; priceModel=priceModel)

    # Test resulting balances
    @test round(context1.accounts.usd.balance; digits=2) == 96036.75
    @test context2.accounts.usd.balance == 98979.0

    # Retrieving ledger with fees
    ledger2 = DataFrame()
    [push!(ledger2, row; cols=:union) for row in context2.ledger]
    @test size(ledger2, 1) == 2
end
