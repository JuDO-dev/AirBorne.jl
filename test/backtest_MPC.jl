
using AirBorne.ETL.AssetValuation: stockValuation, returns
using AirBorne.ETL.Cache: load_bundle
# using AirBorne.Engines.DEDS: run
using AirBorne.Markets.StaticMarket:
    execute_orders!, expose_data, keyJE
using AirBorne.Strategies.MeanVarianceMPC: predeterminedReturns
using AirBorne.Structures: ContextTypeA, TimeEvent

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
    sv=stockValuation(data)
    sv[!,dollar_symbol].=1.0
    sr=returns(sv)

    context.extra.symbolOrder=collect(unique(data.assetID))
    context.parameters.horizon=14

    @test size(predeterminedReturns(context,sr))==(14,)

    ######################
    ###  MPC Strategy  ###
    ######################
    
end
