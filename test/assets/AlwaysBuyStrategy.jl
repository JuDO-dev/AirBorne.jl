"""
    AlwaysBuyStrategy

    This is a demo strategy to use for testing purposes it will try to buy 100 stock from AAPL 
    any chance it gets.

"""
module AlwaysBuyStrategy
#######################################
###### Functions used by Strategy #####
#######################################
export initialize!
export trading_logic!
using AirBorne: AirBorne
using AirBorne.Structures: TimeEvent
using AirBorne.Utils: sortedStructInsert!
using AirBorne.Markets.StaticMarket: Order, place_order!
using AirBorne.Structures: ContextTypeA
using DotMaps: DotMap
using Dates: Day
Context = ContextTypeA
"""
    initialize!

    Set things like currency accounts and next events.
"""
function initialize!(context)

    ####################################
    ####  Specify Account Balance  #####
    ####################################
    context.accounts.usd = DotMap(Dict())
    context.accounts.usd.balance = 100000
    context.accounts.usd.currency = "USD"

    #############################
    ####  Specify next event  ###
    #############################
    next_event_date = context.current_event.date + Day(1)
    new_event = TimeEvent(next_event_date, "data_transfer")
    return sortedStructInsert!(context.eventList, new_event, :date)
end

# This function implements the strategy i.e., SMA
"""
    trading_logic!

    Place orders for the market to execute..
"""
function trading_logic!(context, data)

    #############################
    ####  Specify next event  ###
    #############################
    next_event_date = context.current_event.date + Day(1)
    new_event = TimeEvent(next_event_date, "data_transfer")
    sortedStructInsert!(context.eventList, new_event, :date)

    ##############################
    #####   Generate orders   ####
    ##############################
    # https://www.investopedia.com/ask/answers/100314/whats-difference-between-market-order-and-limit-order.asp

    # Buy 100 shares of AAPL as soon as possible if I have money
    if context.accounts.usd.balance > 0
        order_specs = DotMap(Dict())
        order_specs.ticker = "AAPL"
        order_specs.shares = 100
        order_specs.type = "MarketOrder"
        order_specs.account = context.accounts.usd
        order = Order("NMS", order_specs)

        ###########################
        #####   Place orders   ####
        ###########################
        place_order!(context, order)
        context.extra.orderPlaced = true
    else
        context.extra.orderPlaced = true
    end
end

end
