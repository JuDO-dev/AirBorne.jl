"""
    StaticMarket

    The static market assumes that the prices of the assets are not affected by the strategy used. 

    This is a big assumption for large orders but for smaller ones it can hold.
"""
module StaticMarket
export execute_orders!, expose_data, Order, parse_portfolioHistory, parse_accountHistory
using DataFrames: DataFrame, Not, select!
using DotMaps: DotMap
using ...Structures: ContextTypeA, ContextTypeB
using ....AirBorne: Portfolio, Security
using ...Utils: get_latest

Context = ContextTypeA
Contexts = Union{ContextTypeA,ContextTypeB}
"""
    Order

    Represents an order to the market. I.e. A stock exchange. 
    
    TODO: Add more documentation
"""
struct Order
    market::String
    specs::DotMap
end

place_order!(context::Contexts, order) = push!(context.activeOrders, order)

"""
    available_data(context,data)

    This function determine what data is available given the context.
"""
available_data(context, data) = data[data.date .<= context.current_event.date, :]

"""
    expose_data(context,data)

    This function determine how the data is transformed and filtered before being passed to the user.
"""
function expose_data(context, data)
    return available_data(context, data)
end


"""Defines the unique identifier to an equity asset given a journal entry of the ledger"""
function keyJE(journalEntry::Union{DotMap,Dict})
    return get(journalEntry, "exchangeName", "MISSING") *
           "/" *
           get(journalEntry, "ticker", "MISSING")
end

"""
    addSecurityToPortfolio!(portfolio::Union{DotMap,Dict},security::Union{DotMap,Dict})

    StaticMarket method to add  securities to portfolios .
"""
function addSecurityToPortfolio!(
    portfolio::Union{DotMap,Dict}, journalEntry::Union{DotMap,Dict}
)
    key = get(journal_entry, "assetID", keyJE(journalEntry))
    if !(haskey(portfolio, key)) # A try catch approach may be more performant
        portfolio[key] = 0
    end
    portfolio[key] += get(journalEntry, "shares", nothing)
    return nothing
end

function securityFromJournalEntry(x)
    return Dict(
        "exchangeName" => x["exchangeName"],
        "ticker" => x["ticker"],
        "shares" => x["shares"],
        "price" => x["price"],
    )
end
function addSecurityToPortfolio!(portfolio::Vector{Any}, journalEntry::Union{DotMap,Dict}) # Multiple-dispatch of method in case of portfolio being a vector.
    push!(portfolio, securityFromJournalEntry(journalEntry))
    return nothing
end

function addSecurityToPortfolio!(portfolio::Portfolio, security::Security) # Multiple-dispatch of method in case of portfolio being a vector.
    asset_symbol = get(
        journal_entry,
        "assetSymbol",
        Symbol(get(journal_entry, "assetID", keyJE(journalEntry))),
    )
    portfolio += Security{asset_symbol}(journal_entry["shares"])
    return nothing
end

"""
    addJournalEntryToLedger(ledger::Vector{Any},journalEntry::Union{DotMap,Dict})

    StaticMarket method to add journal entries to ledger.
"""
function addJournalEntryToLedger(ledger::Vector{Any}, journalEntry::Union{DotMap,Dict})
    return push!(ledger, journalEntry)
end

"""
    execute_orders(from, to, context,data)

    This function updates the portfolio of the user that is stored in the variable context.
    
    TODO: Add more documentation.
"""
function execute_orders!(from, to, context::Contexts, data::DataFrame)
    # Retrieve data
    cur_data = get_latest(available_data(context, data), [:exchangeName, :symbol], :date)
    incomplete_orders = Vector{Any}([])
    # Iterate over orders
    while length(context.activeOrders) > 0
        order = pop!(context.activeOrders)
        success = true
        if order.specs.type == "MarketOrder"

            # Transaction data
            price = cur_data[cur_data.symbol .== order.specs.ticker, :open][1] # Retrieve price
            shares = order.specs.shares # Determine number of shares
            transaction_amount = price * order.specs.shares #  Total transaction amount

            # Partial order corrections
            if (transaction_amount >= order.specs.account.balance) && (shares > 0) # If not enough money to buy execute partially
                success = false
                transaction_amount = order.specs.account.balance
                shares = transaction_amount / price
                # Enhancement TODO: Here there should be some logic to allow/forbid fractional transactions
            end

            if shares == 0 # Skip steps below if there are no shares to trade
                continue
            end

            # TODO: Modify Accpimt
            order.specs.account.balance -= transaction_amount

            # Form Security # This depends on portfolio formulation which is defined in the context! 
            # TODO: Modularize From here! 
            journal_entry = Dict(
                "exchangeName" => order.market,
                "ticker" => order.specs.ticker,
                "shares" => shares,
                "price" => price,
            )
            journal_entry = deepcopy(security)
            journal_entry["price"] = price
            journal_entry["amount"] = transaction_amount
            journal_entry["date"] = deepcopy(to) # Improve the logic of determining when a transaction takes place
            journal_entry["assetID"] = keyJE(journalEntry)
            # I.e. one could define an open and close times for a market and use that instead.
            addJournalEntryToLedger(context.ledger, journal_entry)

            addSecurityToPortfolio!(context.portfolio, journal_entry)
            # Finalize Modularization from here

        elseif order.specs.type == "LimitOrder"
            @info "LimitOrder has not yet been implemented, please use MarketOrder"
        end

        # Incomplete orders are to be put back
        if !(success)
            order.specs.shares -= shares # Reduce the amount of shares
            push!(incomplete_orders, order)
        end
    end
    return append!(context.activeOrders, incomplete_orders)
end

function parse_accountHistory(accountHistory) # Probably I will also need the value of the stock at the audit point in time.
    accounts = Set([key for p in accountHistory for key in keys(p)])
    N = length(accountHistory)
    baseDf = DataFrame(; ix=1:N)#, C=1:500)
    for account in accounts
        baseDf[!, account] = [
            get(get(a, account, nothing), "balance", nothing) for a in accountHistory
        ]
    end
    return select!(baseDf, Not([:ix]))
end

function parse_portfolioHistory(portfolioHistory) # Probably I will also need the value of the stock at the audit point in time.
    assetIds = Set([key for p in portfolioHistory for key in keys(p)])
    N = length(portfolioHistory)
    baseDf = DataFrame(; ix=1:N)#, C=1:500)
    for asset in assetIds
        baseDf[!, asset] = [get(p, asset, nothing) for p in portfolioHistory]
    end
    return select!(baseDf, Not([:ix]))
end

end
