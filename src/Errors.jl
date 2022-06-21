# used to calculte the mean squared errors of each algorithm
# used in plotting.jl

using Plots
using SciPy
using Distributions
using KernelDensity
using Flux

include("Behavioural.jl")

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
export rescale

function remove_first_i_vals(vector::Array, j::Int)
    some_vector = vec(vector)
    for i = 1:j
        deleteat!(some_vector, 1)
    end
    some_vector
end

function remove_last_i_vals(array::Array, j::Int)
    some_array = array[1:size(array,1)-j, :]
    some_array
end        

# Plots the mean squared error plot in specifie x values range with specified labels, and title

function plot_mse_vals(x_vals::UnitRange, mse_vals::Vector, data1label::String, title1::String, xlabel1::String, ylabel1::String) 
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

# Construct an error matrix from the predictions equal to the size of test data*num predictions ahead
function get_error_matrix(predictions::Any, test_data::Array, train_data::Array) 
    # remove all missing values and last value from the predictions
    if (size(predictions, 1) != size(test_data, 1))
        pred_clean = remove_last_i_vals(predictions, size(predictions, 2))
        pred_clean = pred_clean[size(train_data, 1)+1:size(pred_clean,1), :]
    else 
        pred_clean = predictions
    end

    perc_matrix = Array{Union{Float64, Missing}}(undef, size(test_data,1), size(predictions, 2))
    rel_matrix = Array{Union{Float64, Missing}}(undef, size(test_data,1), size(predictions, 2))
    abs_matrix = Array{Union{Float64, Missing}}(undef, size(test_data,1), size(predictions, 2))

    for i = 1:size(pred_clean, 1)
        for j = 1:size(pred_clean, 2)
            if (i+j-1 > size(test_data, 1)) 
                perc_matrix[i, j] = missing
                rel_matrix[i, j] = missing
                abs_matrix[i, j] = missing
            else 
                abs, rel, perc = errors(pred_clean[i, j], test_data[i+j-1, 1])
                perc_matrix[i, j] = perc
                rel_matrix[i,j] = rel
                abs_matrix[i,j] = abs
            end
        end
    end
    abs_matrix, rel_matrix, perc_matrix
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
function rescale(array::Array, train_data::Array) 
    empty_array = copy(array)
    for i=1:size(array, 2)
        for j=1:size(array, 1)
            empty_array[j, i] = (empty_array[j, i]*Statistics.std(train_data)) + Statistics.mean(train_data) #a add back mean and multiply by std dev
        end
    end
    empty_array
end

# fit data to a normal distribution as well as perform a kernel density estimation
function est_distribution(array::Array{Union{Float64, Missing}}, num_bins::Int) 
    tmp = collect(skipmissing(array)) 
    d = Distributions.fit(Normal, tmp) # estimate a normal distribution from errors

    lo, hi = Distributions.quantile.(d, [0.01, 0.99])  
    x = range(lo, hi; length = 100)
    pdf = Distributions.pdf.(d, x)

    kde = KernelDensity.kde(vec(tmp))  # perform kernel density estimation 
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


