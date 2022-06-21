# this is a test script to run the code to show what functions the user would have access to 
# and what they would be able to do
include("Data.jl")  
include("Plotting.jl")
include("Behavioural.jl")
include("Errors.jl")
include("Buy_sell.jl")

# RUN EACH SECTION ONE AT A TIME BY UNCOMMENTING

# folder = "C:\\Users\\Alexander scos\\Documents\\FYP\\Results\\Simple vs Machine\\"

# # Outputs for Report 

# # Simple vs ML -------------------------------------------------------------------------

all_data = get_data("AAPL", "2016-07-11", "2021-07-10", "", "1d")
adj_close = all_data[:, 6]

# adj_close_norm = normalize(adj_close)
# train, test = split_train_test(adj_close_norm)

# # Naive ------------------------------------------------------------------------------
# lag = 1
# naive_predictions = naive(adj_close_norm, lag)
# pred_train, pred_test = split_train_test(naive_predictions)
# plot_comparison(pred_test, test, "Predictions", "Test Data", "Graph of Naive Predictions and Test Data lag = $lag", "Days", "Price")
# # Plots.savefig(string(folder, "lag_app_$lag"))
# mse = Flux.mse(pred_test, test)
# println(mse)

# # SMA --------------------------------------------------------------------------------

# n = 3
# sma_predictions = sma(adj_close_norm, n)
# sma_predictions = remove_last_i_vals(sma_predictions, 1)
# pred_train, pred_test = split_train_test(sma_predictions)
# plot_comparison(pred_test, test, "Predictions", "Test Data", "Graph of SMA Predictions and Test Data n = $n", "Days", "Price")
# # Plots.savefig(string(folder, "sma_app_$n"))
# mse = Flux.mse(pred_test, test)
# println(mse)

# # LIN -------------------------------------------------------------------------------

# n = 3
# lin_predictions = linear_prediction(adj_close_norm, n, 1)
# linear_predictions = remove_last_i_vals(lin_predictions, 1)
# pred_train, pred_test = split_train_test(linear_predictions)
# plot_comparison(pred_test, test, "Predictions", "Test Data", "Graph of Linear Predictions and Test Data n = $n", "Days", "Price")
# # Plots.savefig(string(folder, "lin_app_$n"))
# mse = Flux.mse(pred_test, test)
# println(mse)

# --------------------------------------------------------------------------------------------------

## Simple vs Behavioural

all_data = get_data("AMZN", "2018-01-01", "2021-01-01", "", "1d")
adj_close = all_data[:, 6]

# Previous price values only 

# depths = [10, 20]
# gamma = [0.1, 0.7]
# num_preds = 1

# # folder = "C:\\Users\\Alexander scos\\Documents\\FYP\\Results\\Simple vs Behavioural\\"

# adj_close_train , adj_close_test = split_train_test(adj_close)
# adj_close_standard = standardize(adj_close, adj_close_train)

# train_standard, test_standard = split_train_test(adj_close_standard)

# for i = 1:size(depths, 1)
#     for j = 1:size(gamma, 1)
#         L = depths[i]
#         γ = gamma[j]
#         predictions = behavioural_prediction(adj_close_standard, train_standard, test_standard, L, num_preds, γ)
#         pred_rescaled = rescale(predictions, adj_close_train)
#         plot_behavioural_data(adj_close_test, pred_rescaled, L, γ)
#         mse, mae, est = estimate_errors(pred_rescaled, adj_close_test)
#         println("L = $L γ = $γ", "MSE error is $mse", "MAE error is $mae", "Est error is $est")
#     end
# end

# plot graphs of error vs depth and error vs gamma

# ms_vals, ma_vals, est_vals = get_error_vs_depth(adj_close_standard, train_standard, adj_close_train, test_standard, num_preds, 10, 20, 0.1)
# ms_vals2, ma_vals2, estvals2 , gamma_vals = get_error_vs_gamma(adj_close_standard, train_standard, adj_close_train, test_standard, 10, 1)
# plot_error_vs_depth(ms_vals, 10, 20, "MSE", 0.1)
# plot_error_vs_gamma(ms_vals2, gamma_vals, 10, "MSE")

