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
using ....AirBorne: Portfolio, Security, Wallet, get_symbol
using ...Utils: get_latest, δ

using JuMP: Model, @variable, @objective, @constraint, optimize!, value, set_silent
using SparseArrays: sparse, I, spdiagm
using Ipopt: Ipopt
import MathOptInterface as MOI

"""
    Order

    Represents an order to the market. I.e. A stock exchange. 
    
    TODO: Add more documentation
"""
struct Order
    market::String
    specs::DotMap
end

place_order!(context::ContextTypeA, order) = push!(context.activeOrders, order)

"""
    available_data(context,data)

    This function determine what data is available given the context.
"""
available_data(context, data) = data[data.date .<= context.current_event.date, :]

"""
    expose_data(context,data)

    This function determine how the data is transformed and filtered before being passed to the user.

    # Arguments
    -`context::ContextTypeA`: Context of the simulation.
    - `data::DataFrame`: The dataframe provided to the simulation. 
    ### Optional keyword arguments
    -`historical::Bool=true`: If true returns data up to the specified event in the context, otherwise returns just data matching the
    time of the current event of the context.
"""
function expose_data(context::ContextTypeA, data::DataFrame; historical::Bool=true)
    if historical
        out = available_data(context, data)
    else
        out = data[data.date .== context.current_event.date, :]
    end
    return out
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
    asset_symbol = Symbol(get(journal_entry, "assetID", keyJE(journal_entry)))
    if !(asset_symbol in keys(portfolio))
        setindex!(portfolio.content, 0, asset_symbol) # Initialize Asset    
    end
    portfolio[asset_symbol] += (journal_entry["shares"])
    return nothing
end

"""
    addJournalEntryToLedger!(ledger::Vector{Any},journal_entry::Union{DotMap,Dict})

    StaticMarket method to add journal entries to ledger.
"""
function addJournalEntryToLedger!(ledger::Vector{Any}, journal_entry::Union{DotMap,Dict})
    return push!(ledger, journal_entry)
end

"""
    addMoneyToAccount!(account::DotMap, journal_entry)    

    StaticMarket method to add money to the accounts given an entry to ledger.
    The convention is that a positive ledger entry correspond to money exiting the account.
"""
function addMoneyToAccount!(account::DotMap, journal_entry)
    account.balance -= journal_entry["amount"]     # journal_entry["amount"] is Real
    return nothing
end

function addMoneyToAccount!(account::Wallet, journal_entry)
    x = journal_entry["amount"]
    account[get_symbol(x)] += x.value * -1
    return nothing
end

"""
    refPrice(cur_data::DataFrame, ticker::Union{String,Symbol}; col::Symbol=:open)
    
    Using the current data in the market establishes the price to be paid per a unit of an asset 
    (a share for example in equity).
    
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
        throw("LimitOrder has not yet been implemented, please use MarketOrder")
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
    context::ContextTypeA, data::DataFrame; executeOrder::Function=executeOrder_CA
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

"""
    genOrder(assetId::Union{String,Symbol},amount::Real; account::Any=nothing,orderType::String="MarketOrder")
    
    Shortcut to generate market orders, in it the assetId is defined by "ExchangeID/TickerSymol", 
    amount is a real number with the number of shares to be purchased, account is the account to be used to
    provide the money for the transaction and order type is the type of the order. 
