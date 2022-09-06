"""This file is for plotting the predicted prices of a chosen stock, against the correct values"""

#include("Data.jl")  
include("Plotting.jl")
include("Behavioural_AM.jl")
include("Errors_AM.jl")
using Plots
L = 26
gamma = 0.01
data_size = 12
sample_frequency = 1
ahead_predictions = 1
stocks = "XOM"
start_date = "2022-07-24"
end_date = "2022-07-29"
#This gets the data of a stock given some parameters, using yfinance API
all_data = get_data(stocks, start_date, end_date, "", "1m")

#Get the predictions with the corresponding validation set
validation_set, predictions = get_prediction_vs_truevalue(L, gamma, data_size, sample_frequency, ahead_predictions, all_data)

println(size(validation_set))
println(size(predictions))
#Plot the predicted values against the correct ones
p = Plots.plot(1:size(validation_set, 2)-1, [predictions[1:end-1] , validation_set[:, 1:end-1]'], label= ["Prediction" "Actual"], legend =:top)
title!(p, "XOM - 1 Minute Ahead Predictions vs Actual Prices")
xlabel!(p, "1 Minute")
ylabel!(p, "Price (USD)")
display(p)
Plots.savefig("XOM_ActualvsPrediced_1minAhead.png")