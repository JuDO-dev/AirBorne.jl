# All plotting functions are included in this file 
# uses functions from both simple.jl as well as errors.jl
# Use functions in this file to make plotting easier for a specified
# number of graphs as well as plot MSE data 

include("Simple.jl")
include("Errors.jl")
include("Behavioural.jl")

using PyPlot
using Plots

# export the functions that you want users to have access to when using your package

export plot_naive_data_range
export plot_sma_data_range
export plot_linear_data_range
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

function plot_naive_data_range(train_data::Array, test_data::Array, graphs::Int)

    # Train Data

    mse = zeros(0) # Create empty array for MSE values

    for i = 1:graphs
        predictions = naive(train_data, i) # Lags data by i days from Shifted Arrays Library

        calc_mse_naive(predictions, train_data, mse, i) # Prepare data for MSE

        plot_comparison(train_data, predictions, "Train Data", "Predictions", "Graph Showing Predictions with Lag = $i", "Day", "Price")  # Plot data
        Plots.savefig(string(lag_folder,"_Train_data_$i"))

    end

    plot_mse_vals(1:graphs,mse, "MSE", "MSE values for different Lag Values", "Lag", "MSE") # Plot mse values various lag values
    Plots.savefig(string(lag_folder,"_MSE_Train_data"))

    # Test Data

    mse = zeros(0)

    for i = 1:graphs
        predictions = naive(test_data, i)

        calc_mse_naive(predictions, test_data, mse, i) 
        
        plot_comparison(test_data, predictions, "Test Data", "Predictions", "Graph Showing Predictions with Lag = $i", "Day", "Price")
        Plots.savefig(string(lag_folder,"_Test_data_$i"))
    end 

    plot_mse_vals(1:graphs, mse, "MSE", "MSE values for different Lag Values", "Lag", "MSE")
    Plots.savefig(string(lag_folder,"_MSE_Test_data"))
end

# plots the predictions and the mean-squared error for the simple moving average predictions for both train and test_data using "start" number of data points
# for the average and increasing up to "start" + "graphs" number for data points to calculate the average.

function plot_sma_data_range(train_data::Array, test_data::Array, start::Int, graphs::Int)
    mse = zeros(0)  # Train_data
    for i = start:start + graphs
        predictions = sma(train_data,i) 

        calc_mse_sma(predictions, train_data, mse, i)

        plot_comparison(train_data, predictions, "Train_data", "Predictions", "Graph Showing Predicitions with Average = $i", "Day", "Price")
        Plots.savefig(string(sma_folder,"_Train_data_$i"))
    end 
    plot_mse_vals(start:start + graphs,mse, "MSE", "MSE values for different AVG Values", "AVG", "MSE")
    Plots.savefig(string(sma_folder,"_MSE_Train_data"))
    
    mse = zeros(0) # Test_data
    for i = start:start + graphs
        predictions = sma(test_data,i) 

        calc_mse_sma(predictions, test_data, mse, i)

        plot_comparison(test_data, predictions, "Test_data", "Predictions", "Graph Showing Predicitions with Average = $i", "Day", "Price")
        Plots.savefig(string(sma_folder,"_Test_data_$i"))
    end 
    plot_mse_vals(start:start + graphs, mse, "MSE", "MSE values for different AVG Values", "AVG", "MSE")
    Plots.savefig(string(sma_folder,"_MSE_Test_data"))
end

# plots the predictions and the mean-squared error for the linear predictions for both train and test_data using "start" number of data points
# for the linear fit and increasing up to "start" + "graphs" number for data points to calculate the linear fit.

function plot_linear_data_range(train_data::Array, test_data::Array, start::Int, graphs::Int)

    for i = start:start + graphs

        predictions = linear_prediction(train_data, i)
        plot_comparison(train_data, predictions, "Train Data", "Line", "Graph for Linear Model using Last $i days", "Day", "Price")
        Plots.savefig(string(linear_folder,"_Train_data_$i"))

    end 
    for i = start:start + graphs

        predictions = linear_prediction(test_data, i)
        plot_comparison(test_data, predictions, "Test Data", "Line", "Graph for Linear Model using Last $i days", "Day", "Price")
        Plots.savefig(string(linear_folder,"_Test_data_$i"))

    end 
end

# function for plotting predictions generated by the behavioural prediction against the test data
function plot_behavioural_data(data::Array, predictions::Array, depth, gamma)
    pred = collect(skipmissing(predictions[:,1 ]))
    plot_comparison(data, pred, "Test Data", "Prediction", "Behavioural Predictions, L = $depth , gamma = $gamma", "Day", "Price")
end 

# function for plotting the errors produced by get_error_matrix() for selected day
function plot_error_matx_data(error_matrix::Array, depth, num_preds, day, error_type::String)
    Plots.plot(error_matrix[:, day], label = "$error_type Error")
    Plots.display(Plots.plot!(title = "$error_type Error, day $day , L= $depth, P = $num_preds" , xlabel = "Day", ylabel = "$error_type Error"))
end 

# function for plotting the error calculated for the predictions generated for each of depths in the selected range
function plot_error_vs_depth(array::Array, start::Int, max_depth::Int, error_type::String, gamma::Float64)
    Plots.plot(start:max_depth, array, seriestype = :scatter, label = "MSE")
    Plots.display(Plots.plot!(title = "$error_type vs Depth for gamma = $gamma", xlabel = "Depth, L", ylabel = "MS Error"))
    Plots.savefig("C:\\Users\\Alexander scos\\Documents\\FYP\\$error_type _vs_Depth_vol")
end

# function for plotting the error calculated for the predictions generated for each of gamma values in the selected range
function plot_error_vs_gamma(array::Array, gamma_vals, depth::Int , error_type::String)
    Plots.plot(gamma_vals, array, seriestype = :scatter, label = "MSE")
    Plots.display(Plots.plot!(title = "$error_type vs Gamma for Depth = $depth", xlabel = "Gamma", ylabel = error_type))
    Plots.savefig("C:\\Users\\Alexander scos\\Documents\\FYP\\$error_type vs_Gamma_vol")
end

#function for plotting histogram and fitted pdf of the data generated from get_error_matrix()
function plot_histogram(array::Array, normal_dist, x_vals, pdf, kde, lower, upper, error_type::String, num_bins::Int)
    mean = round(normal_dist.μ, digits = 2)
    std = round(normal_dist.σ, digits = 2)
    PyPlot.figure()                      # start new figure

    (values, bins, _) = PyPlot.hist(array, bins=num_bins, density=true, alpha = 0.5) # estimate histogram with custom number of bins
    PyPlot.plot(x_vals, pdf, label = "Normal μ = $mean σ = $std")                                                  # plot the pdf
    PyPlot.plot(kde.x, kde.density, label = "KDE") # plot kernel density estimation

    max = Distributions.pdf(normal_dist, lower)
    # PyPlot.vlines(lower, ymax = 0.04, ymin = 0,  color = "black", alpha = 0.5)
    # PyPlot.vlines(upper, ymax = 0.04, ymin = 0, color = "black", alpha = 0.5)
    PyPlot.axvline(lower, color = "black", alpha = 0.5, linestyle = "--", label = "Lower and Upper Bounds")
    PyPlot.axvline(upper, color = "black", alpha = 0.5, linestyle = "--")

    PyPlot.title("Histogram and PDF estimation of $error_type Errors")
    PyPlot.legend()
    
    display(gcf())
end