"""
function genOrder(
    assetId::Union{String,Symbol},
    amount::Real;
    account::Any=nothing,
    orderType::String="MarketOrder",
)
    market, ticker = split(String(assetId), "/")
    order_specs = DotMap(Dict())
    order_specs.ticker = String(ticker)
    order_specs.shares = amount # Number of shares to buy/sell
    order_specs.type = orderType
    if !(isnothing(account))
        order_specs.account = account
    end
    return Order(String(market), order_specs)
end

"""
    ordersForPortfolioRedistribution(
        sourcePortfolio::Dict{String, Float64}, 
        targetDistribution::Dict{String, Float64},
        assetPricing::Dict{String, Float64};
        curency_symbol::String= "FEX/USD", 
        account::Any=nothing,
        costPropFactor::Real=0,
        costPerTransactionFactor::Real=0,
        )
    This function generates the orders to obtain a particular value distribution on a given portfolio and static pricing.
    It can consider proportional costs by scaling the orders amount by a factor and a fixed cost for each transacted asset.
    It returns the portfolio with the desired distribution and the maximum amount of value expressed in a particular currency.

    -`sourcePortfolio::Dict{String, Float64}`: Dictionary with assets and how many units of them are present in a portfolio 
    -`targetDistribution::Dict{String, Float64}`: Desired distribution of the total value of the portfolio across the whole shares. The values do not need to add to 1, linear scaling will be used.
    -`assetPricing::Dict{String, Float64}`: Value of each share of an asset, with a corresponding value expressed in terms of a currency.
    -`curency_symbol::String= "FEX/USD"`: Symbol used to represent the currency in which the transactions are goint to take place. By default dollars, it should have value 1 on the assetPricing dictionary.
    -`account::Any=nothing`: Argument to be passed to the account field in the orders.
    -`costPropFactor::Real=0`:  Fee rate applied to the sell or purchase of any asset proportional to the value of the transaction.
    -`costPerTransactionFactor::Real=0`: Fee per transaction, every time an asset is sold/bought this fill will apply.
"""
function ordersForPortfolioRedistribution(
    sourcePortfolio::Dict{String,Float64},
    targetDistribution::Dict{String,Float64},
    assetPricing::Dict{String,Float64};
    curency_symbol::String="FEX/USD",
    account::Any=nothing,
    costPropFactor::Real=0,
    costPerTransactionFactor::Real=0,
)
    # Generate Source Distribution from Portfolio
    totalValue = sum([sourcePortfolio[x] * assetPricing[x] for x in keys(sourcePortfolio)])
    sourceDst = Dict([
        x => sourcePortfolio[x] * assetPricing[x] / totalValue for
        x in keys(sourcePortfolio)
    ])

    assetSort = [x for x in keys(sourceDst)]
    N = length(assetSort)
    curency_pos = findall(x -> x == curency_symbol, assetSort)[1]
    ShareVals = [assetPricing[x] for x in assetSort]
    propShareVal = ShareVals ./ totalValue # Share Price expressed in terms of portfolio units.

    # Problem Vectorization: D1 + P*d - Fees -> D2*k
    D1 = [get(sourceDst, x, 0) for x in assetSort] # Source
    D2 = [get(targetDistribution, x, 0) for x in assetSort] # Objective
    M = zeros(N, N)
    M[curency_pos, :] = propShareVal .* -1 # Price to pay per share (without fees)
    P = spdiagm(0 => propShareVal) + M
    FDollars = SparseVector(N, [curency_pos], [1]) # Dollar Fees Vector

    #####
    ##### Optimization Problem
    #####
    genOrderModel = Model(Ipopt.Optimizer)
    set_silent(genOrderModel)
    @variable(genOrderModel, 0 <= k) # Proportionality factor (shrinkage of portfolio)
    @variable(genOrderModel, d[1:N])  # Amount to buy/sell of each asset
    @variable(genOrderModel, propFees >= 0) # Amount Proportional Fees
    @constraint(
        genOrderModel,
        [propFees; (propShareVal .* d) .* costPropFactor] in MOI.NormOneCone(1 + N)
    ) # Implementation of norm-1 for Fees
    @variable(genOrderModel, perTransactionFixFees >= 0) # Number of transactions fees
    @constraint(
        genOrderModel, perTransactionFixFees == sum(-δ.(d) .+ 1) * costPerTransactionFactor
    ) # Implementation of norm-1 for Fees
    @constraint(genOrderModel, d[curency_pos] == 0) # Do not buy or sell dollars (this is the currency).
    @constraint(
        genOrderModel,
        D1 .+ (P * d) .- (FDollars .* (propFees + perTransactionFixFees)) .== D2 .* k
    ) # Distribution ratio
    @objective(genOrderModel, Max, k) # With variance minimization
    optimize!(genOrderModel)
    d = value.(d)

    #### 
    #### Parsing & Order Generation
    ####
    amount = Dict([assetSort[x] => d[x] for x in 1:N if (x != curency_pos) && (d[x] != 0)])
    orders = [genOrder(x, amount[x]; account=account) for x in keys(amount)]
    return orders
end

end
