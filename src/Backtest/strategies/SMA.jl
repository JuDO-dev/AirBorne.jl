"""
    SMA (Simple Moving Average)

    This is a standard strategy that can be implemented in several ways.

    1. Crossover Simple Moving Average: Define 2 time windows, a long one and a short one.
    If the Average during the short one is greater than over the long one this implies that the price  is going up.
    So a long position is desired, however if its smaller then this indicates a falling price and a short position 
    is desired.

    In this Strategy an optimization of hyperparameters will be available. The optimization will need an objective function and 
    maybe constraints.

    The design of this strategy is inspired by the lecture 2 of Algorithmic Trading, original source obtained from  [Algorithmic Trading Society Lectures Imperial College London](https://github.com/algotradingsoc/Lectures2022/blob/main/AlgoTradeSocLectures.ipynb)

"""
module SMA

using ...Utils: sortedStructInsert!
using ...Structures: ContextTypeA, TimeEvent
using ...Markets.StaticMarket: Order, place_order!
using Dates: Day
using DataFrames: DataFrame, groupby, combine, mean
using DotMaps: DotMap

"""
    initialize!

    Template for the initialization procedure, before being passed onto an engine like DEDS a preloaded
    function must be defined so that the initialization function meets the engine requirements.
    
    ```julia
    # Specify custom arguments to tune the behaviour of SMA
    my_initialize!(context,data) = SMA.initialize!(context;...)
    # Or just run with the default parameters
    my_initialize!(context,data) = SMA.trading_logic!(context)
    ```
"""
function interday_initialize!(
    context::ContextTypeA;
    longHorizon::Real=100,
    shortHorizon::Real=10,
    initialCapital::Real=10^5,
)
    context.extra.long_horizon = longHorizon
    context.extra.short_horizon = shortHorizon

    ###################################
    ####  Specify Account Balance  ####
    ###################################
    context.accounts.usd = DotMap(Dict())
    context.accounts.usd.balance = initialCapital
    context.accounts.usd.currency = "USD"

    #########################################
    ####  Define first simulation event  ####
    #########################################
    # Define First Event (Assuming the first event starts from the data
    # The first even should be at least as long as the long horizon)
    next_event_date = context.current_event.date + Day(longHorizon)
    new_event = TimeEvent(next_event_date, "data_transfer")
    sortedStructInsert!(context.eventList, new_event, :date)
    return nothing
end

"""
    interday_trading_logic!(context::ContextTypeA, data::DataFrame)

    Template for the trading logic algorithm, before being passed onto an engine like DEDS a preloaded
    function must be defined so that the trading logic function meets the engine requirements.

    ```julia
    # Specify custom arguments to tune the behaviour of SMA
    my_trading_logic!(context,data) = SMA.trading_logic!(context,data;...)
    # Or just run with the default parameters
    my_trading_logic!(context,data) = SMA.trading_logic!(context,data)
    ```
"""
function interday_trading_logic!(context::ContextTypeA, data::DataFrame)

    # 1. Specify next event (precalculations can be specified here) 
    next_event_date = context.current_event.date + Day(1)
    new_event = TimeEvent(next_event_date, "data_transfer")
    sortedStructInsert!(context.eventList, new_event, :date)

    # 2. Generate orders and  place orders
    if size(data, 1) < context.extra.long_horizon # Skip if not enough data
        return nothing
    end

    # SMA Calculations: This assumes the data of the subdataframe comes pre-sorted with newest results last.
    shortSMA(sdf_col) = mean(last(sdf_col, context.extra.short_horizon))
    longSMA(sdf_col) = mean(last(sdf_col, context.extra.long_horizon))
    sma_df = combine(
        groupby(data, ["symbol", "exchangeName"]),
        :close => shortSMA => :SMA_S,
        :close => longSMA => :SMA_L,
    )
    sma_df[!, :position] = ((sma_df.SMA_S .>= sma_df.SMA_L) .- 0.5) .* 2

    # Order Generation
    for r in eachrow(sma_df)
        assetID = r.exchangeName * "/" * r.symbol
        if r.position > 0 # Set Portfolio to 100 Shares on ticker under a bullish signal
            amount = 100 - get(context.portfolio, assetID, 0)
        elseif r.position < 10
            amount = get(context.portfolio, assetID, 0) * -1
        end
        if amount === 0
            continue
        end
        order_specs = DotMap(Dict())
        order_specs.ticker = r.symbol
        order_specs.shares = amount # Can be replaced by r.amount
        order_specs.type = "MarketOrder"
        order_specs.account = context.accounts.usd
        order = Order(r.exchangeName, order_specs)
        place_order!(context, order)
    end
    return nothing
end

end
