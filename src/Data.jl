"""This file is mainly for data manipulation functions"""
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
    # info = DataFrames.DataFrame(info) # Convert to julia DataFrame
    info = DataFrames.DataFrame([col => collect(info[col]) for col in info.pyo.columns])
    Pandas.display(info) # display
    all_data = info
    all_data # return data
end

#standardize a set of data according to mean and std dev of a set of training data
function standardize(data, train) 
    standardized = StatsBase.zscore(data,Statistics.mean(train), Statistics.std(train))
    standardized
end

# This function splits the data based on the user defined major. Either split by the rows
# or by columns. The first 2/3 of the data used for constructing the hankel matrix and the last
# 1/3 is used for calculating the relative errors then the standard deviation
function split_train_test(df, splitting_type::String)
    if (splitting_type == "row")
        train_data = df[1:floor(Int64,size(df,1)*3/4), :]
        test_data = df[floor(Int64,size(df,1)*3/4)+1:size(df,1),:]
    else
        train_data = df[:, 1:floor(Int64,size(df,2)*3/4)]
        test_data = df[:, floor(Int64,size(df,2)*3/4)+1:size(df,2)]
    end
    
    train_data, test_data
end


function normalize(data::Array)
    dt = fit(UnitRangeTransform, data)
    data_norm = StatsBase.transform(dt, data)
    data_norm
end




