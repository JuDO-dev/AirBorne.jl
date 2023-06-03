"""This file has a function that takes several inputs and returns the profit. It is made to be suitable 
to be run in MADS"""

include("Plotting.jl")
include("Behavioural_AM.jl")
include("Errors_AM.jl")
include("strategies.jl")

using Plots
using PyPlot
using JuMP
using HiGHS

function MADS_basic_strategy_profit(params)
    """This function takes the parameters that are needed to run the long-sell strategy."""
    L = convert(Int64, params[1])
    gamma = params[2]
    data_size = convert(Int64, params[3])
    sample_frequency = convert(Int64, params[4])
    ahead_predictions = convert(Int64, params[5])
    threshhold = params[6]
    decision_interval = convert(Int64, params[7])

    println("L: $L, frequency: $sample_frequency, step ahead = $ahead_predictions, gamma = $gamma, data_size = $data_size, threshhold = $threshhold")

    stocks = "PYPL"
    start_date = "2002-01-01"
    end_date = "2022-01-01"
    #This gets the data of a stock given some parameters.
    all_data = get_data(stocks, start_date, end_date, "", "1wk")

    #validation_set, predictions = get_prediction_vs_truevalue(L, gamma, data_size, sample_frequency, ahead_predictions, all_data)
    
    validation_set, predictions = get_prediction_vs_truevalue_strategy(L, gamma, data_size, sample_frequency, ahead_predictions, all_data, decision_interval)

    println(size(predictions))
    println(size(validation_set))
    profit, return_percent_vec, positive_return_probability = basic_strategy(validation_set[:, 1:end-1], predictions[1:end-1, :], threshhold)

    return -1 * positive_return_probability
end

