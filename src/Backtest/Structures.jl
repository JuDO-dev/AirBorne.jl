"""
    Structures
    
    This module provides data structures defined and used in the Backtest process.

    Facilitating contract enforcement between Engines, Markets and Strategies. 
"""
module Structures
using Dates: DateTime
import DotMaps.DotMap as DM
# Financial model Types
using ...AirBorne: Wallet, Portfolio

export TimeEvent

struct TimeEvent
    date::DateTime
    type::String
end

function length(::TimeEvent)
    return 1
end

"""
    Context definitions for contract between Engines, Markets and Strategies to operate with.
"""
mutable struct ContextTypeA
    eventList::Vector{TimeEvent} # List of events defined by the user
    activeOrders::Vector{Any} # List of orders (keep as Any for agnosticity)
    current_event::TimeEvent
    portfolio::Dict # The market determines the portfolio
    accounts::DM # The market determines the account
    ledger::Vector{Any} # List of transactions
    audit::DM
    extra::DM
end
# Constructors
ContextTypeA(event::TimeEvent) = ContextTypeA([], [], event, Dict(), DM(), [], DM(), DM())

"""
    This context allows for arithmetic operations of portfolio and accounts, such as adding 
    securities by doing portfolio+=security, and or removing Money from an account by doing
    account+=money.
    
    A way to initialize this this context type can look like:
    ```jldoctest 
    using AirBorne.Structures: ContextTypeB, TimeEvent
    using Dates: now
    start_event = TimeEvent(now(),"hi")
    new_context = ContextTypeB(start_event)
    ```
"""
mutable struct ContextTypeB
    eventList::Vector{TimeEvent} # List of events defined by the user
    activeOrders::Vector{Any} # List of orders (keep as Any for agnosticity)
    current_event::TimeEvent
    portfolio::Portfolio # The market determines the portfolio
    accounts::Wallet # The market determines the account
    ledger::Vector{Any} # List of transactions
    audit::DM
    extra::DM
end

# Constructors
function ContextTypeB(event::TimeEvent)
    return ContextTypeB([], [], event, Portfolio(), Wallet(), [], DM(), DM())
end
end
