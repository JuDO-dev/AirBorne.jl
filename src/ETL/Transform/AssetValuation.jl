"""
    AssetValuation

    This module provides standardized asset valuation techniques compatible with 
    datastructures in this module.

"""
module AssetValuation
#AirBorne.ETL.AssetValuation
# ..=ETL
# ...= AirBorne 
using ...Utils: movingAverage, makeRunning
using DataFrames: DataFrame, groupby, unstack, combine, Not, select!
using Dates: DateTime
using Statistics: std, cov, mean

""" 
    assetValue(data::DataFrame;method::Symbol=:last_open)

    Provides a method to calculate the value of an asset given some data.
"""
function valuePortfolio(portfolio::Dict, stockValues::Dict)
    value = 0
    for assetID in keys(portfolio)
        value += portfolio[assetID] * stockValues[assetID]
    end
    return value
end

"""
    stockValuation(data::DataFrame ;col::Symbol=:close,assetCol::Symbol=:assetID)

    Provides the value of individual tickers (share of an equity asset) at a certain 
    point in time given a OHLCV dataframe.
"""
function stockValuation(data::DataFrame; col::Symbol=:close, assetCol::Symbol=:assetID)
    # Produce for each date and assetID (assetCol) a 3 column table with date, assetID and Value
    agg = combine(groupby(data, [:date, assetCol]), col => mean => :stockValue)
    # Generate 1 column per assetID containing its value and 1 row per date. 
    out = unstack(agg, assetCol, :stockValue)
    # Create an additional column summarizing the date values in a dictionary
    out[!, "stockValue"] = [
        Dict([t => x[t] for t in names(x) if t != "date"]) for x in eachrow(out)
    ]
    return out
end

"""
    covariance(assetValuesdf::DataFrame)

    Calculates the covariance matrix given a Asset Value DataFrame or an Asset Return DataFrame.
"""
function covariance(assetValuesdf::DataFrame)
    return cov(
        Matrix(
            assetValuesdf[
                :,
                filter(
                    x -> x ∉ ["date", "stockValue", "stockReturns"], names(assetValuesdf)
                ),
            ],
        ),
    )
end

"""
    returns(assetValuesdf::DataFrame) 

    Calculates the returns of each ticker in the Asset Value DataFrame. By default as the relative percent with respect to the previous element,
    the return of the first element is set to 0 as the starting point.
"""
function returns(assetValuesdf::DataFrame)
    out = deepcopy(assetValuesdf)
    select!(out, Not(:stockValue))
    for x in filter(x -> x ∉ ["date", "stockValue", "stockReturns"], names(assetValuesdf))
        out[!, x] = returns(out[!, x])
    end
    out[!, "stockReturns"] = [
        Dict([t => x[t] for t in names(x) if t != "date"]) for x in eachrow(out)
    ]
    return out
end

"""
    returns(array::Vector)
    
    Calculates the returns as relative percent with respect to the previous element. The return of the first element is set to 0 as the starting point.
"""
function returns(array::Vector)
    out = Array{Union{Float64,Nothing}}(undef, length(array)) # Preallocate memory
    out[1] = 0.0 # First return is always 0 (starting value)
    for i in 2:length(array)
        out[i] = (array[i] - array[i - 1]) / array[i - 1]
    end
    return out
end

"""
    sharpe(avgReturn::Vector,variance::Vector;riskFreeRate::Real=0.0)

    Calculates the sharpe ratio from 2 vectors of same length containing the mean and variance of the returns respectively.

"""
function sharpe(avgReturn::Vector, variance::Vector; riskFreeRate::Real=0.0)
    out = Array{Union{Float64,Nothing}}(undef, length(avgReturn)) # Preallocate memory
    for i in 1:length(avgReturn)
        if (
            variance[i] ∉ [0, nothing] &&
            !isnan(variance[i]) &&
            avgReturn[i] ∉ [nothing] &&
            !isnan(avgReturn[i])
        )
            out[i] = (avgReturn[i] - riskFreeRate) / variance[i]
        end
    end
    return out
end

"""
    sharpe(returns::Vector;riskFreeRate::Real=0.0,windowSize::Union{Int,Nothing}=nothing, startFrom::Int=1)

    Calculates the sharpe ratio from a single vector, by calculating its mean and variance over sliding 
    time windows.
    
"""
function sharpe(
    returns::Vector;
    riskFreeRate::Real=0.0,
    windowSize::Union{Int,Nothing}=nothing,
    startFrom::Int=1,
)
    avgReturn = movingAverage(returns; windowSize=windowSize, startFrom=startFrom)
    variance = makeRunning(returns, std; windowSize=windowSize, startFrom=startFrom)
    return sharpe(avgReturn, variance; riskFreeRate=riskFreeRate)
end

end
