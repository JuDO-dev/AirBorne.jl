"""
    Markowits Portfolio Optimization

    It assumes the returns of the individual stocks to be a stationary stochastic process, not necessarily 
    independet. Therefore it has a constant mean and variance matrix for the asset returns.


    From stock prices it assumes the returns to be 
    This implementation follow the one in [JuMP non-linear Portfolio Optimization](https://jump.dev/JuMP.jl/stable/tutorials/nonlinear/portfolio/)
    
"""
module Markowitz

using ...Utils: sortedStructInsert!
using ...Structures: ContextTypeA, TimeEvent
using ...Markets.StaticMarket: Order, place_order!
using ...ETL.AssetValuation: stockValuation, returns, covariance
using Dates: Day, year
using DataFrames: DataFrame, groupby, combine, mean, Not
using DotMaps: DotMap
using DirectSearch:
    DSProblem,
    Optimize!,
    SetInitialPoint,
    SetObjective,
    SetIterationLimit,
    SetGranularity,
    AddExtremeConstraint,
    AddProgressiveConstraint

function initialize!(
    context::ContextTypeA;
    horizon::Real=30,
    initialCapital::Real=10^5,
    min_growth::Real=0.001,
)
    ###################################
    ####  Parameters & Structures  ####
    ###################################
    context.extra.horizon = horizon

    context.extra.valueHistory = DataFrame()
    context.extra.returnHistory = DataFrame()
    context.extra.currentValue = DataFrame()
    context.extra.pastValue = DataFrame()

    context.extra.idealPortfolioDistribution = []
    context.extra.min_growth = min_growth

    ###################################
    ####  Specify Account Balance  ####
    ###################################
    context.accounts.usd = DotMap(Dict())
    context.accounts.usd.balance = initialCapital
    context.accounts.usd.currency = "USD"

    #########################################
    ####  Define first simulation event  ####
    #########################################
    # Define First Event (Assumming the first event starts from the data
    # The first even should be at least as long as the long horizon)
    next_event_date = context.current_event.date
    new_event = TimeEvent(next_event_date, "data_transfer")
    sortedStructInsert!(context.eventList, new_event, :date)
    return nothing
end

function trading_logic!(
    context::ContextTypeA, data::DataFrame; tune_parameters::Dict=Dict()
)
    # 1. Specify next event (precalculations can be specified here) 
    next_event_date = context.current_event.date + Day(1)
    new_event = TimeEvent(next_event_date, "data_transfer")
    sortedStructInsert!(context.eventList, new_event, :date)

    # 2. Generate orders and  place orders
    # 2.1 Update data
    if size(data, 1) == 0 # No New data, nothing to do
        return nothing
    end
    context.extra.pastValue = context.extra.currentValue
    context.extra.currentValue = stockValuation(data)
    [push!(context.extra.valueHistory, r) for r in eachrow(context.extra.currentValue)]

    if size(context.extra.pastValue, 1) > 0 # Add new data to history record
        r1 = returns(vcat(context.extra.pastValue, context.extra.currentValue))
        push!(context.extra.returnHistory, r1[end, :])
    end

    # 2.2 Calculate Statistics
    if size(context.extra.returnHistory, 1) < context.extra.horizon
        return nothing # Not enough history data to 
    end

    d = context.extra.returnHistory[(end - context.extra.horizon + 1):end, :]
    M = covariance(d) # Covariance Matrix
    m = mean(Matrix(d[!, Not(["date", "stockReturns"])]); dims=1)
    max_return, ix = findmax(m)
    if max_return > context.extra.min_growth # Feasible problem
        # 2.3 Solve Optimization problem
        if context.extra.idealPortfolioDistribution == []
            initial_point = zeros(size(m))
            initial_point[ix] = 1.0
        else
            initial_point = context.extra.idealPortfolioDistribution
        end

        upper_cons(x) = all(x .<= 1)
        lower_cons(x) = all(x .>= 0)
        min_return(x) = context.extra.min_growth - (m * x)[1] # I want at least a 0.1% return in 1 day 
        obj(x) = x' * M * x

        p = DSProblem(length(m))
        SetGranularity(p, Dict([i => 0.001 for i in 1:length(m)]))
        SetObjective(p, obj)
        AddProgressiveConstraint(p, min_return)
        AddExtremeConstraint(p, upper_cons)
        AddExtremeConstraint(p, lower_cons)
        SetInitialPoint(p, vec([i for i in initial_point]))
        Optimize!(p)
        context.extra.idealPortfolioDistribution = p.x
    else
        context.extra.idealPortfolioDistribution = zeros(size(m)) # Sell absolutely everytihng. Market is going down.
    end
    check = false
    if isnothing(context.extra.idealPortfolioDistribution) # Feasible solution not found!, sell all
        context.extra.idealPortfolioDistribution = zeros(size(m))
        check = true
    end

    # 2.4 Calculate shares to buy and sell to achieve optimal portfolio
    asset_names = names(context.extra.currentValue)[2:(end - 1)]
    cv = reshape(Matrix(context.extra.currentValue)[2:(end - 1)], (length(asset_names))) # Current value per share for ticker
    if length(context.portfolio) == 0 # Obtain vector with current portfolio
        context.portfolio = Dict(
            [name => 0.0 for name in names(context.extra.currentValue)][2:(end - 1)]
        )
    end
    currentPortfolio = reshape(Matrix(DataFrame(context.portfolio)), (length(asset_names)))
    total_capital = context.accounts.usd.balance + (currentPortfolio' * cv)[1] # Total capital to distribute 
    if check
        @info "Check:" context.extra.idealPortfolioDistribution total_capital cv
        @info "Check:" size(context.extra.idealPortfolioDistribution) size(total_capital) size(
            cv
        )

        @info context.extra.idealPortfolioDistribution .* total_capital
        @info [
            context.extra.idealPortfolioDistribution[i] * total_capital / cv[i] for
            i in 1:length(cv)
        ]
    end
    # nextPortfolio =  reshape(context.extra.idealPortfolioDistribution.*total_capital ./ cv, (length(asset_names))) # Amount of shares to have of each ticker
    nextPortfolio = reshape(
        [
            context.extra.idealPortfolioDistribution[i] * total_capital / cv[i] for
            i in 1:length(cv)
        ],
        (length(asset_names)),
    ) # Amount of shares to have of each ticker
    portfolioDiff = nextPortfolio - currentPortfolio

    # Summarize
    diffDf = DataFrame(Dict(["symbol" => asset_names, "diff" => portfolioDiff, "cv" => cv]))
    diffDf[!, "total"] = diffDf.diff .* diffDf.cv
    diffDf = diffDf[diffDf.diff .!= 0, :] # Keep only non-zero values
    sort!(diffDf[diffDf.diff .!= 0, :], :total) # Sort such that largest sells happen first, and largest buy's later

    # 2.5 Produce and place orders
    for r in eachrow(diffDf)
        market, ticker = split(r.symbol, "/")
        order_specs = DotMap(Dict())
        order_specs.ticker = String(ticker)
        order_specs.shares = r.diff # Number of shares to buy/sell
        order_specs.type = "MarketOrder"
        order_specs.account = context.accounts.usd
        order = Order(String(market), order_specs)
        place_order!(context, order)
    end
    return nothing
end

end