# perform same tests on same data with the Simple methods to get graphs and values

# Naive ------------------------------------------------------------------------------
# lag = 1
# naive_predictions = naive(adj_close, lag)
# pred_train, pred_test = split_train_test(naive_predictions)
# plot_comparison(pred_test, adj_close_test, "Predictions", "Test Data", "Graph of Naive Predictions and Test Data lag = $lag", "Days", "Price")
# # Plots.savefig(string(folder, "lag_app_$lag"))
# mse = Flux.mse(pred_test, adj_close_test)
# mae = Flux.mae(pred_test, adj_close_test)
# println("MSE for Naive is $mse ", "MAE for Naive is $mae ")

# # SMA --------------------------------------------------------------------------------

# n = 3
# sma_predictions = sma(adj_close, n)
# sma_predictions = remove_last_i_vals(sma_predictions, 1)
# pred_train, pred_test = split_train_test(sma_predictions)
# plot_comparison(pred_test, adj_close_test, "Predictions", "Test Data", "Graph of SMA Predictions and Test Data n = $n", "Days", "Price")
# # Plots.savefig(string(folder, "sma_app_$n"))
# mse = Flux.mse(pred_test, adj_close_test)
# mae = Flux.mae(pred_test, adj_close_test)
# println("MSE for SMA is $mse ", "MAE for SMA is $mae ")

# # LIN -------------------------------------------------------------------------------

# n = 3
# lin_predictions = linear_prediction(adj_close, n, 1)
# linear_predictions = remove_last_i_vals(lin_predictions, 1)
# pred_train, pred_test = split_train_test(linear_predictions)
# plot_comparison(pred_test, adj_close_test, "Predictions", "Test Data", "Graph of Linear Predictions and Test Data n = $n", "Days", "Price")
# # Plots.savefig(string(folder, "lin_app_$n"))
# mse = Flux.mse(pred_test, adj_close_test)
# mae = Flux.mae(pred_test, adj_close_test)
# println("MSE for SMA is $mse ", "MAE for SMA is $mae ")

# Using Previous Price AND Volume Data ------------------------------------------------------------------------------

all_data = get_data("AMZN", "2018-01-01", "2021-01-01", "", "1d")
adj_close = all_data[:, 6]
vol = all_data[:, 7]

# vol_train, vol_test = split_train_test(vol)
# adj_close_train , adj_close_test = split_train_test(adj_close)

# adj_close_standard = standardize(adj_close, adj_close_train)
# vol_standard = standardize(vol, vol_train)

# data_standard = [adj_close_standard vol_standard]
# train_standard, test_standard = split_train_test(data_standard)

# for i = 1:size(depths, 1)
#     for j = 1:size(gamma, 1)
#         L = depths[i]
#         γ = gamma[j]
#         predictions = behavioural_prediction(data_standard, train_standard, test_standard, L, num_preds, γ)
#         pred_rescaled = rescale(predictions, adj_close_train)
#         plot_behavioural_data(adj_close_test, pred_rescaled, L, γ)
#         # Plots.savefig(string(folder, "Price_vol","depth_$L", "_gamma_$j"))
#         mse, mae, est = estimate_errors(pred_rescaled, adj_close_test)
#         println("L = $L γ = $γ", "MSE error is $mse", "MAE error is $mae", "Est error is $est")
#     end
# end

# Buy Sell Test using Historical Price and volume Data -----------------------------------------------------------------------------
# L = 10 : γ =  0.1 This was the best value tested before
L = 10
γ = 0.1
num_preds = 1

all_data = get_data("AMZN", "2018-01-01", "2021-01-01", "", "1d")
adj_close = all_data[:, 6]
vol = all_data[:, 7]

# vol_train, vol_test = split_train_test(vol)
# adj_close_train , adj_close_test = split_train_test(adj_close)

# adj_close_standard = standardize(adj_close, adj_close_train)
# vol_standard = standardize(vol, vol_train)

