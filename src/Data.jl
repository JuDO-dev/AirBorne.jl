using DataFrames
using Statistics
using StatsBase
using StatsPlots
using LinearAlgebra
using TimeSeries


using Pkg
using PyCall
using Conda
using Pandas

# export the functions that you want users to have access to when using your package

export get_train_data
export get_test_data
export split_train_test
export get_data
export standardize
export form_matrix_of_data

numpy = pyimport("numpy")
pandas = pyimport("pandas")
yfinance = pyimport("yfinance")


# get_data is used to import live_data from yahoo finance of a selected stock tickr, in a specified range as well as, a specified interval

function get_data(tickr::String, start::String, finish::String, range::String, int::String)
    live_data = yfinance.download(tickr, start, finish, period = range, interval = int) #import data from any period desired
    info = Pandas.DataFrame(live_data) # Wrap in a pandas DataFrame
    info = Pandas.reset_index(info) # set the index 
    info = DataFrames.DataFrame(info) # Convert to julia DataFrame
    Pandas.display(info) # display
    all_data = info
    all_data # return data
end

#standardize a set of data according to mean and std dev of a set of training data
function standardize(data, train) 
    standardized = StatsBase.zscore(data,Statistics.mean(train), Statistics.std(train))
    standardized
end

function normalize(data)
    norm = data
    min = minimum(data)
    max = maximum(data)
    for i=1:size(data, 1)
        norm[i] = (data[i]-min)/(max-min)
    end
    norm
end



# get_train_data selects the first 2/3 of data from get_data
function split_train_test(df)
    train_data = df[1:floor(Int64,size(df,1)*2/3), :]
    test_data = df[floor(Int64,size(df,1)*2/3)+1:size(df,1),:]
    
    train_data, test_data
end

function form_matrix_of_data(adj_close::Array, volume::Array)
    empty_array = Array{Array}(undef, size(adj_close, 1), 1)
    for i = 1:size(adj_close, 1)
        empty_array[i] = [adj_close[i], volume[i]]
        # empty_array[i] = adjoint([adj_close[i], volume[i]])
    end
    empty_array
end


# get_test_data selects the last 1/3 of data from get_data


