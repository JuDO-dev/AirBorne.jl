
"""
    DEDS - Which stands for "Discrete Event Driven Simulation"  is a framework for backtesting
    where the system moves from one event to the next one.
"""
module DEDS
export run
export hello_deds

using DataFrames: DataFrame
using DotMaps: DotMap
using Dates: DateTime
using ...Utils: deepPush!, sortStruct!
using ...Structures: TimeEvent, ContextTypeA

# Context = ContextTypeA
"""
    DEDS module hello world
"""
function hello_deds()
    return "Hello D.E.D.S.!"
end

# TODO: As it returns context run is not Type-stable. Make the output type-stable.
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
    - `max_iter::Int=10^6`: Limit the number of events processed on the simulation.
    # Returns
    - `verbose::Bool=false`: If true prints the date
"""
function run(
    data::DataFrame,
    initialize!::Function,
    trading_logic!::Function,
    execute_orders!::Function,
    expose_data::Function;
    audit::Bool=true,
    max_iter::Int=10^6,
    max_date::Union{DateTime,Nothing}=nothing,
    verbose::Bool=false,
    contextType::Type=ContextTypeA,
    initialEvents::Union{Vector{TimeEvent},Nothing}=nothing,
)
    initial_event = TimeEvent(findmin(data.date)[1], "start")
    context = contextType(initial_event)

    if !(isnothing(initialEvents))
        context.eventList = initialEvents
    end

    HiddenContext = DotMap(Dict())
    HiddenContext.portfolioHistory = []
    HiddenContext.accountHistory = []
    HiddenContext.eventHistory = []
    HiddenContext.extraHistory = []

    initialize!(context)
    if audit
        deepPush!(HiddenContext.portfolioHistory, context.portfolio)
        deepPush!(HiddenContext.accountHistory, context.accounts)
        deepPush!(HiddenContext.eventHistory, context.current_event)
        deepPush!(HiddenContext.extraHistory, context.extra)
    end
    counter = 0
    while ((size(context.eventList)[1] > 0)) && (counter < max_iter)
        if (max_date !== nothing) && (context.current_event.date > max_date)
            break
        end

        if verbose
            flush(stdout) # Remove whatever was before
            print(context.current_event.date) # Print date
            print("\r") # Reset cursor
        end
        counter += 1

        context.extra.past_event_date = context.current_event.date
        #############################
        ####   Pick next event   ####
        #############################
        # Sort Event List 
        sortStruct!(context.eventList, :date)
        context.current_event = pop!(context.eventList)# Removes the last item from the collection

        #############################################
        ####   Execute orders since last event   ####
        #############################################
        execute_orders!(context, data)
        if audit
            deepPush!(HiddenContext.portfolioHistory, context.portfolio)
            deepPush!(HiddenContext.accountHistory, context.accounts)
            deepPush!(HiddenContext.eventHistory, context.current_event)
            deepPush!(HiddenContext.extraHistory, context.extra)
        end
        #########################
        ####   Expose Data   ####
        #########################
        exposed_data = expose_data(context, data) # Mechanism for which the market exposes the data to the user

        ########################################################
        ####   Let user process data and place new orders   ####
        ########################################################
        trading_logic!(context, exposed_data)
    end
    if audit
        context.audit = HiddenContext
    end
    return context
end

end
