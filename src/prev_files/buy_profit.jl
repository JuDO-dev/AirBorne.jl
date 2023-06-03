include("Data.jl")  
include("Plotting.jl")
include("Behavioural_AM.jl")
include("Errors_AM.jl")
include("strategies.jl")

using Plots
using PyPlot
using JuMP
using HiGHS

L = 20
gamma = 0.01
data_size = 5
sample_frequency = 1
ahead_predictions = 2
stocks = "AAPL"
start_date = "2016-01-01"
end_date = "2021-01-01"
#This gets the data of a stock given some parameters.
all_data = get_data(stocks, start_date, end_date, "", "1d")

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

rel_matx = get_nonabs_error_matrix(clean_new[1:size(adj_close_test_new,2),:], adj_close_test_new')

println(size(adj_close_test_new))
println(size(clean_new))

nlv, return_perc_vec, positive_return_probability, market_return_vec = basic_strategy(adj_close_test_new[:, 1:end-1], clean_new[1:end-1, :], 0.003)
zeroOrpositive_return_probability = (size(return_perc_vec[return_perc_vec .>= 0.0], 1)/size(return_perc_vec,1))*100
zeroOrpositive_market_probability = (size(market_return_vec[market_return_vec .>= 0.0], 1)/size(market_return_vec,1))*100
positive_market_probability = (size(market_return_vec[market_return_vec .> 0.0], 1)/size(market_return_vec,1))*100
println(size(return_percent_vec))
PyPlot.hist(return_percent_vec.*100, density=false, stacked = false, facecolor="blue", bins = 25)
#PyPlot.hist(market_return_vec.*100, density=false, stacked = false, facecolor="blue", bins = 25)
PyPlot.title("PYPL - Strategy decisions return percentages")
#PyPlot.title("XOM - Market return percentages")
PyPlot.xlabel("Return in %")
PyPlot.ylabel("Number of decisions")
#PyPlot.ylabel("Number of points")
println("Positive return probability = $positive_return_probability")
println("Zero of positive return probability = $zeroOrpositive_return_probability")
println("Market 0 or positive return probability = $zeroOrpositive_market_probability")
println("Market positive return probability = $positive_market_probability")


## Error analysis for the standard deviation
# p = Plots.plot(1:size(adj_close_test_new, 2), [clean_new[1:size(adj_close_test_new,2),:] , adj_close_test_new[:, 1:end]'], label= ["Prediction" "Actual"], legend =:best)
# title!(p, "AMZN - 4 min Ahead Predictions vs Actual Prices")
# xlabel!(p, "4 Minutes")
# ylabel!(p, "Prices (USD)")
# display(p)
# Plots.savefig("AMZN_ActualvsPrediced_1HourAhead.png")

# normal, x, pdf, kde = est_distribution(rel_matx)
# lower, upper = get_confidence_int(normal, 0.51)
# probability = get_probability(normal, upper)
# println("Lower: $lower and upper: $upper")
# plot_histogram(rel_matx, normal, x, pdf, kde, lower, upper, "Relative", 30)

#-------------------------------------------------------------------------------------------------------------#
"""This is a very basic strategy, where you buy at a buy signal and sell at a sell signal, with holding
in between. No minimum return added"""
# Set up the optimization problem
# global decision = Model(HiGHS.Optimizer)
# @variable(decision, -1 <= d <= 1, Int)
# global money_in_possession = 1000.0
# global stock_in_possession = 0.0
# global current_price = adj_close_test_new[1]
# market_gain = (adj_close_test_new[end] - adj_close_test_new[1])/adj_close_test_new[1] * money_in_possession + money_in_possession
# for i in 1:size(clean_new, 1)-1
#     global current_price = adj_close_test_new[i]
#     global next_price = adj_close_test_new[i+1]
#     global next_predicted_price = clean_new[i+1]
#     @objective(decision, Max, d*(next_predicted_price-current_price))
#     optimize!(decision);
#     if (value(d) == 1 && stock_in_possession == 0.0) #If predicted price is higher
#         global stock_in_possession = money_in_possession/current_price #buy with the current price
#         global money_in_possession = 0.0
#     elseif (value(d) == -1 && stock_in_possession != 0.0)
#         global money_in_possession = current_price*stock_in_possession
#         global stock_in_possession = 0.0
        
#     end
#     nlv = stock_in_possession*next_price + money_in_possession
#     println("Your net liquid value: $nlv")
# end
# println("Market gain/loss: $market_gain")

#------------------------------------------------------------------------------------------------------------#

# decision = Model(HiGHS.Optimizer)
# @variable(decision, -1 <= d <= 1, Int)
# global money_in_possession = 1000.0
# global stock_in_possession = 0.0
# global current_price = adj_close_test_new[1]
# global min_return_percent = 0.0004
# global return_percent_vec = Vector{Float64}()
# market_gain = (adj_close_test_new[end] - adj_close_test_new[1])/adj_close_test_new[1] * money_in_possession + money_in_possession
# for i in 1:size(clean_new, 1)-1
#     decision = Model(HiGHS.Optimizer)
#     @variable(decision, -1 <= d <= 1, Int)
#     global current_price = adj_close_test_new[i]
#     global next_price = adj_close_test_new[i+1]
#     global next_predicted_price = clean_new[i+1]
#     @objective(decision, Max, d*(next_predicted_price-current_price))
#     expected_return_percentage = (next_predicted_price - current_price)/current_price
#     if (expected_return_percentage > 0 && expected_return_percentage < min_return_percent)
#         @constraint(decision, c1, d == 0)
#     end
#     optimize!(decision);
#     if (value(d) == 1 && stock_in_possession == 0.0) #If predicted price is higher and this is the first buy signal
#         #buy with the current price
#         global stock_in_possession = money_in_possession/current_price 
#         # Calculate how much did the decision result in a return
#         percent_return = (stock_in_possession*next_price - money_in_possession)/money_in_possession
#         global money_in_possession = 0.0
#     elseif (value(d) == -1 && stock_in_possession > 0.0)
#         # Sell the holding to the current price
#         global money_in_possession = current_price*stock_in_possession
#         percent_return = 0
#         global stock_in_possession = 0.0
#     elseif (stock_in_possession > 0)
#         percent_return = (stock_in_possession*next_price - stock_in_possession*current_price)/(stock_in_possession*current_price)
#     elseif (stock_in_possession == 0)
#         percent_return = 0.0
#     end
#     #percent_return = (next_price-current_price)/current_price
#     push!(return_percent_vec, percent_return)
# end
# println(return_percent_vec)
# nlv = stock_in_possession*next_price + money_in_possession
# println("Your net liquid value: $nlv")
# println("Market gain/loss: $market_gain")

# println(size(return_percent_vec))
# PyPlot.hist(return_percent_vec.*100, density=false)
# PyPlot.xlabel("Return in %")
# PyPlot.ylabel("Number of decisions")


# display(Plots.plot(1:size(clean_new, 1), [clean_new adj_close_test_new']))