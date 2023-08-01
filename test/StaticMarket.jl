using AirBorne: AirBorne
using Test

@testset "Static Market" begin
    using AirBorne.Markets.StaticMarket:
        produceFeeLedgerEntry, Order, executeOrder_CA, available_data
    using AirBorne.Structures: ContextTypeA, TimeEvent
    using AirBorne.ETL.Cache: load_bundle
    using AirBorne.Utils: get_latest

    using Dates: DateTime
    using DotMaps: DotMap
    using DataFrames:DataFrame

    # Define dummy Context
    dummy_event = TimeEvent(DateTime(2019, 1, 1), "example2019")
    context = ContextTypeA(dummy_event) # Initialize ContextTypeB

    context.accounts.usd = DotMap(Dict())
    context.accounts.usd.balance = 10^5
    context.accounts.usd.currency = "FEX/USD"


    priceModel(a, b) = 10.0 # Share Price is always 10

    order_specs = DotMap(Dict())
    order_specs.ticker = "AAPL"
    order_specs.shares = 100 # Number of shares to buy/sell
    order_specs.type = "MarketOrder"
    order_specs.account = context.accounts.usd

    order = Order("NMS", order_specs)
    # Retrieve data

    cache_dir = joinpath(@__DIR__, "assets", "cache")
    data = load_bundle("demo"; cache_dir=cache_dir)
    cur_data = get_latest(available_data(context, data), [:exchangeName, :symbol], :date)
    # @info order
    # @info context
    # @info cur_data
    
    context1 = deepcopy(context);executeOrder_CA(context1, order, cur_data) # Basic Test
    @info DataFrame(context1.ledger)

    feeStructA = Dict(
        "FeeName"=>"Broker_A_Commission",
        "fixedPrice"=> 1.0, 
        "variableRate"=> 0.02)
         # 2% commission + $1 transaction fee
    feeLog(order,ledgerEntry) = abs(order.specs.shares)>10 ? 5 : 5.0 * log10(abs(order.specs.shares)) 
    feeSell(order,ledgerEntry) = order.specs.shares<0 ? order.specs.shares * ledgerEntry["sharePrice"] * 0.01  : 0.0 
    function feeStepped(order,ledgerEntry)
        basicAmount = ledgerEntry["sharePrice"] * order.specs.shares
        
        commission = 0.001
        if basicAmount < 10^2
            commission = 0.1 # 1 % commission
        elseif basicAmount < 10^3
            commission = 0.01 # 1 % commission
        elseif basicAmount < 10^4
            commission = 0.005 # 50 bps commission
        end
        return commission*basicAmount
    end

    order_specs_2= deepcopy(order_specs)
    order_specs_2.feeStructures = [feeStructA]
    order2 = Order("NMS", order_specs_2)

    context2 = deepcopy(context);executeOrder_CA(context2, order2, cur_data; priceModel=priceModel)

    ledger2 = DataFrame()
    [push!(ledger2, row, cols=:union) for row in context2.ledger]
    @info ledger2

    
end
