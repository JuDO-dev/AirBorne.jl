"""This file contains functions that are related to the error analysis."""

using Plots
using SciPy
using Distributions
using KernelDensity
using Flux

include("Behavioural_AM.jl")

# export the functions that you want users to have access to when using your package

export remove_first_i_vals
export remove_last_i_vals
export plot_mse_vals
export calc_mse_naive
export calc_mse_sma
export get_error_vs_depth
export get_error_vs_gamma
export get_error_matrix
export estimate_errors
export errors
export rescale_new

function remove_first_i_vals(vector::Array, j::Int)
    """Removes first i elements from a vector and returns it"""
    some_vector = vec(vector)
    for i = 1:j
        deleteat!(some_vector, 1)
    end
    some_vector
end

function remove_last_i_vals(array::Array, j::Int)
    """Removes last i elements from a vector and returns it"""
    some_array = array[1:size(array,1)-j, :]
    some_array
end        

# Plots the mean squared error plot in specifie x values range with specified labels, and title

function plot_mse_vals(x_vals::UnitRange, mse_vals::Vector, data1label::String, title1::String, xlabel1::String, ylabel1::String) 
    """For plotting means squared errors"""
    Plots.plot(x_vals, mse_vals, label = data1label)
    Plots.display(Plots.plot!(title = title1, xlabel = xlabel1, ylabel = ylabel1))
end

# Calculates the mean squared error values for the naive algorithm by preparing the set of values

function calc_mse_naive(predictions::Array, true_data::Array, output::Array, delay::Int)
    without_miss_vals = collect(skipmissing(predictions))
    temp_vec = remove_first_i_vals(true_data, delay)
    append!(output, Flux.mse(without_miss_vals,temp_vec)) 
end

# Calculates the mean squared error values for the SMA slgorithm by preparing the set of values 

function calc_mse_sma_lin(predictions::Array, true_data::Array, output::Array, n::Int) 
    without_miss_vals = remove_last_i_vals(collect(skipmissing(predictions)), 1)
    temp_vec = remove_first_i_vals(true_data, n)
    append!(output, Flux.mse(without_miss_vals,temp_vec))
end

#calculate variety of errors absolute, relative, percentage
function errors(pred::Float64, true_value::Float64)
    abs_error = true_value - pred
    rel_error = 1-(pred/true_value)
    perc = abs_error/true_value*100
    abs_error, rel_error, perc
end

# calculate variety of errors mean squared, mean absolute, estimation
function estimate_errors(predictions::Array, true_values::Array) 
    pred_clean = collect(skipmissing(predictions))
    num_preds = size(pred_clean, 1) - size(true_values, 1)
    pred_clean = remove_last_i_vals(pred_clean, num_preds)

    mean_squared = Flux.mse(pred_clean, true_values) 
    mean_absolute = Flux.mae(pred_clean, true_values)
    estimation_error = 0 

    for i=1:size(pred_clean, 1)                                     #need to check if this is correct for estimation error
        val = abs(true_values[i] - pred_clean[i])/true_values[i]
        estimation_error = val + estimation_error
    end 

    mean_squared, mean_absolute, estimation_error
end

# obtain errors for a fixed depth and a range of gamma values
function get_error_vs_gamma(all_data::Array, train_data::Array, rescaled_train_data::Array, test_data::Array, depth::Int, num_preds::Int)
    n = 10
    γM = range(0; stop = 1.0, length = n)
    ms_vals = zeros(0)
    ma_vals = zeros(0)
    est_vals = zeros(0)
    test_rescaled = rescale(test_data[:, 1], rescaled_train_data)

    for i=1:n
        predictions = behavioural_prediction(all_data, train_data, test_data, depth, num_preds, γM[i])
        pred_rescaled = rescale(predictions, rescaled_train_data)

        ms, ma, est = estimate_errors(pred_rescaled, test_rescaled)
        append!(ms_vals, ms)
        append!(ma_vals, ma)
        append!(est_vals, est)
    end 

    return ms_vals, ma_vals, est_vals, γM

end      

# obtain errors for fixed gamma for a range of depth from specified start to specified max depth NOTE MATRIX MUST HAVE MORE COLS THAN ROWS or will get error
function get_error_vs_depth(all_data::Array, train_data::Array, rescaled_train_data::Array, test_data::Array, num_preds::Int, start::Int, max_depth::Int, gamma::Float64)
    ms_vals = zeros(0)
    ma_vals = zeros(0)
    est_vals = zeros(0)
    test_rescaled = rescale(test_data[:, 1], rescaled_train_data)

    for i=start:max_depth
        predictions = behavioural_prediction(all_data, train_data, test_data, i, num_preds, gamma)
        pred_rescaled = rescale(predictions, rescaled_train_data)

        ms, ma, est = estimate_errors(pred_rescaled, test_rescaled)
        append!(ms_vals, ms)
        append!(ma_vals, ma)
        append!(est_vals, est)
    end 

    return ms_vals, ma_vals, est_vals
