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
export initialize!
export trading_logic!

using ...Utils: sortedStructInsert!
using ...Structures: ContextTypeA, TimeEvent
using ...Markets.StaticMarket: Order, place_order!
using Dates: Day
using DataFrames: DataFrame
using Tables: schema # Used to validate the data against the schemas in the system

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
function initialize!(context::ContextTypeA; longHorizon::Real=100, shortHorizon::Real=10)
    context.extra.long_horizon = longHorizon
    context.extra.shortHorizon = shortHorizon
    return nothing
end

function default_next_event(context::ContextTypeA)
    next_event_date = context.current_event.date + Day(1)
    new_event = TimeEvent(next_event_date, "data_transfer")
    sortedStructInsert!(context.eventList, new_event, :date)
    return nothing
end

function default_order_generation(context::ContextTypeA, data::DataFrame)
    orders = []
    return orders
end

"""
    trading_logic!

    Template for the trading logic algorithm, before being passed onto an engine like DEDS a preloaded
    function must be defined so that the trading logic function meets the engine requirements.

    ```julia
    # Specify custom arguments to tune the behaviour of SMA
    my_trading_logic!(context,data) = SMA.trading_logic!(context,data;...)
    # Or just run with the default parameters
    my_trading_logic!(context,data) = SMA.trading_logic!(context,data)
    ```
"""
function trading_logic!(
    context::ContextTypeA,
    data::DataFrame;
    tune_parameters::Dict=Dict(),
    next_event_setter::Function=default_next_event,
    order_generator::Function=default_order_generator,
)

    # 1. Specify next event (precalculations can be specified here) 
    next_event_setter(context)

    # 2. Generate orders
    orders = order_generator(context, data)

    # 3. Place orders
    for order in orders
        place_order!(context, order)
    end
    return nothing
end

end
