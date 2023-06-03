"""This file is for plotting the relative errors histogram, with its KDE and normal fit"""

include("Data.jl")  
include("Plotting.jl")
include("Behavioural_AM.jl")
include("Errors_AM.jl")

using Plots
using JuMP
using HiGHS

L = 26
gamma = 0.01
data_size = 12
sample_frequency = 1
ahead_predictions = 1
stocks = "XOM"
start_date = "2022-07-24"
end_date = "2022-07-29"
#This gets the data of a stock given some parameters.
all_data = get_data(stocks, start_date, end_date, "", "1m")

#Extract the close prices and remove any corrupted extracted data
adj_close_new = all_data[:, 6]'
adj_close_new = adj_close_new[.~(isnan.(adj_close_new))]'

#Determine the best sampling period
adj_close_new = adj_close_new[:, 1:sample_frequency:end]

#The following lines extracts train and test data, standardize the data then finally 
#extracts the train and test data based on standardized data.

#Test data in this case represent how much data is used to calculate the standard deviation of the error
adj_close_train_new, adj_close_test_new = split_train_test(adj_close_new, "column")

adj_close_train_new = adj_close_train_new[:, 1+data_size:end]
#standardize the data to be able to use the lasso function.
adj_close_standard_new = standardize(adj_close_new[:, 1+data_size:end], adj_close_train_new)

data_standard_new = adj_close_standard_new #data_standard_new = [adj_close_standard_new]
#train_standard_new, test_standard_new = split_train_test(data_standard_new, "column")
train_standard_new = data_standard_new[:, 1:size(adj_close_train_new, 2)]
test_standard_new = data_standard_new[:, size(adj_close_train_new, 2)+1:end]

# do predictions for all and rescale them
predictions_new = behavioural_prediction_new(data_standard_new, train_standard_new, test_standard_new, L, ahead_predictions, gamma)
pred_rescaled_new = rescale_new(predictions_new, adj_close_train_new)

# skip the missing entries because predictions has missing entries 
clean_new = collect(skipmissing(pred_rescaled_new))
clean_new = clean_new[ahead_predictions:ahead_predictions:end, :]

adj_close_test_new = adj_close_test_new[:, ahead_predictions:end]
clean_new = clean_new[1:size(adj_close_test_new,2),:]

rel_matx = get_nonabs_error_matrix(clean_new[1:size(adj_close_test_new,2)-1,:], adj_close_test_new[:, 1:end-1]')

## Error analysis for the standard deviation
# p = Plots.plot(1:size(adj_close_test_new, 2), [clean_new[1:size(adj_close_test_new,2),:] , adj_close_test_new[:, 1:end]'], label= ["Prediction" "Actual"], legend =:best)
# title!(p, "AMZN - 4 min Ahead Predictions vs Actual Prices")
# xlabel!(p, "4 Minutes")
# ylabel!(p, "Prices (USD)")
# display(p)
# Plots.savefig("AMZN_ActualvsPrediced_1HourAhead.png")

normal, x, pdf, kde = est_distribution(rel_matx)
lower, upper = get_confidence_int(normal, 0.51)
probability = get_probability(normal, upper)
println("Lower: $lower and upper: $upper")
println(size(rel_matx))
plot_histogram(rel_matx, normal, x, pdf, kde, lower, upper, "Relative", 30)