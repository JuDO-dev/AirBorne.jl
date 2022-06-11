#implement generic buy/sell algorithm
#if tmrw's predictions is higher than x% current price : buy
#if tmrw's prediction is lower that x% current price :   sell
#if tmrw's predictions is with +-x% current price:       hold

#start with I amount of money
#Cannot spend more than I amount
#Calculate amount of money left 

export buy_sell_hold


mutable struct Holding
    shares::Float64
    investment::Float64
    funds_available::Float64
end


function buy_sell_hold(holding::Holding, upper_bound::Float64, lower_bound::Float64, buy_val::Float64, sell_val::Float64, predictions::Array, train_data::Array, test_data::Array)
    current_price = train_data[size(train_data, 1)]

    for i=1:size(test_data, 1)
        pred_price = predictions[size(train_data, 1)+i]
        upper_price = (1+upper_bound)*current_price
        lwr_price = (1-lower_bound)*current_price

        if (predictions[size(train_data, 1)+i]>= (1+upper_bound)*current_price)
            action = (pred_price, upper_price, lwr_price, "Buying")
            println()
            println(action)
            println("Current Price is $current_price")
            buy_update(holding, current_price, buy_val)
            println(holding)
            current_price = test_data[i]
        elseif (predictions[size(train_data, 1)+i] <= (1-lower_bound)*current_price)
            action = (pred_price, upper_price, lwr_price, "Selling")
            println()
            println(action)
            sell_update(holding, current_price, sell_val)
            println(holding)
            current_price = test_data[i]
        else
            action = (pred_price, upper_price, lwr_price, "Holding")
            println()
            println(action)
            println("Current Price is $current_price")
            hold_update(holding)
            println(holding)
            current_price = test_data[i]
        end
    end

    return holding, holding.shares*current_price, current_price

end

function sell_update(holding::Holding,  curr_price::Float64, sell_val::Float64)
    if (holding.investment > sell_val)
        trans_val = sell_val #perc*holding.investment
        holding.shares = holding.shares - trans_val/curr_price
        holding.investment = holding.investment - trans_val 
        holding.funds_available = holding.funds_available + trans_val
    else 
        return holding
    end
end

function buy_update(holding::Holding, curr_price::Float64, buy_val::Float64)
    if (holding.funds_available > buy_val)
        trans_val = buy_val #perc*holding.funds_available
        holding.shares = holding.shares + trans_val/curr_price
        holding.investment = holding.investment + trans_val
        holding.funds_available = holding.funds_available - trans_val
    else 
        return holding
    end
end

function hold_update(holding::Holding)
    return holding
end




