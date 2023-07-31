"""
    MeanVarianceMPC

    This module provides a template strategy we call Mean Variance Model Predictive Control or Mean-Variance MPC for short.

    This strategy provides seeks the set of optimal portfolio distributions over time considering the cost of changing positions and 
    a forecast on the expected returns and as well covariance matrix of returns.

"""
module MeanVarianceMPC
# Internal Dependencies
using ...Utils: sortedStructInsert!, rvcat, rblockdiag
using ...Structures: ContextTypeA
using ...Markets.StaticMarket: Order, place_order!, ordersForPortfolioRedistribution
using ...ETL.AssetValuation: stockValuation, returns, covariance

# External Dependencies
using Dates: DateTime
using DataFrames: DataFrame
using DotMaps: DotMap
using JuMP:
    @variable,
    @expression,
    Model,
    @objective,
    @constraint,
    optimize!,
    @NLobjective,
    value,
    set_silent
using SparseArrays: sparse, I, spdiagm
using Ipopt: Ipopt
import MathOptInterface as MOI

"""
    predeterminedReturns(context::ContextTypeA,returnData::DataFrame)
    
    Returns a sequence of tuples with (returnVector,CovarianceMatrix). Since the values of the predeterminedReturns is assumed to be known constants
    the variance and convariance between assets is set to 0.

    -`returnData::DataFrame`: Dataframe that has one row per time and a column per assetID at least containing the elements of *context.extra.symbolOrder*. Each 
    entry on the dataframe corresponds to the return of 1 unit of the assetId of the corresponding column between the time of the previous row and its corresponding row .
    
    To use this function context needs to have defined the following attributes:
    -`context.extra.symbolOrder::Vector{String}`: The order in which the return and covariance matrix vector should be expressed.
    -`context.current_event::TimeEvent`: The current event of the simulation. (Mandatory for context)
    -`context.parameters.horizon::Int64`: The number of sequences to be read from returnData and transformed into tuples of return vector and variance matrices.

    To use this forecast in the tradingLogicMPC! strategy
    ```julia
        forecastFun(context) = predeterminedReturns(context, returnsData) # returnsData must already be defined.
        custom_trading_logic!(context,data) = tradingLogicMPC!(context,data;forecastFun=forecastFun) 
    ```
"""
function predeterminedReturns(context::ContextTypeA, returnData::DataFrame)
    n_assets = length(context.extra.symbolOrder)
    horizon = context.parameters.horizon
    r_mat =
        float.(
            Matrix(
                first(
                    returnData[
                        returnData.date .> context.current_event.date,
                        context.extra.symbolOrder,
                    ],
                    horizon,
                ),
            )
        )
    Σ = zeros(n_assets, n_assets)
    return [(r_mat[i, :], Σ) for i in 1:horizon] # Mean-Variance Forecast 
end

function initialize!(
    context::ContextTypeA;
    min_data_samples::Int64=200,
    currency_symbol::String="FEX/USD",
    initialCapital::Float64=10.0^5,
    parameters::Dict=Dict(),
    otherExtras::Dict=Dict(),
)

    # Internal Data Storage
    context.extra.returnsHistory = DataFrame()

    # Fixed attributes & parameters
    context.extra.min_data_samples = min_data_samples
    context.extra.currency_symbol = currency_symbol

    context.extra.valueHistory = DataFrame()
    context.extra.returnHistory = DataFrame()
    context.extra.currentValue = DataFrame()
    context.extra.pastValue = DataFrame()

    [setindex!(context.extra, otherExtras[key], key) for key in keys(otherExtras)]

    # Initialize Accounts     
    context.accounts.usd = DotMap(Dict())
    context.accounts.usd.balance = initialCapital
    context.accounts.usd.currency = currency_symbol

    # Initialize Portfolio
    if :symbolOrder in keys(context.extra)
        push!(context.extra.symbolOrder, currency_symbol)
        [setindex!(context.portfolio, 0.0, n) for n in context.extra.symbolOrder] # Initialize an empty portfolio
    end
    context.portfolio[currency_symbol] = initialCapital # Sync portfolio with account at first

    # Adjustable hyper-parameters by StrategyOptimization
    [setindex!(context.parameters, parameters[key], key) for key in keys(parameters)]

    return nothing
end

function tradingLogic!(context, data; forecastFun::Function=linearRegressionForecast)

    #######################
    ####  Update data  ####
    #######################
    if size(data, 1) == 0 # No New data, nothing to do
        return nothing
    end
    context.extra.pastValue = context.extra.currentValue

    context.extra.currentValue = stockValuation(data)
    context.extra.currentValue[!, context.extra.currency_symbol] .= 1.0 # Add currency to values

    [push!(context.extra.valueHistory, r) for r in eachrow(context.extra.currentValue)]

    if size(context.extra.pastValue, 1) > 0 # Add new data to history record
        r1 = returns(vcat(context.extra.pastValue, context.extra.currentValue))
        push!(context.extra.returnHistory, r1[end, :])
    end

    ###############
    ####  MPC  ####
    ###############

    if size(context.extra.returnHistory, 1) < context.extra.min_data_samples
        return nothing # Not enough history data to continue
    end

    # Forecasts
    meanVarianceForecast = forecastFun(context) # Returns a sequence of Return vectors and Covariance matrices

    # Matrices Definitions
    r = rvcat([rV[1] for rV in meanVarianceForecast]) # Return Vector
    Q = rblockdiag([rV[2] for rV in meanVarianceForecast]) # Block diagonal with covariance matrices in the diagonal
    𝛾_trade = get(context.parameters, "propCost", 0.05)
    𝛾_risk = get(context.parameters, "riskWeight", 0.0)
    n_assets = length(context.extra.symbolOrder)
    T = context.parameters.horizon
    B1 = kron(sparse(I, T, T), ones(1, n_assets)) # Matrix such that when multiplied by X, it returns a vector of ones of length T

    # Optimization Problem
    model = Model(Ipopt.Optimizer)
    set_silent(model)
    @variable(model, x[1:length(r)] >= 0)
    @variable(model, sum_portfolio_differences)
    @constraint(
        model,
        [sum_portfolio_differences; x[1:(end - n_assets)] - x[(n_assets + 1):end]] in
            MOI.NormOneCone(1 + length(x) - n_assets)
    ) # Implementation of norm-1
    @objective(
        model, Min, -r' * x + 𝛾_trade * sum_portfolio_differences + 𝛾_risk * (x' * Q * x)
    ) # With variance minimization
    @constraint(model, B1 * x .- ones(T, 1) .== 0) # Sum of portfolio distribution equals 1 for all days
    optimize!(model)
    sol = round.(value.(x)[1:n_assets]; digits=3) # Best next portfolio distribution

    # Decode solution into buy/sell orders
    assetPricing = context.extra.currentValue[1, "stockValue"]
    assetPricing[context.extra.currency_symbol] = 1.0
    orders = ordersForPortfolioRedistribution(
        convert(Dict{String,Float64}, context.portfolio),
        Dict([context.extra.symbolOrder[i] => sol[i] for i in 1:n_assets]),
        assetPricing;
        account=context.accounts.usd,
        curency_symbol=context.extra.currency_symbol,
        costPropFactor=𝛾_trade,
    )
    [place_order!(context, order) for order in orders] # Place orders
    return nothing
end
end
