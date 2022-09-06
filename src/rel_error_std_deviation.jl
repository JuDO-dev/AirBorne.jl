include("Data.jl")  
include("Plotting.jl")
include("Behavioural_AM.jl")
include("Errors_AM.jl")

export std_deviation
#This is the function that would be minimized

#This function predicts prices on a moving window, calculates the errors and then outputs the standard deviation

"""Test data in this case referes to the amount of data used to calculate the standard deviation
Test data is considered to be 1/3 of the sample size
The amount of data to be used for training is a PARAMETER that would be optimized
    This function can directly be used for plotting"""
function std_deviation(L, gamma, data_size, ahead_predictions, stocks, start_date, end_date, sample_frequency)
    data_size = convert(Int64, data_size)
    sample_frequency = convert(Int64, sample_frequency)
    ahead_predictions = convert(Int64, ahead_predictions)
    #This gets the data of a stock given some parameters.
    all_data = get_data(stocks, start_date, end_date, "", "1m")

    #Extract the close prices and remove any corrupted extracted data
    adj_close_new = all_data[1:end-1, 6]'
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

    println(size(clean_new))
    println(size(adj_close_test_new))

    adj_close_test_new = adj_close_test_new[:, ahead_predictions:end]
    # calculate the relative errors and output the standard deviation of the relative errors
    rel_matx = get_error_matrix(clean_new[1:size(adj_close_test_new,2),:], adj_close_test_new')
    rel_error_change_rate = get_error_change_rate(clean_new[1:size(adj_close_test_new,2),:], adj_close_test_new', ahead_predictions)
    println(std(rel_matx))
    return std(rel_error_change_rate)

end

function MADS_std_deviation(params)
    """ This function is a MADS compatible version of the std_deviation function. This means that that this
    function only takes one input (vector) and outputs the error standard deviation, which is the output
    of std_deviation function. 
        The input is params, which is a vector of parameters that needs to be optimized. The first parameter 
    is the depth of the hankel matrix, the second parameter is gamma, which is the l1 norm parameter, 
    the third parameter is the data_size, which is a parameter that determines the best past data size to
    be used for the defined step ahead predictions.
        The output is the standard deviation of the relative error, same as the output of the std_deviation
    function."""
    L = params[1]
    gamma = params[2]
    data_size = params[3]
    sample_frequency = params[4]
    steps_ahead = params[5]
    println("L: $L, frequency: $sample_frequency, step ahead = $steps_ahead")
    stock = "AAPL"
    start_date = "2022-07-31"
    end_date = "2022-08-05"

    standard_dev = std_deviation(L, gamma, data_size, steps_ahead, stock, start_date, end_date, sample_frequency)

    return standard_dev
end

function std_deviation_adjusted_testsize(L, gamma, past_data_size, trial_data_size ,ahead_predictions, stocks, start_date, end_date, sample_frequency)
    data_size = convert(Int64, past_data_size)
    trial_data_size = convert(Int64, trial_data_size)
    #This gets the data of a stock given some parameters.
    all_data = get_data(stocks, start_date, end_date, "", sample_frequency)

    #Extract the close prices
    adj_close_new = all_data[:, 6]'

    #The following lines extracts train and test data, standardize the data then finally 
    #extracts the train and test data based on standardized data.

    #Test data in this case represent how much data is used to calculate the standard deviation of the error
    adj_close_train_new, adj_close_test_new = split_train_test(adj_close_new, "column")

    adj_close_train_new = adj_close_train_new[:, 1+data_size:end]
    adj_close_test_new = adj_close_test_new[:, 1:end-trial_data_size]
    #standardize the data to be able to use the lasso function.
    adj_close_standard_new = standardize(adj_close_new[:, 1+data_size:end], adj_close_train_new)

    data_standard_new = adj_close_standard_new #data_standard_new = [adj_close_standard_new]
    #train_standard_new, test_standard_new = split_train_test(data_standard_new, "column")
    train_standard_new = data_standard_new[:, 1:size(adj_close_train_new, 2)]
    test_standard_new = data_standard_new[:, size(adj_close_train_new, 2)+1:end-trial_data_size]

    # do predictions for all and rescale them
    predictions_new = behavioural_prediction_new(data_standard_new, train_standard_new, test_standard_new, L, ahead_predictions, gamma)
    pred_rescaled_new = rescale_new(predictions_new, adj_close_train_new)

    # skip the missing entries because predictions has missing entries 
    clean_new = collect(skipmissing(pred_rescaled_new))

    # println(clean_new)
    # println(adj_close_test_new)
    # calculate the relative errors and output the standard deviation of the relative errors
    rel_matx = get_error_matrix(clean_new[1:size(adj_close_test_new,2),:], adj_close_test_new')
    # println(rel_matx)
    return std(rel_matx)

end