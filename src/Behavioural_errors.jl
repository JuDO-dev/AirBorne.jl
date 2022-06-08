# will estimate error between the prediction trajectory
# and the true values of the signal (test_data)
include("Behavioural.jl")

export plot_error_vs_depth
export plot_error_vs_gamma
export get_error_matrix

function errors(pred, true_value)
    abs_error = true_value - pred
    rel_error = abs(1-(pred/true_value))
    perc = abs(abs_error/true_value)*100
    abs_error, rel_error, perc
end


function estimate_errors(predictions, true_values) 

    mean_squared = Flux.mse(pred_clean, true_values) 
    mean_absolute = Flux.mae(pred_clean, true_values)
    estimation_error = 0 

    for i=1:size(pred_clean, 1)                                     #need to check if this is correct for estimation error
        val = (true_values[i] - pred_clean[i])/true_values[i]
        estimation_error = val + estimation_error
    end 

    mean_squared, mean_absolute, estimation_error
end

function plot_error_vs_gamma(all_data, train_data, test_data, depth, num_preds)
    n = 10
    γM = range(0; stop = 1.5, length = n)
    ms_vals = zeros(0)
    ma_vals = zeros(0)
    est_vals = zeros(0)

    for i=1:n
        predictions = behavioural_prediction(all_data, train_data, test_data, depth, num_preds, γM[i])
        ms, ma, est = estimate_errors(predictions, test_data)
        append!(ms_vals, ms)
        append!(ma_vals, ma)
        append!(est_vals, est)
    end 

    Plots.plot(γM, ms_vals, seriestype = :scatter)
    Plots.display(Plots.plot!(title = "Mean Squared Error vs Gamma for Depth = $depth", xlabel = "Gamma", ylabel = "MS Error"))
    savefig("C:\\Users\\Alexander scos\\Documents\\FYP\\MS_Error_vs_Gamma_vol")

    Plots.plot(γM, ma_vals, seriestype = :scatter)
    Plots.display(Plots.plot!(title = "Mean Absolute Error vs Gamma for Depth = $depth", xlabel = "Gamma", ylabel = "MA Error"))
    savefig("C:\\Users\\Alexander scos\\Documents\\FYP\\MA_Error_vs_Gamma_vol")

end      

function plot_error_vs_depth(all_data, train_data, test_data, num_preds, start, max_depth)
    gamma = 1.0
    ms_vals = zeros(0)
    ma_vals = zeros(0)
    est_vals = zeros(0)

    for i=start:max_depth
        predictions = behavioural_prediction(all_data, train_data, test_data, i, num_preds, gamma)
        ms, ma, est = estimate_errors(predictions, test_data)
        append!(ms_vals, ms)
        append!(ma_vals, ma)
        append!(est_vals, est)
    end 

    Plots.plot(start:max_depth, ms_vals, seriestype = :scatter)
    Plots.display(Plots.plot!(title = "Mean Squared Error vs Depth for gamma = $gamma", xlabel = "Depth, L", ylabel = "MS Error"))
    savefig("C:\\Users\\Alexander scos\\Documents\\FYP\\MS_Error_vs_Depth_vol")

    Plots.plot(start:max_depth, ma_vals, seriestype = :scatter)
    Plots.display(Plots.plot!(title = "Mean Absolute Error vs Depth for gamma = $gamma", xlabel = "Depth, L", ylabel = "MA Error"))
    savefig("C:\\Users\\Alexander scos\\Documents\\FYP\\MA_Error_vs_Depth_vol")
    
    # Plots.plot(start:max_depth, est_vals, seriestype = :scatter)

end

function get_error_matrix(predictions, test_data, train_data)
    # remove all missing values and last value from the predictions
    pred_clean = remove_last_i_vals(predictions, 1)
    pred_clean = pred_clean[size(train_data, 1)+1:size(pred_clean,1), :]

    perc_matrix = Array{Float64}(undef, size(test_data,1), num_preds)
    rel_matrix = Array{Float64}(undef, size(test_data,1), num_preds)
    abs_matrix = Array{Float64}(undef, size(test_data,1), num_preds)

    for i = 1:size(pred_clean, 1)
        for j = 1:size(pred_clean, 2)
            if (i+j-1 > size(test_data, 1)) 
                perc_matrix[i, j] = 0.0
                rel_matrix[i, j] = 0.0
                abs_matrix[i, j] = 0.0
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

function get_avg_error(error_matrix::Matrix)
    matrix = Array{Float64}(undef, size(error,1), 1)
    for i=1:size(error_matrix, 1)
        total = sum(error_matrix[i, :])
        avg = total/size(error_matrix, 2)
        matrix[i, 1] = avg
    end
    matrix
end

function rescale(array::Array, train_data::Array) # in order to calculate errors better, need to rescale data
    empty_array = copy(array)
    for i=1:size(array, 2)
        for j=1:size(array, 1)
            empty_array[j, i] = (empty_array[j, i]*Statistics.std(train_data)) + Statistics.mean(train_data)
        end
    end
    empty_array
end