# data_standard = [adj_close_standard vol_standard]
# train_standard, test_standard = split_train_test(data_standard)

# # do predictions for all
# predictions = behavioural_prediction(data_standard, train_standard, test_standard, L, num_preds, γ)
# pred_rescaled = rescale(predictions, adj_close_train)
# # split adj close test values in half 
# adj_close_test_1 = adj_close_test[1:floor(Int, size(adj_close_test, 1)/2)]
# adj_close_test_2 = adj_close_test[floor(Int, size(adj_close_test, 1)/2)+1:size(adj_close_test, 1)]

# # split predictions in half 
# clean = collect(skipmissing(pred_rescaled))
# pred_rescaled_1 = clean[1:floor(Int, size(clean, 1)/2)]
# pred_rescaled_2 = clean[floor(Int, size(clean, 1)/2)+1:size(clean, 1)]

# # calculate errors for all predictions and get the get the confidence interval
# abs_matx, rel_matx, perc_matx= get_error_matrix(pred_rescaled, adj_close_test, adj_close_train)

# # get first half of error matrix 
# rel_matx_1 = rel_matx[1:floor(Int, size(adj_close_test, 1)/2)]
# normal, x, pdf, kde = est_distribution(rel_matx_1, 30)
# lower, upper = get_confidence_int(normal, 0.9)
# plot_histogram(rel_matx_1, normal, x, pdf, kde, lower, upper, "Relative", 30)

# # Then do the Buy sell strategy
# holding = Holding(0, 0, 10000)
# holding, value, curr_price = buy_sell_hold(holding, upper, lower, 0.0, 0.0, pred_rescaled_2, adj_close_test_1, adj_close_test_2, 0.001)
# println(holding)
# println(value)

# SMA ---------------------------------------------------------------------

# adj_close_train , adj_close_test = split_train_test(adj_close)

# # split adj close
# adj_close_test_1 = adj_close_test[1:floor(Int, size(adj_close_test, 1)/2)]
# adj_close_test_2 = adj_close_test[floor(Int, size(adj_close_test, 1)/2)+1:size(adj_close_test, 1)]

# n = 3
# sma_predictions = sma(adj_close, n)
# sma_predictions = remove_last_i_vals(sma_predictions, 1)
# pred_train, pred_test = split_train_test(sma_predictions)

# pred_test_2 = pred_test[floor(Int, size(pred_test, 1)/2)+1: size(pred_test,1)]

# abs_matx, rel_matx, perc_matx= get_error_matrix(pred_test, adj_close_test, adj_close_train)

# rel_matx_1 = rel_matx[1:floor(Int, size(adj_close_test, 1)/2)]

# normal, x, pdf, kde = est_distribution(rel_matx_1, 30)
# lower, upper = get_confidence_int(normal, 0.9)
# plot_histogram(rel_matx_1, normal, x, pdf, kde, lower, upper, "Perc", 30)

# holding = Holding(0, 0, 10000)
# holding, value, curr_price = buy_sell_hold(holding, upper, lower, 0.0, 0.0, pred_test_2, adj_close_test_1, adj_close_test_2, 0.001)
# println(holding)
# println(value)

# Linear -----------------------------------------------------------------------------

# n = 3
# lin_predictions = linear_prediction(adj_close, n, 7)
# linear_predictions = remove_last_i_vals(lin_predictions, 1)
# pred_train, pred_test = split_train_test(linear_predictions)

# pred_test_2 = pred_test[floor(Int, size(pred_test, 1)/2)+1: size(pred_test,1)]

# abs_matx, rel_matx, perc_matx = get_error_matrix(pred_test, adj_close_test, adj_close_train)

# rel_matx_1 = rel_matx[1:floor(Int, size(adj_close_test, 1)/2)]

# normal, x, pdf, kde = est_distribution(rel_matx_1, 30)
# lower, upper = get_confidence_int(normal, 0.9)
# plot_histogram(rel_matx_1, normal, x, pdf, kde, lower, upper, "Perc", 30)

