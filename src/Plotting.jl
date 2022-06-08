# All plotting functions are included in this file 
# uses functions from both simple.jl as well as errors.jl
# Use functions in this file to make plotting easier for a specified
# number of graphs as well as plot MSE data 

include("Simple.jl")
include("Errors.jl")
include("Behavioural.jl")

using Plots

# export the functions that you want users to have access to when using your package

export plot_naive_data
export plot_sma_data
export plot_linear_data
export plot_behavioural_data

# Specify folders for your plots to go in
# default folder will be.........

lag_folder = "C:\\Users\\Alexander scos\\Documents\\FYP\\Lag_Predictions\\Lag_Predictions"
linear_folder = "C:\\Users\\Alexander scos\\Documents\\FYP\\Linear_Predictions\\Linear_Pred_"
sma_folder = "C:\\Users\\Alexander scos\\Documents\\FYP\\Moving_Avg_Predictions\\Moving_Avgs"
behave_folder = "C:\\Users\\Alexander scos\\Documents\\FYP\\Behavioural\\Behavioural_"

# plots two sets of data on the same plot using the Plots package

function plot_comparison(data1::Array, data2::Array, data1label::String, data2label::String, title1::String, xlabel1::String, ylabel1::String)
    Plots.plot(data1, label = data1label)  #xlims = (floor(Int64,size(data1,1)*2/3)+1, size(data2,1)))
    Plots.plot!(data2, label = data2label)
    Plots.display(Plots.plot!(title = title1, xlabel = xlabel1, ylabel = ylabel1))
end

# plots the predictions and the mean squared error for the naive prediction for both train and test_data with an increasing delay up to "graphs"

function plot_naive_data(train_data::Array, test_data::Array, graphs::Int)

    # Train Data

    mse = zeros(0) # Create empty array for MSE values

    for i = 1:graphs
        predictions = naive(train_data, i) # Lags data by i days from Shifted Arrays Library

        calc_mse_naive(predictions, train_data, mse, i) # Prepare data for MSE

        plot_comparison(train_data, predictions, "Train Data", "Predictions", "Graph Showing Predictions with Lag = $i", "Day", "Price")  # Plot data
        savefig(string(lag_folder,"_Train_data_$i"))

    end

    plot_mse_vals(1:graphs,mse, "MSE", "MSE values for different Lag Values", "Lag", "MSE") # Plot mse values various lag values
    savefig(string(lag_folder,"_MSE_Train_data"))

    # Test Data

    mse = zeros(0)

    for i = 1:graphs
        predictions = naive(test_data, i)

        calc_mse_naive(predictions, test_data, mse, i) 
        
        plot_comparison(test_data, predictions, "Test Data", "Predictions", "Graph Showing Predictions with Lag = $i", "Day", "Price")
        savefig(string(lag_folder,"_Test_data_$i"))
    end 

    plot_mse_vals(1:graphs, mse, "MSE", "MSE values for different Lag Values", "Lag", "MSE")
    savefig(string(lag_folder,"_MSE_Test_data"))
end

# plots the predictions and the mean-squared error for the simple moving average predictions for both train and test_data using "start" number of data points
# for the average and increasing up to "start" + "graphs" number for data points to calculate the average.

function plot_sma_data(train_data::Array, test_data::Array, start::Int, graphs::Int)
    mse = zeros(0)  # Train_data
    for i = start:start + graphs
        predictions = sma(train_data,i) 

        calc_mse_sma(predictions, train_data, mse, i)

        plot_comparison(train_data, predictions, "Train_data", "Predictions", "Graph Showing Predicitions with Average = $i", "Day", "Price")
        savefig(string(sma_folder,"_Train_data_$i"))
    end 
    plot_mse_vals(start:start + graphs,mse, "MSE", "MSE values for different AVG Values", "AVG", "MSE")
    savefig(string(sma_folder,"_MSE_Train_data"))
    
    mse = zeros(0) # Test_data
    for i = start:start + graphs
        predictions = sma(test_data,i) 

        calc_mse_sma(predictions, test_data, mse, i)

        plot_comparison(test_data, predictions, "Test_data", "Predictions", "Graph Showing Predicitions with Average = $i", "Day", "Price")
        savefig(string(sma_folder,"_Test_data_$i"))
    end 
    plot_mse_vals(start:start + graphs, mse, "MSE", "MSE values for different AVG Values", "AVG", "MSE")
    savefig(string(sma_folder,"_MSE_Test_data"))
end

# plots the predictions and the mean-squared error for the linear predictions for both train and test_data using "start" number of data points
# for the linear fit and increasing up to "start" + "graphs" number for data points to calculate the linear fit.

function plot_linear_data(train_data::Array, test_data::Array, start::Int, graphs::Int)

    for i = start:start + graphs

        predictions = linear_prediction(train_data, i)
        plot_comparison(train_data, predictions, "Train Data", "Line", "Graph for Linear Model using Last $i days", "Day", "Price")
        savefig(string(linear_folder,"_Train_data_$i"))

    end 
    for i = start:start + graphs

        predictions = linear_prediction(test_data, i)
        plot_comparison(test_data, predictions, "Test Data", "Line", "Graph for Linear Model using Last $i days", "Day", "Price")
        savefig(string(linear_folder,"_Test_data_$i"))

    end 
end

function plot_behavioural_data(data::Array, predictions::Array, size_wd, depth, num_preds)
    plot_comparison(data, predictions[:, 1], "Test Data", "Prediction", "Behavioural Pred, wd = $size_wd, L = $depth , ahead = $num_preds", "Day", "Price")
    savefig(string(behave_folder,"_Train_data wd_$size_wd L_$depth Ahead_$num_preds"))
end 

function plot_error_data(error_matrix::Array, depth, num_preds, day, error_type::String)
    Plots.plot(error_matrix[:, day], label = "$error_type Error")
    Plots.display(Plots.plot!(title = "$error_type Error, day $day , L= $depth, P = $num_preds" , xlabel = "Day", ylabel = "$error_type Error"))
end 
