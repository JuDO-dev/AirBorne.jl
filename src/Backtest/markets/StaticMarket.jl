"""
    StaticMarket

    The static market assumes that the prices of the assets are not affected by the strategy used. 

    This is a big assumption for large orders but for smaller ones it can hold.
"""
module StaticMarket
export execute_orders!, expose_data, Order, parse_portfolioHistory, parse_accountHistory
using DataFrames: DataFrame, Not, select!
using DotMaps: DotMap
using ...Structures: ContextTypeA
using ...Utils: get_latest

Context = ContextTypeA

"""
    Order

    Represents an order to the market. I.e. A stock exchange. 
    
    TODO: Add more documentation
"""
struct Order
    market::String
    specs::DotMap
end

function place_order!(context, order)
    return push!(context.activeOrders, order)
end

"""
    available_data(context,data)

    This function determine what data is available given the context.
"""
function available_data(context, data)
    return data[data.date .<= context.current_event.date, :]
end

"""
    expose_data(context,data)

    This function determine how the data is transformed and filtered before being passed to the user.
"""
function expose_data(context, data)
    return available_data(context, data)
end

"""
    addSecurityToPortfolio(portfolio::Union{DotMap,Dict},security::Union{DotMap,Dict})

    StaticMarket method to add  securities to portfolios .
"""
function addSecurityToPortfolio(portfolio::Union{DotMap,Dict}, security::Union{DotMap,Dict})
    key =
        get(security, "exchangeName", "MISSING") * "/" * get(security, "ticker", "MISSING")
    if !(haskey(portfolio, key)) # A try catch approach may be more performant
        portfolio[key] = 0
    end
    return portfolio[key] += get(security, "shares", nothing)
end

function addSecurityToPortfolio(portfolio::Vector{Any}, security::DotMap) # Multiple-dispatch of method in case of portfolio being a vector.
    return push!(portfolio, security)
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
function execute_orders!(from, to, context, data)
    cur_data = get_latest(available_data(context, data), [:exchangeName, :symbol], :date)
    incomplete_orders = Vector{Any}([])

    while length(context.activeOrders) > 0
        order = pop!(context.activeOrders)
        success = true
        if order.specs.type == "MarketOrder"

            # Transaction data
            price = cur_data[cur_data.symbol .== order.specs.ticker, :open][1]
            shares = order.specs.shares
            transaction_amount = price * order.specs.shares

            # Partial order corrections
            if (transaction_amount >= order.specs.account.balance) && (shares > 0) # If not enough money to buy execute partially
                success = false
                transaction_amount = order.specs.account.balance
                shares = transaction_amount / price
                # TODO: Here there should be some logic to allow/forbid fractional transactions
            end

            if shares == 0 # Skip steps below if there are no shares to trade
                continue
            end

            order.specs.account.balance -= transaction_amount

            # Form Security
            security = Dict(
                "exchangeName" => order.market,
                "ticker" => order.specs.ticker,
                "shares" => shares,
                "price" => price,
            )

            journal_entry = deepcopy(security)
            journal_entry["price"] = price
            journal_entry["amount"] = transaction_amount
            journal_entry["date"] = deepcopy(to) # Improve the logic of determining when a transaction takes place
            # I.e. one could define an open and close times for a market and use that instead.

            addJournalEntryToLedger(context.ledger, journal_entry)
            addSecurityToPortfolio(context.portfolio, security)

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
