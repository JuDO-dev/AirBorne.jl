module Structures
using Dates: DateTime
using DotMaps: DotMap

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
    accounts::DotMap # The market determines the account
    ledger::Vector{Any} # List of transactions
    audit::DotMap
    extra::DotMap
end
end
