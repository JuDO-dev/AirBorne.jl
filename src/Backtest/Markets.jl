"""
    Strategies

    This module centralizes access to different market models.

    A market model is tuple with a module and a struct that can be used to simulate/estimate the execution of orders.  

    A market can represent a stock exchange like NYSE or secondary markets.

    Assumptions made during the modelling of the market will have a direct impact on the results from backtesting,
    any result from backtesting should be referenced to a strategy and a market model. 
"""
module Markets
include("./markets/StaticMarket.jl")
end
