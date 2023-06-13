
"""
    DEDS - Which stands for "Discrete Event Driven Simulation"  is a framework for backtesting
    where the system moves from one event to the next one.
"""
module DEDS

using DataFrames: DataFrame
using DotMaps: DotMap
using ...Utils: deepPush!, sortStruct!
using ...Structures: TimeEvent

# . =AirBorne.Backtest.DEDS
# .. =AirBorne.Backtest
# ... = AirBorne
"""
    DEDS module hello world
"""
function hello_deds()
    return "Hello D.E.D.S.!"
end

"""
    Provides context definitions
"""
mutable struct Context
    eventList::Vector{TimeEvent} # List of events defined by the user
    activeOrders::Vector{Any} # List of orders (keep as Any for agnosticity)
    current_event::TimeEvent
    portfolio::Dict # The market determines the portfolio
    accounts::DotMap # The market determines the account
    ledger::Vector{Any} # List of transactions
    audit::DotMap
    extra::DotMap
end

"""
    run(data::DataFrame, initialize!::Function, trading_logic!::Function, execute_orders!::Function,expose_data::Function;audit=true)

    Run DEDS simulation provided:
    # Arguments
    - `data::DataFrame`: A dataframe with the data to be provided to the function `expose_data` and `Function, execute_orders!`.
    - `initialize!::Function`: initialize!(context) should receive a struct context and provide initialization for its accounts 
        and add as the next events to be processed by this function.
    - `trading_logic!::Function`: `trading_logic!(context,exposed_data)` receives the context and exposed data from the market 
      and should place orders and define further events 
    - `execute_orders!::Function`: execute_orders!(past_event_date, context.current_event.date, context, data) Executes orders between
        the past event and the current one, this function will modify the portfolio and the accounts from the context.
    ### Optional keyword arguments
    - `audit::Bool=true`: If true context will its audit entry populated for each event in the simulation. 
    # Returns
    - `context::Context`
"""
function run_A(data::DataFrame, initialize!::Function, trading_logic!::Function, execute_orders!::Function,expose_data::Function;audit::Bool=true)
    DM()= DotMap(Dict()) # Shorthand
    context = Context([],[],TimeEvent(findmin(data.date)[1],"start"),Dict(),DM(),[],DM(),DM())

    HiddenContext=DotMap(Dict())
    HiddenContext.portfolioHistory=[]
    HiddenContext.accountHistory=[]
    HiddenContext.eventHistory=[]
    HiddenContext.extraHistory=[] 
    
    
    initialize!(context) 
    if audit
        deepPush!(HiddenContext.portfolioHistory,context.portfolio)
        deepPush!(HiddenContext.accountHistory,context.accounts)
        deepPush!(HiddenContext.eventHistory,context.current_event)
        deepPush!(HiddenContext.extraHistory,context.extra)
    end
    counter = 0
    max_iter= 50
    while ((size(context.eventList)[1]>0)) && (counter<max_iter)
        counter+=1
        
        past_event_date=context.current_event.date
        #############################
        ####   Pick next event   ####
        #############################
        # Sort Event List 
        sortStruct!(context.eventList,:date)
        context.current_event=pop!(context.eventList)# Removes the last item from the collection
        
        #############################################
        ####   Execute orders since last event   ####
        #############################################
        execute_orders!(past_event_date, context.current_event.date, context, data)
        if audit
            deepPush!(HiddenContext.portfolioHistory,context.portfolio)
            deepPush!(HiddenContext.accountHistory,context.accounts)
            deepPush!(HiddenContext.eventHistory,context.current_event)
            deepPush!(HiddenContext.extraHistory,context.extra)
        end
        #########################
        ####   Expose Data   ####
        #########################
        exposed_data = expose_data(context,data) # Mechanism for which the market exposes the data to the user
        
        
        ########################################################
        ####   Let user process data and place new orders   ####
        ########################################################
        trading_logic!(context,exposed_data)
        
    end
    if audit
        context.audit=HiddenContext
    end
    return context
end

end