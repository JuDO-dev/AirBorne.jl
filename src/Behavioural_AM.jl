"""This file is for function related to the behavioral control predictions"""
using LinearAlgebra
using Statistics
using Plots
using Random
using JuMP
using DelimitedFiles
using SCS
using Convex
using ShiftedArrays
using Flux
using MarketTechnicals
using TimeSeries
using Dates

import MathOptInterface

include("Data.jl")

export hankel_vector_new
export form_w_given
export hankel_scalar
export Lasso
export find_w_given
export behavioural_new
export behavioural_prediction_new
export form_w_given_new


function hankel_vector_new(w_d::Array, L::Any) 
    """Creates the hankel matrix"""
    L = convert(Int64, L)
    dim = size(w_d, 1) #Dimension (how many signals used)
    Tmin = (dim + 1)*L-1 #T_min=(m + 1)*L - 1
    T = size(w_d, 2) #Trajectory time length
    Lmax = floor((T+1)/(dim+1)) #L_max = floor (T+1)/(q+1)

    # if(T < Tmin) || (L > Lmax)
    #     println("Min length is $Tmin, length of matrix is $T")
    #     println("Max depth is $Lmax, depth selected is $L")
    #     return 
    #else
        hank = Array{Float64}(undef, dim*L, (T-L+1))
        for i=1:L
            hank[(i-1)*dim+1:(i-1)*dim+dim, :] = w_d[:, i:T-L+i]
        end
    #end
    hank
end

function hankel_scalar(traj, L)
    hank = Array{Float64}(undef, L, (size(traj,1)-L+1))
    for i=1:(size(traj,1)-L+1)
        for j=1:L
            hank[j,i] = traj[j+i-1]
        end   
    end
    hank
end

function Lasso(Y, X, γ, λ = 0)  
    #taken from https://jump.dev/Convex.jl/stable/examples/general_examples/lasso_regression/
    # this function can't solve for matrix of matrices
    (T, K) = (size(X, 1), size(X, 2))
    b_ls = X \ Y                    #LS estimate of weights, no restrictions

    Q = X'X / T
    c = X'Y / T                      #c'b = Y'X*b

    b = Variable(K)              #define variables to optimize over
    L1 = quadform(b, Q)            #b'Q*b
    L2 = dot(c, b)                 #c'b
    L3 = norm(b, 1)                #sum(|b|)
    L4 = sumsquares(b)            #sum(b^2)

    if λ > 0
        Sol = minimize(L1 - 2 * L2 + γ * L3 + λ * L4)      #u'u/T + γ*sum(|b|) + λ*sum(b^2), where u = Y-Xb
    else
        Sol = minimize(L1 - 2 * L2 + γ * L3)               #u'u/T + γ*sum(|b|) where u = Y-Xb
    end
    solve!(Sol, SCS.Optimizer; silent_solver = true)
    Sol.status == Convex.MOI.OPTIMAL ? b_i = vec(evaluate(b)) : b_i = NaN

    return b_i, b_ls
end

function find_w_given(traj, times)
    w_given = zeros(0)
    for i= 1:size(times, 1)
        append!(w_given, traj[times[i]])
    end
    w_given
end


function behavioural_new(wd, w_given, L, T, γ)
    t_given = 1:size(w_given, 1)
    hank = hankel_vector_new(wd, L)
    #print(size(hank))

    b_opt, b_ls = Lasso(w_given, hank[t_given, :], γ) 
    values = hank*b_opt

    predictions = values[(size(wd, 1)*T)+1:size(wd, 1)*L]
    # if the hankel matrix and w_given contain more than just price data we need to 
    # extract only the adj close values since "prediction" will contain prediction values for 
    # all data used e.g will contain adj_close and volume predictions

    adj_close_predictions = get_adj_close_predictions(predictions, size(wd, 1))

    return adj_close_predictions
end


function behavioural_prediction_new(data::Array, optimization_set::Array, validation_set::Array, hankel_depth::Any, step_ahead_preds::Int, γ)
    #Hankel depth is casted to Int because it is initially a float, to be compatible with MADS
    hankel_depth = convert(Int64, hankel_depth)

    #Empty array is a place holder for the predictions with the size of test data 
    #+1 because you predict on a moving window, so one extra prediction is made from the data.
    #This extra prediction is disregarded later
    empty_array = Array{Float64}(undef, size(validation_set,2)+1, step_ahead_preds)

    #To be able to solve mising data estimation problem, some data is used for the 
    #least squares estimate of the parameters, and such amount of data is dependent on the depth of the 
    #Hankel matrix. The depth is also one of the parameters to be optimized. w_given is the data used for 
    #least squares estimation

    #The size of w_given is the depth - the step ahead predictions
    w_tba_size = hankel_depth-step_ahead_preds #Size of w_given (t_given)

    #wd is the data matrix formed, from behavioral control theory
    size_wd = size(optimization_set, 2)-w_tba_size

    for i in 1:size(validation_set,2)+1
        #form w_given with moving window based on the depth of the hankel matrix, which is optimized
        w_given = form_w_given_new(data[:,i+size_wd:i+size(optimization_set, 2)-1]) #Flatten the data
        tmp_preds = behavioural_new(data[:, i:i+size_wd-1], w_given, hankel_depth, w_tba_size, γ)
        tmp_preds = Array(transpose(tmp_preds))
        empty_array[i, :] =  tmp_preds
    end
    tmp_miss = Array{Union{Missing, Int}}(missing, size(optimization_set, 1), step_ahead_preds)
    predictions = empty_array
    predictions = (vcat(tmp_miss, empty_array))
    predictions
