
using AirBorne.ETL.AssetValuation: stockValuation, returns
using AirBorne.ETL.Cache: load_bundle
using AirBorne.Engines.DEDS: run
using AirBorne.Markets.StaticMarket: execute_orders!, expose_data
using AirBorne.Strategies.MeanVarianceMPC: predeterminedReturns
import AirBorne.Strategies.MeanVarianceMPC as mpc

using AirBorne.Structures: ContextTypeA, TimeEvent, summarizePerformance

using Dates: DateTime, Day
using Test
using Logging
# Tests
@testset "Backtest: MPC" begin

    ###############################
    ###  Forecasting Functions  ###
    ###############################
    dummy_event = TimeEvent(DateTime(2019, 1, 1), "example2019")
    context = ContextTypeA(dummy_event) # Initialize ContextTypeB

    cache_dir = joinpath(@__DIR__, "assets", "cache")
    data = load_bundle("Mark1"; cache_dir=cache_dir)
    evaluationEvents = [
        TimeEvent(t, "data_transfer") for t in sort(unique(data.date); rev=true)
    ]

    dollar_symbol = "FEX/USD"
    sv = stockValuation(data)
    sv[!, dollar_symbol] .= 1.0
    sr = returns(sv)

    context.extra.symbolOrder = collect(unique(data.assetID))
    context.parameters.horizon = 14

    @test size(predeterminedReturns(context, sr)) == (14,)

    ######################
    ###  MPC Strategy  ###
    ######################
    account_currency = "FEX/USD"
    forecastFun(context) = predeterminedReturns(context, sr)

    evaluationEvents = [
        TimeEvent(t, "data_transfer") for t in sort(unique(data.date); rev=true)
    ]

    parameters = Dict("horizon" => 7)
    otherExtras = Dict("symbolOrder" => collect(unique(data.assetID)))

    # Simulation functions definition
    function initialize!(context)
        return mpc.initialize!(
            context;
            currency_symbol=account_currency,
            min_data_samples=5,
            otherExtras=otherExtras,
            parameters=parameters,
        )
    end

    function trading_logic!(context, data)
        return mpc.tradingLogic!(context, data; forecastFun=forecastFun)
    end

    my_expose_data(context, data) = expose_data(context, data; historical=false)
    function my_execute_orders!(context, data)
        return execute_orders!(context, data; propagateBalanceToPortfolio=true)
    end

    mpc_context = run(
        data,
        initialize!,
        trading_logic!,
        my_execute_orders!,
        my_expose_data;
        audit=true,
        max_iter=7,
        initialEvents=evaluationEvents,
    )

    # Produce valuation data for currency and add it to the data fed to summarizePerformance 
    usdData = deepcopy(data[data.assetID .== mpc_context.extra.symbolOrder[1], :])
    usdData[!, "assetID"] .= account_currency
    usdData[!, "exchangeName"] .= "FEX"
    usdData[!, "symbol"] .= "USD"
    usdData[!, [:close, :high, :low, :open]] .= 1.0
    usdData[!, [:volume]] .= 0

    OHLCV_data = vcat(data, usdData)
    performance = summarizePerformance(OHLCV_data, mpc_context; includeAccounts=false)
    @test size(performance, 1) == 8
end
