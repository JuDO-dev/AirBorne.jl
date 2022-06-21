#implement generic buy/sell algorithm
#if tmrw's predictions is higher than x% current price : buy
#if tmrw's prediction is lower that x% current price :   sell
#if tmrw's predictions is with +-x% current price:       hold

#start with I amount of money
#Cannot spend more than I amount
#Calculate amount of money left 
using Distributions

export buy_sell_hold


mutable struct Holding
    shares::Float64
    investment::Float64
    funds_available::Float64
end


function buy_sell_hold(holding::Holding, upper_bound::Float64, lower_bound::Float64, buy_val::Float64, sell_val::Float64, predictions::Array, test_data_1::Array, test_data_2::Array, commission::Float64)
    current_price = test_data_1[size(test_data_1, 1)]

    for i=1:size(test_data_2, 1)
        pred_price = predictions[i]
        upper_price = (1+abs(upper_bound))*current_price
        lwr_price = (1-abs(lower_bound))*current_price

        if (pred_price >= upper_price)
            action = (pred_price, upper_price, lwr_price, "Buying")
            println()
            println(action)
            println("Current Price is $current_price")
            buy_update(holding, current_price, buy_val, commission)
            println(holding)
            current_price = test_data_2[i]
        elseif (pred_price <= lwr_price)
            action = (pred_price, upper_price, lwr_price, "Selling")
            println()
            println(action)
            println("Current Price is $current_price")
            sell_update(holding, current_price, sell_val, commission)
            println(holding)
            current_price = test_data_2[i]
        else
            action = (pred_price, upper_price, lwr_price, "Holding")
            println()
            println(action)
            println("Current Price is $current_price")
            hold_update(holding)
            println(holding)
            current_price = test_data_2[i]
        end
    end

    return holding, holding.shares*current_price, current_price

end

function sell_update(holding::Holding,  curr_price::Float64, sell_val::Float64, commission::Float64)
    # uncomment below if you want to implement without selling entire hlding when you buy/sell
    # # if (holding.shares*curr_price >= sell_val)
    # #     trans_val = sell_val  #perc*holding.investment
    # #     holding.shares = holding.shares - trans_val/curr_price
    # #     holding.investment = holding.investment - trans_val 
    # #     holding.funds_available = holding.funds_available + (trans_val - sell_val*commission)
    # # else 
    
    #     return holding
    # end
    if (holding.shares > 0)
        trans_val = holding.shares*curr_price
        holding.shares = 0
        holding.funds_available = trans_val - (trans_val*commission)
    end
    return holding
end

function buy_update(holding::Holding, curr_price::Float64, buy_val::Float64, commission::Float64)
    # uncomment below if you want to implement without selling entire hlding when you buy/sell
    # if (holding.funds_available >= buy_val)
    #     trans_val = buy_val  #perc*holding.funds_available
    #     holding.shares = holding.shares + trans_val/curr_price
    #     holding.investment = holding.investment + trans_val
    #     holding.funds_available = holding.funds_available - (trans_val + buy_val*commission)
    #     if(holding.investment > holding.max_invested)
    #         holding.max_invested = holding.investment
    #     end
    # else 
    #     return holding
    # end
    if (holding.funds_available > 0)
        trans_val = holding.funds_available - (holding.funds_available*commission)
        holding.shares = trans_val/curr_price
        holding.funds_available = 0
    end
    return holding
end

function hold_update(holding::Holding)
    return holding
end