end

function form_w_given_new(array::Array)
    empty_array = Array{Float64}(undef, size(array, 1)*size(array, 2), 1) 
    empty_array = reshape(array, (size(array, 1)*size(array, 2), 1))
    empty_array
end

function get_adj_close_predictions(predictions::Array, space::Int)
    adj_close_predictions = Array{Float64}(undef, Int(size(predictions, 1)/space), 1)
    counter = 1
    for i=1:size(adj_close_predictions, 1)
        adj_close_predictions[i, 1] = predictions[counter]
        counter = counter + space
    end
    adj_close_predictions
end

function get_prediction_vs_truevalue(L, gamma, data_size, sample_frequency, ahead_predictions, all_data)
    """This function takes in 6 parameters:
            1. all_data: downloaded stock data from yfinance
            2. L: Depth of the Hankel matrix
            3. gamma: regularization parameter
            4. data_size: deals with how much past data should be used
            5. Sampling_frequency: how often should the stock prices be sampled
            6. ahead_predictions: how far ahead into the future should we predict
            
    This function outputs the predictions with their corresponding real values"""
    #Extract the close prices and remove any corrupted extracted data
    adj_close_new = all_data[:, 6]'
    adj_close_new = adj_close_new[.~(isnan.(adj_close_new))]'

    #Determine the best sampling period
    adj_close_new = adj_close_new[:, 1:sample_frequency:end]

    #The following lines extracts train and test data, standardize the data then finally 
    #extracts the train and test data based on standardized data.

    #Test data in this case represent how much data is used to calculate the standard deviation of the error
    adj_close_optimization_new, adj_close_validation_new = split_train_test(adj_close_new, "column")

    adj_close_train_new = adj_close_optimization_new[:, 1+data_size:end]
    #standardize the data to be able to use the lasso function.
    adj_close_standard_new = standardize(adj_close_new[:, 1+data_size:end], adj_close_train_new)


    data_standard_new = adj_close_standard_new #data_standard_new = [adj_close_standard_new]

    train_standard_new = data_standard_new[:, 1:size(adj_close_train_new, 2)]
    test_standard_new = data_standard_new[:, size(adj_close_train_new, 2)+1:end]

    # do predictions for all and rescale them
    predictions_new = behavioural_prediction_new(data_standard_new, train_standard_new, test_standard_new, L, ahead_predictions, gamma)
    pred_rescaled_new = rescale_new(predictions_new, adj_close_train_new)

    # skip the missing entries because predictions has missing entries 
    clean_new = collect(skipmissing(pred_rescaled_new))
    clean_new = clean_new[ahead_predictions:ahead_predictions:end, :]

    adj_close_test_new = adj_close_validation_new[:, ahead_predictions:end]
    clean_new = clean_new[1:size(adj_close_test_new, 2), :]

    return adj_close_test_new, clean_new
end


function get_prediction_vs_truevalue_strategy(L, gamma, data_size, sample_frequency, ahead_predictions, all_data, decision_time)
    """This function takes in 7 parameters:
            1. all_data: downloaded stock data from yfinance
            2. L: Depth of the Hankel matrix
            3. gamma: regularization parameter
            4. data_size: deals with how much past data should be used
            5. Sampling_frequency: how often should the stock prices be sampled
            6. ahead_predictions: how far ahead into the future should we predict
            
    This function outputs the predictions with their corresponding real values, but also relaxes the assumption
        that decisions need to be taken after every sample time minutes"""
    #Extract the close prices and remove any corrupted extracted data
    adj_close_new = all_data[:, 6]'
    adj_close_new = adj_close_new[.~(isnan.(adj_close_new))]'

    optim_set, train_set = split_train_test(adj_close_new, "column")

    decision_price_extract = train_set[:, decision_time:sample_frequency:end]
    #Determine the best sampling period
    adj_close_new = adj_close_new[:, 1:sample_frequency:end]

    #The following lines extracts train and test data, standardize the data then finally 
    #extracts the train and test data based on standardized data.

    #Test data in this case represent how much data is used to calculate the standard deviation of the error
    adj_close_optimization_new, adj_close_validation_new = split_train_test(adj_close_new, "column")

    adj_close_train_new = adj_close_optimization_new[:, 1+data_size:end]
    #standardize the data to be able to use the lasso function.
    adj_close_standard_new = standardize(adj_close_new[:, 1+data_size:end], adj_close_train_new)


    data_standard_new = adj_close_standard_new #data_standard_new = [adj_close_standard_new]

    train_standard_new = data_standard_new[:, 1:size(adj_close_train_new, 2)]
    test_standard_new = data_standard_new[:, size(adj_close_train_new, 2)+1:end]

    # do predictions for all and rescale them
    predictions_new = behavioural_prediction_new(data_standard_new, train_standard_new, test_standard_new, L, ahead_predictions, gamma)
    pred_rescaled_new = rescale_new(predictions_new, adj_close_train_new)

    # skip the missing entries because predictions has missing entries 
    clean_new = collect(skipmissing(pred_rescaled_new))
    clean_new = clean_new[ahead_predictions:ahead_predictions:end, :]

    adj_close_test_new = decision_price_extract[:, ahead_predictions:end]
    clean_new = clean_new[1:size(adj_close_test_new, 2), :]

    return adj_close_test_new, clean_new
end