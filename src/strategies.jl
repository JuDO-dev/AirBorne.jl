"""This file is for the functions that define different strategies"""

using Noise

function basic_strategy(adj_close_test_new, clean_new, threshhold)
"""This function represents the long-sell basic strategy, the idea of the strategy is to buy when
the next predicted price is above the threshold, sells if the predicted price is less than the current
price, and hold otherwise.

Parameters: 
    adj_close_test_new: The actual prices for the chosen data set.
    clean_new: The predicted prices corresponding the the actual prices.
    threshhold: The precentage that represents the minimum increase amount for the strategy to buy.
    
Returns:
    nlv: Net Liquid Value.
    return_percent_vec: The return percentage that every decision lead to.
    positive_return_probability: the amount of elements that are greater than 0 from the return_percent_vec.
    market_return_vec: vector that has the market return percent at every point.
    """

    # Add gaussian noise here
    clean_new = add_gauss(clean_new, 0.0)

    decision = Model(HiGHS.Optimizer)
    @variable(decision, -1 <= d <= 1, Int)
    #Initial money
    global money_in_possession = 1000.0
    # Initial stock
    global stock_in_possession = 0.0
    global current_price = adj_close_test_new[1]
    global threshhold_g = threshhold
    global return_percent_vec = Vector{Float64}()
    global market_return_vec = Vector{Float64}()
    global commission = 0.002
    market_gain = (adj_close_test_new[end] - adj_close_test_new[1]) / adj_close_test_new[1] * money_in_possession*(1-commission) + money_in_possession*(1-commission)
    for i in 1:size(clean_new, 1)-1 #A loop to run the simulation
        decision = Model(HiGHS.Optimizer)
        @variable(decision, -1 <= d <= 1, Int)
        global current_price = adj_close_test_new[i]
        global next_price = adj_close_test_new[i+1]
        global next_predicted_price = clean_new[i+1]
        @objective(decision, Max, d * (next_predicted_price - current_price))
        expected_return_percentage = (next_predicted_price - current_price) / current_price
        if (expected_return_percentage > 0 && expected_return_percentage < threshhold_g)
            @constraint(decision, c1, d == 0)
        end
        set_optimizer_attribute(decision, "output_flag", false)
        set_optimizer_attribute(decision, "log_to_console", false)
        optimize!(decision)
        if (value(d) == 1 && stock_in_possession == 0.0) #If predicted price is higher and this is the first buy signal
            #buy with the current price
            global stock_in_possession = (money_in_possession*(1-commission)) / current_price
            # Calculate how much did the decision result in a return
            percent_return = (stock_in_possession * next_price - money_in_possession) / money_in_possession
            global money_in_possession = 0.0
        elseif (value(d) == -1 && stock_in_possession > 0.0)
            # Sell the holding to the current price
            global money_in_possession = current_price * stock_in_possession
            global money_in_possession = money_in_possession*(1-commission)
            percent_return = -1 * commission
            global stock_in_possession = 0.0
        elseif (stock_in_possession > 0)
            percent_return = (stock_in_possession * next_price - stock_in_possession * current_price) / (stock_in_possession * current_price)
        elseif (stock_in_possession == 0)
            percent_return = 0.0
        end
        market_return = (next_price-current_price)/current_price
        push!(market_return_vec, market_return)
        push!(return_percent_vec, percent_return)
    end
    println(return_percent_vec)
    nlv = stock_in_possession * next_price + money_in_possession
    println("Your net liquid value: $nlv")
    println("Market gain/loss: $market_gain")
    positive_return_probability = (size(return_percent_vec[return_percent_vec.>0], 1)/size(return_percent_vec,1))*100
    return nlv, return_percent_vec, positive_return_probability, market_return_vec
end