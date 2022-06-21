# Naive Predicition , Moving Average , Linear prediction 
using Statistics, StatsPlots
using StatsBase
using ShiftedArrays
using Flux
using GLM
using MLBase
using DataFrames

export naive
export sma
export linear_prediction
export linear_predict
export plot_mse_vals

# delays the specified array by a select amount of "delay"

function naive(data::Array, delay::Int)
    predictions = copy(GLM.lag(data, delay))
    predictions
end

# calculates the simple moving average of the specified array using an "n" number of points

function sma(a::Array, n::Int)
    vals = zeros(size(a,1)+1, size(a,2))

    for i in 1:size(a,1) - (n-1)
        for j in 1:size(a,2)
            vals[i,j] = mean(a[i:i+(n-1),j])
        end
    end
    predictions = copy(GLM.lag(vals,n))
    predictions
end

# calculates the moving linear prediction of the specified array using an "n" number of points
# works similar to the simple moving average
# makes use of the linear_predict function

function linear_prediction(data::Array, n::Int, ahead::Int)
    vals = zeros(size(data,1)+1)

    for i in 1:size(data,1) - (n-1)
        vals[i] = linear_predict(data[i:i+(n-1)], ahead)
    end
    predictions = copy(GLM.lag(vals,n))
    predictions
end

# calculates the linear fit of the specified array and predicts the next point "prediction" using the line calculated

function linear_predict(data::Array, ahead::Int)
    vector_data = vec(data)
    df = DataFrames.DataFrame(y = vector_data, x = 1:size(data,1))
    fm = @formula(y ~ x)
    model = lm(fm, df)
    slope = GLM.coef(model)[2]
    y_int = GLM.coef(model)[1]
    y = slope*(size(vector_data,1)+ahead) + y_int
    y
end

