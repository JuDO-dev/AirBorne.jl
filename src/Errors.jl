# used to calculte the mean squared errors of each algorithm
# used in plotting.jl

using Flux
using Plots

# export the functions that you want users to have access to when using your package

export remove_first_i_vals
export remove_last_i_vals
export plot_mse_vals
export calc_mse_naive
export calc_mse_sma

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

function calc_mse_naive(data1::Array, data2::Array, output::Array, size::Int)

    without_miss_vals = collect(skipmissing(data1))
    temp_vec = remove_first_i_vals(data2, size)
    append!(output, Flux.mse(without_miss_vals,temp_vec)) 

end

# Calculates the mean squared error values for the SMA slgorithm by preparing the set of values 

function calc_mse_sma(data1::Array, data2::Array, output::Array, size::Int) 
    without_miss_vals = remove_last_i_vals(collect(skipmissing(data1)), 1)
    temp_vec = remove_first_i_vals(data2, size)
    append!(output, Flux.mse(without_miss_vals,temp_vec))
end

