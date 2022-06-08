# this is a test script to run the code to show what functions the user would have access to 
# and what they would be able to do
include("Data.jl")  
include("Plotting.jl")
include("Behavioural.jl")
include("Behavioural_errors.jl")
include("Buy_Sell_test.jl")

depth = 25    # Depth of hankel matrix
num_preds = 1 # Number of days to predict ahead

start = "2021-01-01"
finish = "2021-12-31"


all_data = get_data("AMZN", "2021-01-01","2021-12-31","", "1d")
train_df, test_df = split_train_test(all_data)

open = all_data[:, 2]
high = all_data[:, 3]
low = all_data[:, 4]
close = all_data[:, 5]
adj_close = all_data[:, 6]
vol = all_data[:, 7]

adj_close_train, adj_close_test = split_train_test(adj_close)
vol_train, vol_test = split_train_test(vol)

#These are Time Arrays need to convert to matrices
macd = get_MACD(all_data, adj_close_train, 4)
rsi = get_RSI(all_data, adj_close_train, 14)

adj_close = standardize(adj_close, adj_close_train)
vol = standardize(vol, vol_train)

all_data = [adj_close vol]
train, test = split_train_test(all_data)

size_wd = size(train, 1)-depth-num_preds

# plot_sma_data(adj_close_train, adj_close_test, 3, 1)

# we only care about the prices but we want to account for volume as well 
# do behavioural algorithm with both volume and adj_close but only plot adj_close prices
# only get predictions for adj close prices 
predictions = behavioural_prediction(all_data, train, test, depth, num_preds, 0.2)
pred_rescaled = rescale(predictions, adj_close_train)
adj_close_rescaled = rescale(adj_close, adj_close_train)
plot_behavioural_data(adj_close_rescaled, pred_rescaled, size_wd, depth, num_preds)

holding = Holding(0, 0, 10000)
buy_sell_hold(holding, 0.02, 0.05, 1500.0, 500.0, pred_rescaled, adj_close_train, adj_close_test)

# put the data together
# abs_matx, rel_matx, perc_matx= get_error_matrix(pred_rescaled, adj_close_test, adj_close_train)
# avg_matrix = get_avg_error(rel_matx)
# plot_error_data(rel_matx, depth, num_preds, 7, "Relative")
# plot_error_data(abs_matx, depth, num_preds, 7, "Absolute")
# plot_error_data(perc_matx, depth, num_preds, 7, "Percent")