# holding = Holding(0, 0, 10000)
# holding, value, curr_price = buy_sell_hold(holding, upper, lower, 0.0, 0.0, pred_test_2, adj_close_test_1, adj_close_test_2, 0.001)
# println(holding)
# println(value)

# Buy/Sell 7 days ahead --------------------------------------------------------------------------------------------------

# all_data = get_data("AMZN", "2018-01-01", "2021-01-01", "", "1d")
# adj_close = all_data[:, 6]
# vol = all_data[:, 7]

# # L = 10 : γ =  0.1 This was the best value tested before
# L = 10
# γ = 0.1
# num_preds = 7

# vol_train, vol_test = split_train_test(vol)
# adj_close_train , adj_close_test = split_train_test(adj_close)

# adj_close_standard = standardize(adj_close, adj_close_train)
# vol_standard = standardize(vol, vol_train)

# data_standard = [adj_close_standard vol_standard]
# train_standard, test_standard = split_train_test(data_standard)

# # do predictions for all
# predictions = behavioural_prediction(data_standard, train_standard, test_standard, L, num_preds, γ)
# pred_rescaled = rescale(predictions, adj_close_train)
# # split adj close test values in half 
# adj_close_test_1 = adj_close_test[1:floor(Int, size(adj_close_test, 1)/2)]
# adj_close_test_2 = adj_close_test[floor(Int, size(adj_close_test, 1)/2)+1:size(adj_close_test, 1)]

# # split predictions in half and select only 7 day ahead predictions
# clean = collect(skipmissing(pred_rescaled[:, 7]))
# pred_rescaled_1 = clean[1:floor(Int, size(clean, 1)/2)]
# pred_rescaled_2 = clean[floor(Int, size(clean, 1)/2)+1:size(clean, 1)]

# # calculate errors for all predictions and get the get the confidence interval
# abs_matx, rel_matx, perc_matx= get_error_matrix(pred_rescaled, adj_close_test, adj_close_train)

# # get first half of error matrix and select only 7 day ahead predictions
# rel_matx_1 = rel_matx[1:floor(Int, size(adj_close_test, 1)/2), num_preds]
# normal, x, pdf, kde = est_distribution(rel_matx_1, 30)
# lower, upper = get_confidence_int(normal, 0.9)
# plot_histogram(rel_matx_1, normal, x, pdf, kde, lower, upper, "Relative", 30)

# # Then do the Buy sell strategy
# holding = Holding(0, 0, 10000)
# holding, value, curr_price = buy_sell_hold(holding, upper, lower, 0.0, 0.0, pred_rescaled_2, adj_close_test_1, adj_close_test_2, 0.001)
# println(holding)
# println(value)

# SMA ----------------------------------------------------------------------------------------------------------
# Buy_sell test would be the same as the prediction 1 day ahead as an avg of last 3 days 
# would be the same as prediction 7 days ahead as an avg of last 3 days.

# Linear --------------------------------------------------------------------------------------------------------

# n = 3
# lin_predictions = linear_prediction(adj_close, n, 7)
# linear_predictions = remove_last_i_vals(lin_predictions, 1)
# pred_train, pred_test = split_train_test(linear_predictions)

# pred_test_2 = pred_test[floor(Int, size(pred_test, 1)/2)+1: size(pred_test,1)]

# abs_matx, rel_matx, perc_matx = get_error_matrix(pred_test, adj_close_test, adj_close_train)

# rel_matx_1 = rel_matx[1:floor(Int, size(adj_close_test, 1)/2)]

# normal, x, pdf, kde = est_distribution(rel_matx_1, 30)
# lower, upper = get_confidence_int(normal, 0.9)
# plot_histogram(rel_matx_1, normal, x, pdf, kde, lower, upper, "Perc", 30)

# holding = Holding(0, 0, 10000)
# holding, value, curr_price = buy_sell_hold(holding, upper, lower, 0.0, 0.0, pred_test_2, adj_close_test_1, adj_close_test_2, 0.001)
# println(holding)
# println(value)


