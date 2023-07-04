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
function keyJE(journal_entry::Union{DotMap,Dict})
    return get(journal_entry, "exchangeName", "MISSING") *
           "/" *
           get(journal_entry, "ticker", "MISSING")
end

"""
    addSecurityToPortfolio!(portfolio::Union{DotMap,Dict},journal_entry::Union{DotMap,Dict})

    StaticMarket method to add  securities to portfolios .
"""
function addSecurityToPortfolio!(
    portfolio::Union{DotMap,Dict}, journal_entry::Union{DotMap,Dict}
)
    key = get(journal_entry, "assetID", keyJE(journal_entry))
    if !(haskey(portfolio, key)) # A try catch approach may be more performant
        portfolio[key] = 0
    end
    portfolio[key] += get(journal_entry, "shares", nothing)
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
function addSecurityToPortfolio!(portfolio::Vector{Any}, journal_entry::Union{DotMap,Dict}) # Multiple-dispatch of method in case of portfolio being a vector.
    push!(portfolio, securityFromJournalEntry(journal_entry))
    return nothing
end

function addSecurityToPortfolio!(portfolio::Portfolio, journal_entry::Union{DotMap,Dict}) # Multiple-dispatch of method in case of portfolio being a vector.
    asset_symbol = get(
        journal_entry,
        "assetSymbol",
        Symbol(get(journal_entry, "assetID", keyJE(journal_entry))),
    )
    portfolio += Security{asset_symbol}(journal_entry["shares"])
    return nothing
end

"""
    addJournalEntryToLedger!(ledger::Vector{Any},journal_entry::Union{DotMap,Dict})

    StaticMarket method to add journal entries to ledger.
"""
function addJournalEntryToLedger!(ledger::Vector{Any}, journal_entry::Union{DotMap,Dict})
    return push!(ledger, journal_entry)
end

function addMoneyToAccount!(account::DotMap, journal_entry)
    return account.balance -= journal_entry["amount"]
end

"""
    Assuming a dataframe with one row per ticker where the ticker symbol is in the column symbol
    The price is assumed to be at the column "col"
"""
function refPrice(cur_data::DataFrame, ticker::Union{String,Symbol}; col::Symbol=:open)
    return cur_data[cur_data.symbol .== ticker, col][1]
end

""" executeOrder_CA(
    context::ContextTypeA, order::Order, cur_data::DataFrame; priceModel::Function=refPrice
)
    Default order execution method when using ContextTypeA in the simulation.
"""
function executeOrder_CA(
    context::ContextTypeA, order::Order, cur_data::DataFrame; priceModel::Function=refPrice
)
    success = true
    if order.specs.type == "MarketOrder"
        price = priceModel(cur_data, order.specs.ticker)
        shares = order.specs.shares # Determine number of shares (Real number)
        transaction_amount = price * order.specs.shares #  Total transaction amount
        if (transaction_amount >= order.specs.account.balance) && (shares > 0) # If not enough money to buy execute partially
            success = false
            transaction_amount = order.specs.account.balance
            shares = transaction_amount / price
            # Enhancement TODO: Here there should be some logic to allow/forbid fractional transactions
        end
        journal_entry = Dict(
            "exchangeName" => order.market,
            "ticker" => order.specs.ticker,
            "shares" => shares,
            "price" => price,
            "amount" => transaction_amount,
            "date" => context.current_event.date,
        )
        journal_entry["assetID"] = keyJE(journal_entry)
    elseif order.specs.type == "LimitOrder"
        @info "LimitOrder has not yet been implemented, please use MarketOrder"
    end
    return journal_entry, success
end

"""
    execute_orders(from, to, context,data)

    This function updates the portfolio of the user that is stored in the variable context.
    
    The static Market assumes that orders do not modify market attributes. Therefore orders can be executed
    sequentially without consideration on how the order on one asset may affect the price on another.
"""
function execute_orders!(
    context::Contexts, data::DataFrame; executeOrder::Function=executeOrder_CA
)
    # Retrieve data
    cur_data = get_latest(available_data(context, data), [:exchangeName, :symbol], :date)
    incomplete_orders = Vector{Any}([])
    # Iterate over orders
    while length(context.activeOrders) > 0
        order = pop!(context.activeOrders)
        journal_entry, success = executeOrder(context, order, cur_data)
        if !(success) # Incomplete orders are to be put back
            order.specs.shares -= journal_entry["shares"] # Reduce the amount of shares
            push!(incomplete_orders, order)
        end
        addJournalEntryToLedger!(context.ledger, journal_entry) # Audit Transaction in Ledger 
        addSecurityToPortfolio!(context.portfolio, journal_entry) # Implement change to Portfolio
        addMoneyToAccount!(order.specs.account, journal_entry) # Implement change in Account
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