end


function get_error_matrix(predictions::Any, test_data) 
    """Construct an error matrix from the predictions equal to the size of test data*num predictions ahead"""
    rel_errors = abs.(test_data-predictions)./test_data
    return rel_errors
end

function get_nonabs_error_matrix(predictions::Any, test_data) 
    """Removes the absolute value for error plots"""
    rel_errors = (test_data-predictions)./predictions
    return rel_errors
end

function get_error_change_rate(predictions::Any, test_data, steps_ahead)
    """A different objective function, where the relative error change was considered"""
   error_change = abs.(test_data[steps_ahead:end]-predictions[steps_ahead:end])./((abs.(test_data[steps_ahead:end]-test_data[1:end-steps_ahead+1])).+1)
   return error_change
end


# retrieve the avg error form error matrix
function get_avg_error(error_matrix::Matrix) 
    matrix = Array{Float64}(undef, size(error,1), 1)
    for i=1:size(error_matrix, 1)
        total = sum(error_matrix[i, :])
        avg = total/size(error_matrix, 2)
        matrix[i, 1] = avg
    end
    matrix
end

# in order to calculate errors better, need to rescale data
function rescale_new(array::Array, train_data) 
    empty_array = copy(array)
    empty_array = (empty_array.*Statistics.std(train_data)) .+ Statistics.mean(train_data) #a add back mean and multiply by std dev
    empty_array
end

# fit data to a normal distribution as well as perform a kernel density estimation
function est_distribution(rel_error_matrix)  
    d = Distributions.fit(Normal, rel_error_matrix) # estimate a normal distribution from errors

    lo, hi = Distributions.quantile.(d, [0.01, 0.99])  
    x = range(lo, hi; length = 100)
    pdf = Distributions.pdf.(d, x)

    kde = KernelDensity.kde(vec(rel_error_matrix))  # perform kernel density estimation 
    return d, x, pdf, kde
end

# user specified confidence interval. 
# returns lower and upper bound.
# function has this confidence between these two values.
# i.e the algorithm is this 'confident' the prediction will be between these two values
function get_confidence_int(distribution, confidence::Float64)
    val = 1.0 - confidence
    bounds = Distributions.quantile.(distribution, [val, 1.0-val])
    lower = bounds[1]
    upper = bounds[2]
    return lower, upper  
end

function get_probability(distribution, confidence)
    return cdf(distribution, confidence)
end

#Function is called to look at some values that analyze the errors obtained.
function confidence_interval_analysis(pred_timing::Int, rel_err_matrix)
    
    negative_errors_index = findall(<=(0), rel_err_matrix)
    negative_rel_errors = rel_matx[negative_errors_index]
    prediction_higher_percent = size(negative_rel_errors, 1)/size(rel_matx, 1) * 100 #This variable has the percentage of how many times the prediction is higher than the actual
    println("\n")
    println("Considering $pred_timing day ahead predictions, the predictor predicts higher price than the actual price $prediction_higher_percent% of the times\n")

    abs_avg_error_high_pred = abs(mean(rel_err_matrix))
    println("With an average of $abs_avg_error_high_pred% higher")
    percent90_confidence_index = findall(>=(-0.01), negative_rel_errors) #This variable gets the indices for which the values are within 10% of the actual value
    percent90_confidence = negative_rel_errors[percent90_confidence_index]

    println("Within 10% (confidence interval of 90%): ")
    println(size(percent90_confidence,1)/size(negative_rel_errors,1)*100)

    percent70_confidence_index = findall(>=(-0.03), negative_rel_errors)
    percent70_confidence = negative_rel_errors[percent70_confidence_index]

    println("Within 30% (confidence interval of 70%): ")
    println(size(percent70_confidence,1)/size(negative_rel_errors,1)*100)

    percent50_confidence_index = findall(>=(-0.05), negative_rel_errors)
    percent50_confidence = negative_rel_errors[percent50_confidence_index]

    println("Within 50% (confidence interval of 50%): ")
    println(size(percent50_confidence,1)/size(negative_rel_errors,1)*100)
end



